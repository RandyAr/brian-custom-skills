# Frontend Integration

## Client Setup

```typescript
// lib/supabase.ts
import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/supabase'

export const supabase = createClient<Database>(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)
```

### Server-Side Client (Next.js App Router)
```typescript
// lib/supabase-server.ts
import { createServerComponentClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import type { Database } from '@/types/supabase'

export function createServerClient() {
  return createServerComponentClient<Database>({ cookies })
}
```

### SvelteKit Client
```typescript
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js'
import type { Database } from '$lib/types/supabase'
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public'

export const supabase = createClient<Database>(
  PUBLIC_SUPABASE_URL,
  PUBLIC_SUPABASE_ANON_KEY
)
```

## Auth Flows (Complete Examples)

### Email/Password Sign Up
```typescript
async function signUp(email: string, password: string, fullName: string) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        full_name: fullName,
      },
    },
  })
  if (error) throw error
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
  if (error) throw error
  return data
}
```

### Magic Link
```typescript
async function signInWithMagicLink(email: string) {
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: `${window.location.origin}/auth/callback`,
    },
  })
  if (error) throw error
}
```

### OAuth (Google, GitHub, etc.)
```typescript
async function signInWithOAuth(provider: 'google' | 'github' | 'apple') {
  const { error } = await supabase.auth.signInWithOAuth({
    provider,
    options: {
      redirectTo: `${window.location.origin}/auth/callback`,
    },
  })
  if (error) throw error
}
```

### Sign Out
```typescript
async function signOut() {
  const { error } = await supabase.auth.signOut()
  if (error) throw error
}
```

### Auth State Listener and Session Management
```typescript
import { useEffect, useState } from 'react'
import type { User, Session } from '@supabase/supabase-js'

export function useAuth() {
  const [user, setUser] = useState<User | null>(null)
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setUser(session?.user ?? null)
      setLoading(false)
    })

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setSession(session)
        setUser(session?.user ?? null)
        setLoading(false)
      }
    )

    return () => subscription.unsubscribe()
  }, [])

  return { user, session, loading }
}
```

### Auth Context/Provider Pattern
```typescript
// contexts/AuthContext.tsx
import { createContext, useContext, useEffect, useState, ReactNode } from 'react'
import type { User, Session } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'

type AuthContextType = {
  user: User | null
  session: Session | null
  loading: boolean
  signIn: (email: string, password: string) => Promise<void>
  signUp: (email: string, password: string) => Promise<void>
  signOut: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setUser(session?.user ?? null)
      setLoading(false)
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setSession(session)
        setUser(session?.user ?? null)
      }
    )

    return () => subscription.unsubscribe()
  }, [])

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
  }

  const signUp = async (email: string, password: string) => {
    const { error } = await supabase.auth.signUp({ email, password })
    if (error) throw error
  }

  const signOut = async () => {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
  }

  return (
    <AuthContext.Provider value={{ user, session, loading, signIn, signUp, signOut }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
```

### Protected Route Wrapper Component
```typescript
// components/ProtectedRoute.tsx
import { useAuth } from '@/contexts/AuthContext'
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!loading && !user) {
      router.push('/login')
    }
  }, [user, loading, router])

  if (loading) {
    return <div>Loading...</div>
  }

  if (!user) {
    return null
  }

  return <>{children}</>
}
```

## Data Operations

### CRUD with Type Safety
```typescript
import type { Database } from '@/types/supabase'

type Post = Database['public']['Tables']['posts']['Row']
type PostInsert = Database['public']['Tables']['posts']['Insert']
type PostUpdate = Database['public']['Tables']['posts']['Update']

// CREATE
async function createPost(post: PostInsert): Promise<Post> {
  const { data, error } = await supabase
    .from('posts')
    .insert(post)
    .select()
    .single()
  if (error) throw error
  return data
}

// READ (single)
async function getPost(id: string): Promise<Post> {
  const { data, error } = await supabase
    .from('posts')
    .select('*')
    .eq('id', id)
    .single()
  if (error) throw error
  return data
}

// UPDATE
async function updatePost(id: string, updates: PostUpdate): Promise<Post> {
  const { data, error } = await supabase
    .from('posts')
    .update(updates)
    .eq('id', id)
    .select()
    .single()
  if (error) throw error
  return data
}

// DELETE
async function deletePost(id: string): Promise<void> {
  const { error } = await supabase
    .from('posts')
    .delete()
    .eq('id', id)
  if (error) throw error
}
```

### Filtering, Pagination, and Ordering
```typescript
async function getPosts({
  page = 1,
  pageSize = 20,
  status,
  search,
  orderBy = 'created_at',
  ascending = false,
}: {
  page?: number
  pageSize?: number
  status?: string
  search?: string
  orderBy?: string
  ascending?: boolean
}) {
  let query = supabase
    .from('posts')
    .select('*, author:profiles(full_name, avatar_url)', { count: 'exact' })

  // Filtering
  if (status) {
    query = query.eq('status', status)
  }
  if (search) {
    query = query.ilike('title', `%${search}%`)
  }

  // Pagination
  const from = (page - 1) * pageSize
  const to = from + pageSize - 1
  query = query.range(from, to)

  // Ordering
  query = query.order(orderBy, { ascending })

  const { data, error, count } = await query
  if (error) throw error

  return {
    data,
    count,
    page,
    pageSize,
    totalPages: Math.ceil((count ?? 0) / pageSize),
  }
}
```

### Joins (Select with Foreign Table Expansion)
```typescript
// One-to-many: posts with their comments
const { data } = await supabase
  .from('posts')
  .select(`
    *,
    comments (
      id,
      body,
      created_at,
      author:profiles (full_name, avatar_url)
    )
  `)
  .eq('id', postId)
  .single()

// Many-to-many: posts with their tags (via junction table)
const { data } = await supabase
  .from('posts')
  .select(`
    *,
    posts_tags (
      tags (id, name, slug)
    )
  `)
```

### Upsert Patterns
```typescript
// Single upsert (insert or update based on unique constraint)
const { data, error } = await supabase
  .from('user_preferences')
  .upsert(
    { user_id: userId, theme: 'dark', language: 'en' },
    { onConflict: 'user_id' }
  )
  .select()
  .single()

// Bulk upsert
const { data, error } = await supabase
  .from('products')
  .upsert(
    products.map(p => ({ sku: p.sku, name: p.name, price: p.price })),
    { onConflict: 'sku' }
  )
  .select()
```

### Bulk Operations
```typescript
// Bulk insert
const { data, error } = await supabase
  .from('tags')
  .insert([
    { name: 'JavaScript', slug: 'javascript' },
    { name: 'TypeScript', slug: 'typescript' },
    { name: 'React', slug: 'react' },
  ])
  .select()

// Bulk update (update all matching rows)
const { data, error } = await supabase
  .from('notifications')
  .update({ read: true })
  .eq('user_id', userId)
  .eq('read', false)
  .select()

// Bulk delete
const { error } = await supabase
  .from('cart_items')
  .delete()
  .eq('cart_id', cartId)
```

### Error Handling Patterns
```typescript
import { PostgrestError } from '@supabase/supabase-js'

class SupabaseError extends Error {
  code: string
  details: string

  constructor(error: PostgrestError) {
    super(error.message)
    this.code = error.code
    this.details = error.details
  }
}

async function safeQuery<T>(
  queryFn: () => Promise<{ data: T | null; error: PostgrestError | null }>
): Promise<T> {
  const { data, error } = await queryFn()

  if (error) {
    // Handle specific error codes
    switch (error.code) {
      case '23505': // unique_violation
        throw new SupabaseError({ ...error, message: 'A record with this value already exists.' })
      case '23503': // foreign_key_violation
        throw new SupabaseError({ ...error, message: 'Referenced record does not exist.' })
      case '42501': // insufficient_privilege (RLS)
        throw new SupabaseError({ ...error, message: 'You do not have permission to perform this action.' })
      default:
        throw new SupabaseError(error)
    }
  }

  if (data === null) {
    throw new Error('No data returned')
  }

  return data
}

// Usage
const post = await safeQuery(() =>
  supabase.from('posts').select('*').eq('id', postId).single()
)
```

## Realtime Subscriptions

### Postgres Changes (Row-Level)
```typescript
// Listen to all changes on a table
const channel = supabase
  .channel('posts-changes')
  .on(
    'postgres_changes',
    { event: '*', schema: 'public', table: 'posts' },
    (payload) => {
      console.log('Change:', payload.eventType, payload.new, payload.old)
      switch (payload.eventType) {
        case 'INSERT':
          setPosts(prev => [...prev, payload.new as Post])
          break
        case 'UPDATE':
          setPosts(prev => prev.map(p => p.id === (payload.new as Post).id ? payload.new as Post : p))
          break
        case 'DELETE':
          setPosts(prev => prev.filter(p => p.id !== (payload.old as Post).id))
          break
      }
    }
  )
  .subscribe()

// Cleanup
return () => {
  supabase.removeChannel(channel)
}
```

### Filtered Subscriptions
```typescript
// Only listen to changes for a specific room
const channel = supabase
  .channel('room-messages')
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'messages',
      filter: `room_id=eq.${roomId}`,
    },
    (payload) => {
      setMessages(prev => [...prev, payload.new as Message])
    }
  )
  .subscribe()
```

### Presence (Track Online Users)
```typescript
const channel = supabase.channel('online-users', {
  config: { presence: { key: userId } },
})

channel
  .on('presence', { event: 'sync' }, () => {
    const state = channel.presenceState()
    const onlineUsers = Object.keys(state)
    setOnlineUsers(onlineUsers)
  })
  .on('presence', { event: 'join' }, ({ key, newPresences }) => {
    console.log('User joined:', key, newPresences)
  })
  .on('presence', { event: 'leave' }, ({ key, leftPresences }) => {
    console.log('User left:', key, leftPresences)
  })
  .subscribe(async (status) => {
    if (status === 'SUBSCRIBED') {
      await channel.track({
        user_id: userId,
        username: user.full_name,
        online_at: new Date().toISOString(),
      })
    }
  })
```

### Broadcast (Ephemeral Messages, Cursors, Typing Indicators)
```typescript
const channel = supabase.channel('room:typing')

// Send typing indicator
channel.send({
  type: 'broadcast',
  event: 'typing',
  payload: { user_id: userId, username: user.full_name },
})

// Listen for typing indicators
channel
  .on('broadcast', { event: 'typing' }, ({ payload }) => {
    setTypingUsers(prev => {
      const updated = new Map(prev)
      updated.set(payload.user_id, {
        username: payload.username,
        timestamp: Date.now(),
      })
      return updated
    })
  })
  .subscribe()
```

## File Upload (Storage)

### Upload with Progress
```typescript
async function uploadFile(
  bucket: string,
  path: string,
  file: File,
  onProgress?: (percent: number) => void
): Promise<string> {
  const { data, error } = await supabase.storage
    .from(bucket)
    .upload(path, file, {
      cacheControl: '3600',
      upsert: false,
    })

  if (error) throw error
  return data.path
}

// React component example with progress
function FileUpload({ bucket, folder }: { bucket: string; folder: string }) {
  const [uploading, setUploading] = useState(false)

  async function handleUpload(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0]
    if (!file) return

    setUploading(true)
    try {
      const filePath = `${folder}/${Date.now()}_${file.name}`
      const { data, error } = await supabase.storage
        .from(bucket)
        .upload(filePath, file)

      if (error) throw error

      // Get the public URL
      const { data: { publicUrl } } = supabase.storage
        .from(bucket)
        .getPublicUrl(data.path)

      console.log('Uploaded:', publicUrl)
    } catch (error) {
      console.error('Upload error:', error)
    } finally {
      setUploading(false)
    }
  }

  return (
    <input
      type="file"
      onChange={handleUpload}
      disabled={uploading}
    />
  )
}
```

### Generate Signed URLs (Private Buckets)
```typescript
async function getSignedUrl(bucket: string, path: string, expiresIn = 3600): Promise<string> {
  const { data, error } = await supabase.storage
    .from(bucket)
    .createSignedUrl(path, expiresIn)

  if (error) throw error
  return data.signedUrl
}

// Batch signed URLs
async function getSignedUrls(bucket: string, paths: string[]): Promise<string[]> {
  const { data, error } = await supabase.storage
    .from(bucket)
    .createSignedUrls(paths, 3600)

  if (error) throw error
  return data.map(d => d.signedUrl)
}
```

### Public URL Generation
```typescript
function getPublicUrl(bucket: string, path: string): string {
  const { data } = supabase.storage
    .from(bucket)
    .getPublicUrl(path)

  return data.publicUrl
}
```

### Image Transformation
```typescript
function getTransformedImageUrl(
  bucket: string,
  path: string,
  options: { width?: number; height?: number; quality?: number; format?: 'origin' | 'avif' }
): string {
  const { data } = supabase.storage
    .from(bucket)
    .getPublicUrl(path, {
      transform: {
        width: options.width ?? 300,
        height: options.height ?? 300,
        quality: options.quality ?? 80,
        format: options.format ?? 'origin',
      },
    })

  return data.publicUrl
}

// Usage: avatar thumbnail
const avatarThumb = getTransformedImageUrl('avatars', user.avatar_path, {
  width: 64,
  height: 64,
  quality: 80,
})
```
