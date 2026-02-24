# Supabase Auth Integration Patterns

Comprehensive auth integration patterns for Supabase across all major frameworks. Covers client-side and server-side auth, middleware, token handling, custom claims, and profile linking.

---

## Table of Contents

1. [Client-Side Auth Flows](#client-side-auth-flows)
2. [Next.js App Router (Server Components + SSR)](#nextjs-app-router)
3. [Next.js Pages Router](#nextjs-pages-router)
4. [React SPA](#react-spa)
5. [SvelteKit](#sveltekit)
6. [Server-Side Auth (SSR with Cookies)](#server-side-auth-ssr)
7. [Middleware for Protected Routes](#middleware-for-protected-routes)
8. [Auth Helpers Packages](#auth-helpers-packages)
9. [Token Refresh Handling](#token-refresh-handling)
10. [Custom Claims via raw_app_meta_data](#custom-claims)
11. [Linking auth.users to Public Profiles](#linking-auth-users-to-profiles)

---

## Client-Side Auth Flows

These patterns work across all frameworks. The Supabase client handles token storage, refresh, and session persistence automatically when configured with the default cookie/localStorage storage.

### Email/Password Registration

```typescript
import { supabase } from '@/lib/supabase'

async function signUp(email: string, password: string, metadata?: Record<string, unknown>) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: metadata, // Stored in raw_user_meta_data
      emailRedirectTo: `${window.location.origin}/auth/callback`,
    },
  })

  if (error) {
    if (error.message.includes('already registered')) {
      throw new Error('An account with this email already exists.')
    }
    throw error
  }

  // data.user exists but data.session may be null if email confirmation is required
  return data
}
```

### Email/Password Sign In

```typescript
async function signIn(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  })

  if (error) {
    if (error.message.includes('Invalid login credentials')) {
      throw new Error('Incorrect email or password.')
    }
    throw error
  }

  return data // { user, session }
}
```

### Magic Link (Passwordless Email)

```typescript
async function signInWithMagicLink(email: string) {
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: `${window.location.origin}/auth/callback`,
      // Set to true to create new users automatically
      shouldCreateUser: true,
    },
  })

  if (error) throw error
  // User receives an email with a login link
}
```

### Phone OTP

```typescript
// Step 1: Send OTP
async function sendPhoneOtp(phone: string) {
  const { error } = await supabase.auth.signInWithOtp({
    phone,
  })
  if (error) throw error
}

// Step 2: Verify OTP
async function verifyPhoneOtp(phone: string, token: string) {
  const { data, error } = await supabase.auth.verifyOtp({
    phone,
    token,
    type: 'sms',
  })
  if (error) throw error
  return data
}
```

### OAuth (Google, GitHub, Apple, etc.)

```typescript
async function signInWithOAuth(provider: 'google' | 'github' | 'apple' | 'azure' | 'discord') {
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider,
    options: {
      redirectTo: `${window.location.origin}/auth/callback`,
      queryParams: {
        // Provider-specific params
        access_type: 'offline', // Google: get refresh token
        prompt: 'consent',      // Google: always show consent screen
      },
      scopes: 'email profile', // Request specific scopes
    },
  })

  if (error) throw error
  // User is redirected to the provider's login page
  // data.url contains the redirect URL if you want to handle it manually
}
```

### Sign Out

```typescript
async function signOut() {
  const { error } = await supabase.auth.signOut()
  if (error) throw error
  // Session is cleared, user is signed out
}

// Sign out from all devices
async function signOutEverywhere() {
  const { error } = await supabase.auth.signOut({ scope: 'global' })
  if (error) throw error
}
```

### Password Reset

```typescript
// Step 1: Send reset email
async function resetPassword(email: string) {
  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${window.location.origin}/auth/reset-password`,
  })
  if (error) throw error
}

// Step 2: Update password (on the reset-password page, after user clicks email link)
async function updatePassword(newPassword: string) {
  const { error } = await supabase.auth.updateUser({
    password: newPassword,
  })
  if (error) throw error
}
```

### Auth Callback Handler

The callback page handles the redirect from email links (magic link, email confirmation, password reset) and OAuth providers.

```typescript
// app/auth/callback/route.ts (Next.js App Router)
import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const requestUrl = new URL(request.url)
  const code = requestUrl.searchParams.get('code')

  if (code) {
    const supabase = createRouteHandlerClient({ cookies })
    await supabase.auth.exchangeCodeForSession(code)
  }

  // Redirect to the app after auth
  return NextResponse.redirect(new URL('/dashboard', request.url))
}
```

---

## Next.js App Router

The App Router uses React Server Components by default. Supabase auth in this context requires careful handling of cookies for server-side session management.

### Package Setup

```bash
npm install @supabase/supabase-js @supabase/auth-helpers-nextjs @supabase/ssr
```

### Environment Variables

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
```

### Client Types

The App Router requires different Supabase client types depending on the context:

```typescript
// lib/supabase/client.ts — Client Components (browser)
'use client'
import { createBrowserClient } from '@supabase/ssr'
import type { Database } from '@/types/supabase'

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

```typescript
// lib/supabase/server.ts — Server Components, Server Actions, Route Handlers
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import type { Database } from '@/types/supabase'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // The `setAll` method is called from a Server Component.
            // This can be ignored if you have middleware refreshing sessions.
          }
        },
      },
    }
  )
}
```

```typescript
// lib/supabase/middleware.ts — Middleware client
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) =>
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // Refresh the session — this is critical
  const { data: { user } } = await supabase.auth.getUser()

  return supabaseResponse
}
```

### Server Component Usage

```typescript
// app/dashboard/page.tsx
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function DashboardPage() {
  const supabase = await createClient()

  const { data: { user }, error } = await supabase.auth.getUser()
  if (!user) {
    redirect('/login')
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single()

  return (
    <div>
      <h1>Welcome, {profile?.full_name}</h1>
      {/* Dashboard content */}
    </div>
  )
}
```

### Server Action Usage

```typescript
// app/actions/profile.ts
'use server'
import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export async function updateProfile(formData: FormData) {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Not authenticated')

  const { error } = await supabase
    .from('profiles')
    .update({
      full_name: formData.get('full_name') as string,
      bio: formData.get('bio') as string,
    })
    .eq('id', user.id)

  if (error) throw error
  revalidatePath('/profile')
}
```

### Client Component Auth Form

```typescript
// components/LoginForm.tsx
'use client'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import { useState } from 'react'

export function LoginForm() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const router = useRouter()
  const supabase = createClient()

  async function handleSignIn(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError(null)

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      setError(error.message)
      setLoading(false)
      return
    }

    router.push('/dashboard')
    router.refresh()
  }

  return (
    <form onSubmit={handleSignIn}>
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="Email"
        required
      />
      <input
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        placeholder="Password"
        required
      />
      {error && <p className="error">{error}</p>}
      <button type="submit" disabled={loading}>
        {loading ? 'Signing in...' : 'Sign In'}
      </button>
    </form>
  )
}
```

### Route Handler (API Route)

```typescript
// app/auth/callback/route.ts
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')
  const next = searchParams.get('next') ?? '/dashboard'

  if (code) {
    const supabase = await createClient()
    const { error } = await supabase.auth.exchangeCodeForSession(code)
    if (!error) {
      return NextResponse.redirect(`${origin}${next}`)
    }
  }

  // Return the user to an error page with instructions
  return NextResponse.redirect(`${origin}/auth/auth-code-error`)
}
```

### Middleware (Protect Routes)

```typescript
// middleware.ts
import { updateSession } from '@/lib/supabase/middleware'
import { type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  return await updateSession(request)
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

### Advanced Middleware with Route Protection

```typescript
// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

const publicRoutes = ['/', '/login', '/signup', '/auth/callback', '/auth/reset-password']
const adminRoutes = ['/admin']

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) =>
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  const { data: { user } } = await supabase.auth.getUser()

  const pathname = request.nextUrl.pathname
  const isPublicRoute = publicRoutes.some(route => pathname === route || pathname.startsWith(route + '/'))

  // Redirect unauthenticated users to login
  if (!user && !isPublicRoute) {
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    url.searchParams.set('redirectTo', pathname)
    return NextResponse.redirect(url)
  }

  // Redirect authenticated users away from auth pages
  if (user && (pathname === '/login' || pathname === '/signup')) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  // Check admin routes
  if (user && adminRoutes.some(route => pathname.startsWith(route))) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    if (profile?.role !== 'admin') {
      return NextResponse.redirect(new URL('/dashboard', request.url))
    }
  }

  return supabaseResponse
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
}
```

---

## Next.js Pages Router

The Pages Router uses `getServerSideProps` for server-side auth and client-side hooks for state management.

### Package Setup

```bash
npm install @supabase/supabase-js @supabase/auth-helpers-nextjs
```

### Client Setup

```typescript
// lib/supabase.ts
import { createPagesBrowserClient } from '@supabase/auth-helpers-nextjs'
import type { Database } from '@/types/supabase'

export const supabase = createPagesBrowserClient<Database>()
```

### Session Provider (_app.tsx)

```typescript
// pages/_app.tsx
import { createPagesBrowserClient } from '@supabase/auth-helpers-nextjs'
import { SessionContextProvider } from '@supabase/auth-helpers-react'
import { useState } from 'react'
import type { AppProps } from 'next/app'

export default function App({ Component, pageProps }: AppProps) {
  const [supabaseClient] = useState(() => createPagesBrowserClient())

  return (
    <SessionContextProvider
      supabaseClient={supabaseClient}
      initialSession={pageProps.initialSession}
    >
      <Component {...pageProps} />
    </SessionContextProvider>
  )
}
```

### Using Auth Hooks in Pages

```typescript
// pages/dashboard.tsx
import { useUser, useSupabaseClient, useSession } from '@supabase/auth-helpers-react'
import { createPagesServerClient } from '@supabase/auth-helpers-nextjs'
import type { GetServerSidePropsContext } from 'next'

export default function Dashboard({ profile }: { profile: any }) {
  const user = useUser()
  const session = useSession()
  const supabase = useSupabaseClient()

  if (!user) return <div>Loading...</div>

  return (
    <div>
      <h1>Welcome, {profile.full_name}</h1>
      <button onClick={() => supabase.auth.signOut()}>Sign Out</button>
    </div>
  )
}

export const getServerSideProps = async (ctx: GetServerSidePropsContext) => {
  const supabase = createPagesServerClient(ctx)

  const { data: { session } } = await supabase.auth.getSession()

  if (!session) {
    return {
      redirect: {
        destination: '/login',
        permanent: false,
      },
    }
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', session.user.id)
    .single()

  return {
    props: {
      initialSession: session,
      profile,
    },
  }
}
```

### API Route with Auth

```typescript
// pages/api/profile.ts
import { createPagesServerClient } from '@supabase/auth-helpers-nextjs'
import type { NextApiRequest, NextApiResponse } from 'next'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const supabase = createPagesServerClient({ req, res })

  const { data: { session } } = await supabase.auth.getSession()

  if (!session) {
    return res.status(401).json({ error: 'Not authenticated' })
  }

  if (req.method === 'GET') {
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', session.user.id)
      .single()

    if (error) return res.status(500).json({ error: error.message })
    return res.status(200).json(profile)
  }

  if (req.method === 'PATCH') {
    const { full_name, bio } = req.body

    const { data: profile, error } = await supabase
      .from('profiles')
      .update({ full_name, bio })
      .eq('id', session.user.id)
      .select()
      .single()

    if (error) return res.status(500).json({ error: error.message })
    return res.status(200).json(profile)
  }

  res.setHeader('Allow', ['GET', 'PATCH'])
  res.status(405).end(`Method ${req.method} Not Allowed`)
}
```

### Auth Callback (Pages Router)

```typescript
// pages/auth/callback.tsx
import { useEffect } from 'react'
import { useRouter } from 'next/router'
import { useSupabaseClient } from '@supabase/auth-helpers-react'

export default function AuthCallback() {
  const router = useRouter()
  const supabase = useSupabaseClient()

  useEffect(() => {
    const handleCallback = async () => {
      const { error } = await supabase.auth.exchangeCodeForSession(
        router.query.code as string
      )
      if (error) {
        router.push('/login?error=auth')
      } else {
        router.push('/dashboard')
      }
    }

    if (router.query.code) {
      handleCallback()
    }
  }, [router.query.code, supabase, router])

  return <div>Completing sign in...</div>
}
```

---

## React SPA

For standalone React applications (Vite, Create React App) without server-side rendering.

### Client Setup

```typescript
// lib/supabase.ts
import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/supabase'

export const supabase = createClient<Database>(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
)
```

### Auth Provider

```typescript
// contexts/AuthProvider.tsx
import {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
  type ReactNode,
} from 'react'
import type { User, Session, AuthError } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'

interface AuthContextType {
  user: User | null
  session: Session | null
  loading: boolean
  signInWithPassword: (email: string, password: string) => Promise<void>
  signInWithOAuth: (provider: 'google' | 'github') => Promise<void>
  signInWithMagicLink: (email: string) => Promise<void>
  signUp: (email: string, password: string, metadata?: Record<string, unknown>) => Promise<void>
  signOut: () => Promise<void>
  resetPassword: (email: string) => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Get the initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setUser(session?.user ?? null)
      setLoading(false)
    })

    // Subscribe to auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        setSession(session)
        setUser(session?.user ?? null)
        setLoading(false)

        // Handle specific events
        if (event === 'SIGNED_IN') {
          // User signed in
        } else if (event === 'SIGNED_OUT') {
          // User signed out — clear app state
        } else if (event === 'TOKEN_REFRESHED') {
          // Token was refreshed
        } else if (event === 'USER_UPDATED') {
          // User profile updated
        } else if (event === 'PASSWORD_RECOVERY') {
          // User clicked password reset link
        }
      }
    )

    return () => subscription.unsubscribe()
  }, [])

  const signInWithPassword = useCallback(async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
  }, [])

  const signInWithOAuth = useCallback(async (provider: 'google' | 'github') => {
    const { error } = await supabase.auth.signInWithOAuth({
      provider,
      options: { redirectTo: `${window.location.origin}/auth/callback` },
    })
    if (error) throw error
  }, [])

  const signInWithMagicLink = useCallback(async (email: string) => {
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: `${window.location.origin}/auth/callback` },
    })
    if (error) throw error
  }, [])

  const signUp = useCallback(async (
    email: string,
    password: string,
    metadata?: Record<string, unknown>
  ) => {
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: metadata },
    })
    if (error) throw error
  }, [])

  const signOut = useCallback(async () => {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
  }, [])

  const resetPassword = useCallback(async (email: string) => {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`,
    })
    if (error) throw error
  }, [])

  return (
    <AuthContext.Provider
      value={{
        user,
        session,
        loading,
        signInWithPassword,
        signInWithOAuth,
        signInWithMagicLink,
        signUp,
        signOut,
        resetPassword,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
```

### Protected Route Component (React Router)

```typescript
// components/ProtectedRoute.tsx
import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from '@/contexts/AuthProvider'

interface ProtectedRouteProps {
  children: React.ReactNode
  requiredRole?: string
}

export function ProtectedRoute({ children, requiredRole }: ProtectedRouteProps) {
  const { user, loading } = useAuth()
  const location = useLocation()

  if (loading) {
    return <div>Loading...</div>
  }

  if (!user) {
    return <Navigate to="/login" state={{ from: location }} replace />
  }

  // Optional: check role from user metadata or profile
  if (requiredRole && user.user_metadata?.role !== requiredRole) {
    return <Navigate to="/unauthorized" replace />
  }

  return <>{children}</>
}

// Usage in router:
// <Route path="/dashboard" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
// <Route path="/admin" element={<ProtectedRoute requiredRole="admin"><Admin /></ProtectedRoute>} />
```

### Auth Callback Component (React Router)

```typescript
// pages/AuthCallback.tsx
import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'

export function AuthCallback() {
  const navigate = useNavigate()

  useEffect(() => {
    // The Supabase client automatically handles the hash fragment
    // from OAuth and magic link redirects.
    // We just need to wait for the auth state to update.
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'SIGNED_IN') {
        navigate('/dashboard', { replace: true })
      }
    })

    return () => subscription.unsubscribe()
  }, [navigate])

  return <div>Completing sign in...</div>
}
```

---

## SvelteKit

SvelteKit uses hooks and load functions for server-side auth, and stores for client-side state.

### Package Setup

```bash
npm install @supabase/supabase-js @supabase/ssr
```

### Environment Variables

```env
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=eyJ...
```

### Hooks (Server-Side Session Management)

```typescript
// src/hooks.server.ts
import { createServerClient } from '@supabase/ssr'
import { type Handle, redirect } from '@sveltejs/kit'
import { sequence } from '@sveltejs/kit/hooks'
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public'

const supabase: Handle = async ({ event, resolve }) => {
  event.locals.supabase = createServerClient(
    PUBLIC_SUPABASE_URL,
    PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        getAll: () => event.cookies.getAll(),
        setAll: (cookiesToSet) => {
          cookiesToSet.forEach(({ name, value, options }) => {
            event.cookies.set(name, value, { ...options, path: '/' })
          })
        },
      },
    }
  )

  event.locals.safeGetSession = async () => {
    const { data: { session } } = await event.locals.supabase.auth.getSession()
    if (!session) return { session: null, user: null }

    const { data: { user }, error } = await event.locals.supabase.auth.getUser()
    if (error) return { session: null, user: null }

    return { session, user }
  }

  return resolve(event, {
    filterSerializedResponseHeaders(name) {
      return name === 'content-range' || name === 'x-supabase-api-version'
    },
  })
}

const authGuard: Handle = async ({ event, resolve }) => {
  const { session, user } = await event.locals.safeGetSession()
  event.locals.session = session
  event.locals.user = user

  // Protect routes
  if (!session && event.url.pathname.startsWith('/dashboard')) {
    redirect(303, '/login')
  }

  // Redirect logged-in users away from auth pages
  if (session && (event.url.pathname === '/login' || event.url.pathname === '/signup')) {
    redirect(303, '/dashboard')
  }

  return resolve(event)
}

export const handle: Handle = sequence(supabase, authGuard)
```

### App.d.ts Types

```typescript
// src/app.d.ts
import type { SupabaseClient, Session, User } from '@supabase/supabase-js'
import type { Database } from '$lib/types/supabase'

declare global {
  namespace App {
    interface Locals {
      supabase: SupabaseClient<Database>
      safeGetSession: () => Promise<{ session: Session | null; user: User | null }>
      session: Session | null
      user: User | null
    }
    interface PageData {
      session: Session | null
      user: User | null
    }
  }
}

export {}
```

### Root Layout (Pass Session to Client)

```typescript
// src/routes/+layout.server.ts
import type { LayoutServerLoad } from './$types'

export const load: LayoutServerLoad = async ({ locals }) => {
  const { session, user } = await locals.safeGetSession()
  return { session, user }
}
```

```svelte
<!-- src/routes/+layout.svelte -->
<script lang="ts">
  import { onMount } from 'svelte'
  import { invalidate } from '$app/navigation'
  import { createBrowserClient, isBrowser, parse } from '@supabase/ssr'
  import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public'
  import type { LayoutData } from './$types'

  export let data: LayoutData

  let supabase = createBrowserClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
    global: {
      fetch,
    },
    cookies: {
      get(key) {
        if (!isBrowser()) return JSON.stringify(data.session)
        const cookie = parse(document.cookie)
        return cookie[key]
      },
    },
  })

  onMount(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_, newSession) => {
      if (newSession?.expires_at !== data.session?.expires_at) {
        invalidate('supabase:auth')
      }
    })

    return () => subscription.unsubscribe()
  })
</script>

<slot />
```

### Protected Page Load

```typescript
// src/routes/dashboard/+page.server.ts
import { redirect } from '@sveltejs/kit'
import type { PageServerLoad } from './$types'

export const load: PageServerLoad = async ({ locals }) => {
  if (!locals.session) {
    redirect(303, '/login')
  }

  const { data: profile } = await locals.supabase
    .from('profiles')
    .select('*')
    .eq('id', locals.user!.id)
    .single()

  return { profile }
}
```

### Login Page

```svelte
<!-- src/routes/login/+page.svelte -->
<script lang="ts">
  import { createBrowserClient } from '@supabase/ssr'
  import { goto } from '$app/navigation'
  import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public'

  const supabase = createBrowserClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY)

  let email = ''
  let password = ''
  let error = ''
  let loading = false

  async function handleSignIn() {
    loading = true
    error = ''

    const { error: authError } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (authError) {
      error = authError.message
      loading = false
      return
    }

    goto('/dashboard')
  }

  async function handleOAuth(provider: 'google' | 'github') {
    await supabase.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
      },
    })
  }
</script>

<form on:submit|preventDefault={handleSignIn}>
  <input type="email" bind:value={email} placeholder="Email" required />
  <input type="password" bind:value={password} placeholder="Password" required />
  {#if error}
    <p class="error">{error}</p>
  {/if}
  <button type="submit" disabled={loading}>
    {loading ? 'Signing in...' : 'Sign In'}
  </button>
</form>

<button on:click={() => handleOAuth('google')}>Sign in with Google</button>
<button on:click={() => handleOAuth('github')}>Sign in with GitHub</button>
```

### Auth Callback Route

```typescript
// src/routes/auth/callback/+server.ts
import { redirect } from '@sveltejs/kit'
import type { RequestHandler } from './$types'

export const GET: RequestHandler = async ({ url, locals }) => {
  const code = url.searchParams.get('code')
  const next = url.searchParams.get('next') ?? '/dashboard'

  if (code) {
    const { error } = await locals.supabase.auth.exchangeCodeForSession(code)
    if (!error) {
      redirect(303, next)
    }
  }

  redirect(303, '/auth/auth-code-error')
}
```

---

## Server-Side Auth (SSR)

### Why Server-Side Auth?

Client-side auth (`getSession()`) reads the JWT from cookies or localStorage but does not validate it against Supabase servers. For security-critical operations (especially in server-rendered pages), always use `getUser()` which makes a round-trip to Supabase to verify the JWT.

```typescript
// INSECURE for server-side decisions:
const { data: { session } } = await supabase.auth.getSession()
// The JWT could be tampered with or expired

// SECURE for server-side decisions:
const { data: { user }, error } = await supabase.auth.getUser()
// This validates the JWT against Supabase auth servers
```

### Cookie-Based Session Management

All `@supabase/ssr` client creators automatically handle cookies. The key patterns:

1. **Middleware/hooks refresh the session** on every request to prevent stale tokens.
2. **Server components use `getUser()`** for trusted auth checks.
3. **Client components use `onAuthStateChange`** for reactive UI updates.

### Secure Server-Side Data Fetching

```typescript
// In any server context (Server Component, API Route, getServerSideProps)
async function getSecureData(supabase: SupabaseClient) {
  // Step 1: Verify the user (round-trip to Supabase)
  const { data: { user }, error: authError } = await supabase.auth.getUser()

  if (authError || !user) {
    throw new Error('Unauthorized')
  }

  // Step 2: Fetch data (RLS will use the user's JWT automatically)
  const { data, error } = await supabase
    .from('sensitive_data')
    .select('*')
    .eq('user_id', user.id)

  if (error) throw error
  return data
}
```

---

## Middleware for Protected Routes

### Pattern: Centralized Route Protection

Define route groups and check auth in middleware rather than in each page.

```typescript
// Route configuration
const routeConfig = {
  public: ['/', '/login', '/signup', '/about', '/pricing', '/auth/callback'],
  authenticated: ['/dashboard', '/settings', '/profile'],
  admin: ['/admin'],
  api: ['/api'],
}

function getRouteType(pathname: string): keyof typeof routeConfig | 'unknown' {
  for (const [type, routes] of Object.entries(routeConfig)) {
    if (routes.some(route => pathname === route || pathname.startsWith(route + '/'))) {
      return type as keyof typeof routeConfig
    }
  }
  return 'unknown'
}

// In middleware:
const routeType = getRouteType(request.nextUrl.pathname)

switch (routeType) {
  case 'public':
    // Allow through, but still refresh session
    break
  case 'authenticated':
    if (!user) redirect('/login')
    break
  case 'admin':
    if (!user) redirect('/login')
    // Check admin role
    break
  case 'api':
    // API routes handle their own auth
    break
  default:
    // Unknown routes: require auth by default (deny-by-default)
    if (!user) redirect('/login')
}
```

---

## Auth Helpers Packages

### @supabase/ssr (Recommended - Current)

The `@supabase/ssr` package is the modern replacement for `@supabase/auth-helpers-*`. It provides framework-agnostic cookie handling.

```bash
npm install @supabase/ssr @supabase/supabase-js
```

Key functions:
- `createBrowserClient()` — Client-side, uses cookies automatically
- `createServerClient()` — Server-side, requires cookie handlers

### @supabase/auth-helpers-nextjs (Legacy but Widely Used)

```bash
npm install @supabase/auth-helpers-nextjs @supabase/supabase-js
```

Provides:
- `createPagesBrowserClient()` — Pages Router client-side
- `createPagesServerClient()` — Pages Router server-side (getServerSideProps, API routes)
- `createRouteHandlerClient()` — App Router route handlers
- `createServerComponentClient()` — App Router server components
- `createMiddlewareClient()` — Middleware
- `SessionContextProvider` — React context for Pages Router
- `useUser()`, `useSession()`, `useSupabaseClient()` — React hooks

### @supabase/auth-helpers-react (Legacy)

```bash
npm install @supabase/auth-helpers-react
```

Provides:
- `SessionContextProvider` — Wraps your app to provide session context
- `useUser()` — Returns the current user
- `useSession()` — Returns the current session
- `useSupabaseClient()` — Returns the Supabase client

### Migration from auth-helpers to @supabase/ssr

```typescript
// BEFORE (auth-helpers-nextjs)
import { createServerComponentClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
const supabase = createServerComponentClient({ cookies })

// AFTER (@supabase/ssr)
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
const cookieStore = await cookies()
const supabase = createServerClient(url, key, {
  cookies: {
    getAll() { return cookieStore.getAll() },
    setAll(cookiesToSet) {
      cookiesToSet.forEach(({ name, value, options }) =>
        cookieStore.set(name, value, options))
    },
  },
})
```

---

## Token Refresh Handling

### How Supabase Token Refresh Works

Supabase uses JWTs with a default 1-hour expiry. The client library automatically refreshes the token before it expires using the refresh token stored in cookies/localStorage.

### Client-Side (Automatic)

The Supabase client handles refresh automatically. Just listen for the event:

```typescript
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'TOKEN_REFRESHED') {
    console.log('Token refreshed:', session?.access_token)
    // Update any external systems that need the new token
  }
  if (event === 'SIGNED_OUT') {
    // Token refresh failed (refresh token expired or revoked)
    // Redirect to login
    window.location.href = '/login'
  }
})
```

### Server-Side (Middleware Refresh)

In SSR apps, the middleware must refresh the session on every request to keep cookies up to date:

```typescript
// This is why middleware calls getUser() — it triggers a token refresh
// if the access token is expired but the refresh token is still valid
const { data: { user } } = await supabase.auth.getUser()
```

### Manual Token Refresh

If you need to manually trigger a refresh (rare):

```typescript
const { data, error } = await supabase.auth.refreshSession()
if (error) {
  // Refresh failed — user needs to re-authenticate
  await supabase.auth.signOut()
  window.location.href = '/login'
}
```

### Handling Expired Refresh Tokens

Refresh tokens have a longer lifespan (configurable in Supabase Dashboard, default 1 week). When they expire:

```typescript
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'SIGNED_OUT' && !session) {
    // This can happen when:
    // 1. User explicitly signed out
    // 2. Refresh token expired
    // 3. Session was revoked server-side
    clearApplicationState()
    redirectToLogin()
  }
})
```

### Configuring Token Lifetimes

In Supabase Dashboard > Authentication > Settings:
- **JWT Expiry**: Default 3600 seconds (1 hour). Lower = more secure, more refresh requests.
- **Refresh Token Rotation**: Enable for additional security (old refresh tokens are invalidated after use).
- **Refresh Token Reuse Interval**: Grace period for concurrent requests using the same refresh token.

---

## Custom Claims via raw_app_meta_data

### What are Custom Claims?

Supabase auth tokens contain two metadata fields:
- `raw_user_meta_data` — User-modifiable (set during signup, updatable by the user)
- `raw_app_meta_data` — Admin-only (set by service_role, not modifiable by the user)

Custom claims in `raw_app_meta_data` are included in the JWT and accessible in RLS policies.

### Setting Custom Claims (Service Role Only)

```typescript
// Edge Function or server-side code with service_role key
const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
)

// Set custom claims
const { data, error } = await supabaseAdmin.auth.admin.updateUserById(userId, {
  app_metadata: {
    role: 'admin',
    org_id: 'org_123',
    plan: 'pro',
    permissions: ['read', 'write', 'delete'],
  },
})
```

### Accessing Claims in RLS Policies

```sql
-- Access app_metadata claims in RLS
CREATE POLICY "Only pro users can access"
    ON public.premium_features FOR SELECT
    USING (
        (auth.jwt() -> 'app_metadata' ->> 'plan') = 'pro'
    );

-- Role-based access via claims
CREATE POLICY "Admin access"
    ON public.admin_settings FOR ALL
    USING (
        (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
    );

-- Org-based isolation via claims
CREATE POLICY "Tenant isolation via claims"
    ON public.tenant_data FOR ALL
    USING (
        (auth.jwt() -> 'app_metadata' ->> 'org_id') = org_id::text
    );
```

### Accessing Claims in Application Code

```typescript
// Client-side
const { data: { session } } = await supabase.auth.getSession()
const role = session?.user.app_metadata?.role
const orgId = session?.user.app_metadata?.org_id

// Server-side (from JWT)
const { data: { user } } = await supabase.auth.getUser()
const role = user?.app_metadata?.role
```

### Custom Claims Helper Function (Database)

Create a PostgreSQL function to set claims from within the database:

```sql
-- Function to set a custom claim (call from trigger or Edge Function)
CREATE OR REPLACE FUNCTION public.set_claim(
    uid UUID,
    claim TEXT,
    value JSONB
)
RETURNS TEXT AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM auth.users WHERE id = uid
    ) THEN
        RETURN 'User not found';
    END IF;

    UPDATE auth.users
    SET raw_app_meta_data =
        raw_app_meta_data || json_build_object(claim, value)::jsonb
    WHERE id = uid;

    RETURN 'OK';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Usage:
SELECT public.set_claim('user-uuid', 'role', '"admin"'::jsonb);
SELECT public.set_claim('user-uuid', 'org_id', '"org_123"'::jsonb);
SELECT public.set_claim('user-uuid', 'permissions', '["read","write"]'::jsonb);
```

### Important Notes on Custom Claims

1. **Claims are cached in the JWT**: Changes to `app_metadata` do not take effect until the token is refreshed. Force a refresh with `supabase.auth.refreshSession()`.
2. **Keep claims small**: The JWT is sent with every request. Large claims increase request size.
3. **Do not store sensitive data**: JWTs can be decoded by anyone (they are signed, not encrypted).
4. **Use claims for authorization, not authentication**: Claims determine what a user can do, not who they are.

---

## Linking auth.users to Public Profiles

### Why Link?

The `auth.users` table is in the `auth` schema and cannot be directly queried from the client via the PostgREST API. You need a `public.profiles` table that mirrors essential user data and can be queried with RLS.

### Database Setup

```sql
-- Create the profiles table
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    website TEXT,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user', 'viewer')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Anyone can read profiles (or restrict as needed)
CREATE POLICY "Public profiles are viewable by everyone"
    ON public.profiles FOR SELECT
    USING (true);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(
            NEW.raw_user_meta_data ->> 'full_name',
            NEW.raw_user_meta_data ->> 'name',
            ''
        ),
        COALESCE(
            NEW.raw_user_meta_data ->> 'avatar_url',
            NEW.raw_user_meta_data ->> 'picture',
            ''
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users insert
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();
```

### Keeping Profiles in Sync

When users update their email or metadata through Supabase Auth, sync it to the profiles table:

```sql
-- Sync email changes
CREATE OR REPLACE FUNCTION public.handle_user_updated()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.profiles SET
        email = NEW.email,
        full_name = COALESCE(
            NEW.raw_user_meta_data ->> 'full_name',
            NEW.raw_user_meta_data ->> 'name',
            profiles.full_name
        ),
        avatar_url = COALESCE(
            NEW.raw_user_meta_data ->> 'avatar_url',
            NEW.raw_user_meta_data ->> 'picture',
            profiles.avatar_url
        ),
        updated_at = now()
    WHERE id = NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_updated
    AFTER UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_user_updated();
```

### Handle User Deletion

```sql
-- The ON DELETE CASCADE on profiles.id handles this automatically.
-- But if you need cleanup logic:
CREATE OR REPLACE FUNCTION public.handle_user_deleted()
RETURNS TRIGGER AS $$
BEGIN
    -- Clean up user's storage files
    DELETE FROM storage.objects
    WHERE owner = OLD.id;

    -- Any other cleanup
    -- The CASCADE will handle profiles, org_members, etc.

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_deleted
    BEFORE DELETE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_user_deleted();
```

### Querying Profiles from the Client

```typescript
// Get current user's profile
async function getMyProfile() {
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Not authenticated')

  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single()

  if (error) throw error
  return data
}

// Get another user's public profile
async function getProfile(userId: string) {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, full_name, avatar_url, bio')
    .eq('id', userId)
    .single()

  if (error) throw error
  return data
}

// Update own profile
async function updateMyProfile(updates: {
  full_name?: string
  bio?: string
  avatar_url?: string
  website?: string
}) {
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Not authenticated')

  const { data, error } = await supabase
    .from('profiles')
    .update(updates)
    .eq('id', user.id)
    .select()
    .single()

  if (error) throw error
  return data
}
```

### Avatar Upload with Profile Update

```typescript
async function updateAvatar(file: File) {
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Not authenticated')

  // Upload to storage
  const filePath = `${user.id}/${Date.now()}_avatar.${file.name.split('.').pop()}`
  const { error: uploadError } = await supabase.storage
    .from('avatars')
    .upload(filePath, file, { upsert: true })

  if (uploadError) throw uploadError

  // Get public URL
  const { data: { publicUrl } } = supabase.storage
    .from('avatars')
    .getPublicUrl(filePath)

  // Update profile
  const { data, error } = await supabase
    .from('profiles')
    .update({ avatar_url: publicUrl })
    .eq('id', user.id)
    .select()
    .single()

  if (error) throw error
  return data
}
```

### Complete Profile Page Component (React)

```typescript
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthProvider'
import type { Database } from '@/types/supabase'

type Profile = Database['public']['Tables']['profiles']['Row']

export function ProfilePage() {
  const { user } = useAuth()
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [formData, setFormData] = useState({
    full_name: '',
    bio: '',
    website: '',
  })

  useEffect(() => {
    if (!user) return

    async function loadProfile() {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user!.id)
        .single()

      if (data) {
        setProfile(data)
        setFormData({
          full_name: data.full_name ?? '',
          bio: data.bio ?? '',
          website: data.website ?? '',
        })
      }
      setLoading(false)
    }

    loadProfile()
  }, [user])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!user) return

    setSaving(true)
    const { data, error } = await supabase
      .from('profiles')
      .update(formData)
      .eq('id', user.id)
      .select()
      .single()

    if (data) setProfile(data)
    setSaving(false)
  }

  async function handleAvatarChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file || !user) return

    const filePath = `${user.id}/avatar.${file.name.split('.').pop()}`
    const { error: uploadError } = await supabase.storage
      .from('avatars')
      .upload(filePath, file, { upsert: true })

    if (uploadError) {
      console.error('Upload error:', uploadError)
      return
    }

    const { data: { publicUrl } } = supabase.storage
      .from('avatars')
      .getPublicUrl(filePath)

    const { data } = await supabase
      .from('profiles')
      .update({ avatar_url: publicUrl })
      .eq('id', user.id)
      .select()
      .single()

    if (data) setProfile(data)
  }

  if (loading) return <div>Loading...</div>
  if (!profile) return <div>Profile not found</div>

  return (
    <div>
      <div>
        <img
          src={profile.avatar_url || '/default-avatar.png'}
          alt="Avatar"
          width={100}
          height={100}
        />
        <input type="file" accept="image/*" onChange={handleAvatarChange} />
      </div>

      <form onSubmit={handleSubmit}>
        <label>
          Full Name
          <input
            type="text"
            value={formData.full_name}
            onChange={e => setFormData(prev => ({ ...prev, full_name: e.target.value }))}
          />
        </label>

        <label>
          Bio
          <textarea
            value={formData.bio}
            onChange={e => setFormData(prev => ({ ...prev, bio: e.target.value }))}
          />
        </label>

        <label>
          Website
          <input
            type="url"
            value={formData.website}
            onChange={e => setFormData(prev => ({ ...prev, website: e.target.value }))}
          />
        </label>

        <button type="submit" disabled={saving}>
          {saving ? 'Saving...' : 'Save Profile'}
        </button>
      </form>

      <div>
        <p>Email: {profile.email}</p>
        <p>Role: {profile.role}</p>
        <p>Member since: {new Date(profile.created_at).toLocaleDateString()}</p>
      </div>
    </div>
  )
}
```
