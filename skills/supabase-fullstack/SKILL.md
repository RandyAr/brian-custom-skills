---
name: supabase-fullstack
description: >
  Supabase fullstack application generator. Triggers when the user mentions
  Supabase, Supabase project, RLS policies, Row Level Security, Supabase Edge Functions,
  Supabase auth, Supabase storage, Supabase realtime, fullstack app with Supabase,
  Supabase migration, Supabase TypeScript, supabase-js, Supabase client, auth.uid(),
  service_role, anon key, Supabase CLI, magic link, OAuth with Supabase, multi-tenant
  Supabase, Supabase triggers, Supabase functions, database functions, pgcrypto,
  Supabase React, Supabase Next.js, Supabase SvelteKit, Supabase Edge Functions,
  Supabase realtime subscriptions, Supabase storage buckets, Supabase RLS,
  Supabase auth helpers, Supabase SSR, Supabase row level security policies,
  Supabase database webhooks, Supabase scheduled functions, or building a
  fullstack app powered by Supabase with proper security and type safety.
---

# Supabase Fullstack Application Generator

You are an expert Supabase architect and fullstack developer. You generate complete Supabase-powered applications with production-grade SQL migrations, Row Level Security policies, Edge Functions, frontend integration code, and TypeScript types. Every output prioritizes security, type safety, and real-world best practices.

---

## Workflow

When the user describes an application, follow this sequence:

### Step 1 — Clarify Requirements

Before generating anything, confirm:
1. **Frontend framework**: Next.js App Router (default), Next.js Pages Router, React SPA, or SvelteKit.
2. **Auth methods**: Email/Password (default), Magic Link, OAuth providers (Google, GitHub, Apple, etc.), or phone OTP.
3. **Entity descriptions**: What data does the app manage? Users, organizations, resources, etc.
4. **Multi-tenancy**: Single-tenant or multi-tenant (org-based isolation)?
5. **Realtime needs**: Which tables/events need live updates?
6. **Storage needs**: File uploads (avatars, documents, images)?
7. **Edge Functions**: Any server-side logic (webhooks, Stripe, email, scheduled tasks)?

If the user provides enough context, infer sensible defaults and proceed. Only ask when genuinely ambiguous.

### Step 2 — Generate SQL Migrations

Produce numbered migration files following Supabase conventions:

```
supabase/migrations/
  20240101000000_initial_schema.sql
  20240101000001_rls_policies.sql
  20240101000002_triggers_and_functions.sql
  20240101000003_storage_buckets.sql
```

Each migration includes tables, RLS, triggers, and functions as described below.

### Step 3 — Generate Edge Functions

Produce Deno/TypeScript serverless functions in:

```
supabase/functions/
  function-name/
    index.ts
```

### Step 4 — Generate Frontend Integration

Produce client setup, auth flows, data hooks, and realtime subscriptions for the chosen framework.

### Step 5 — Generate TypeScript Types

Produce a `types/supabase.ts` file matching the schema, or instruct the user to run `supabase gen types typescript` for auto-generation.

### Step 6 — Security Audit

Run through the security checklist and verify every item before delivering.

---

## SQL Migration Generation

### Table Conventions

- Table names: **snake_case, plural** (e.g., `users`, `order_items`).
- Column names: **snake_case** (e.g., `first_name`, `created_at`).
- Primary keys: `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`.
- Foreign key columns: `{referenced_table_singular}_id` (e.g., `user_id`).
- All tables get `created_at TIMESTAMPTZ NOT NULL DEFAULT now()` and `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`.
- Soft delete tables get `deleted_at TIMESTAMPTZ`.
- Junction tables: `{table_a}_{table_b}` alphabetically (e.g., `posts_tags`).
- Index names: `idx_{table}_{column(s)}`.
- Constraint names: `chk_{table}_{column}`, `uq_{table}_{column}`, `fk_{table}_{column}`.
- Always index foreign key columns.

### Migration Template

```sql
-- Migration: 20240101000000_initial_schema
-- Description: Create core application tables

BEGIN;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "moddatetime" SCHEMA extensions;

-- ============================================================
-- TABLES
-- ============================================================

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user', 'viewer')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_profiles_email ON public.profiles (email);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ============================================================
-- TRIGGERS
-- ============================================================

CREATE TRIGGER handle_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION extensions.moddatetime(updated_at);

COMMIT;
```

### RLS Policies Per Table Per Role

Always enable RLS on every table and create explicit policies. Common patterns:

#### Owner-Based Access
```sql
-- User owns the row via user_id column
CREATE POLICY "Users can CRUD own rows"
    ON public.todos FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

#### Organization Membership
```sql
-- User is member of the org that owns the row
CREATE POLICY "Org members can view resources"
    ON public.resources FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.org_members
            WHERE org_members.org_id = resources.org_id
            AND org_members.user_id = auth.uid()
        )
    );
```

#### Public Read, Authenticated Write
```sql
-- Anyone can read, only authenticated users can insert
CREATE POLICY "Public read access"
    ON public.posts FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can create posts"
    ON public.posts FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);
```

#### Admin-Only Access
```sql
-- Only users with admin role can access
CREATE POLICY "Admins only"
    ON public.admin_settings FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );
```

#### Row-Level Tenant Isolation
```sql
-- Multi-tenant: users can only see their tenant's data
CREATE POLICY "Tenant isolation"
    ON public.tenant_resources FOR ALL
    USING (
        tenant_id = (
            SELECT tenant_id FROM public.profiles
            WHERE id = auth.uid()
        )
    )
    WITH CHECK (
        tenant_id = (
            SELECT tenant_id FROM public.profiles
            WHERE id = auth.uid()
        )
    );
```

### Trigger Functions

Always include these reusable trigger functions:

#### handle_updated_at — Auto-Update Timestamps
```sql
-- Option A: Use moddatetime extension (preferred in Supabase)
CREATE EXTENSION IF NOT EXISTS "moddatetime" SCHEMA extensions;

CREATE TRIGGER handle_updated_at
    BEFORE UPDATE ON public.your_table
    FOR EACH ROW
    EXECUTE FUNCTION extensions.moddatetime(updated_at);

-- Option B: Custom function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.your_table
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
```

#### handle_new_user — Create Profile on Signup
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''),
        COALESCE(NEW.raw_user_meta_data ->> 'avatar_url', '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users table
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();
```

#### handle_soft_delete — Archive Instead of Delete
```sql
CREATE OR REPLACE FUNCTION public.handle_soft_delete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.archived_records SET
        deleted_at = now(),
        deleted_by = auth.uid()
    WHERE id = OLD.id;

    -- Prevent actual deletion
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER soft_delete_instead
    BEFORE DELETE ON public.your_table
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_soft_delete();
```

#### audit_log_trigger — Log All Changes
```sql
CREATE TABLE public.audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_data JSONB,
    new_data JSONB,
    changed_by UUID REFERENCES auth.users(id),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_log_table_record ON public.audit_log (table_name, record_id);
CREATE INDEX idx_audit_log_changed_at ON public.audit_log (changed_at);

CREATE OR REPLACE FUNCTION public.audit_log_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.audit_log (table_name, record_id, action, new_data, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'INSERT', to_jsonb(NEW), auth.uid());
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO public.audit_log (table_name, record_id, action, old_data, new_data, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), auth.uid());
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO public.audit_log (table_name, record_id, action, old_data, changed_by)
        VALUES (TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD), auth.uid());
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply to any table:
CREATE TRIGGER audit_your_table
    AFTER INSERT OR UPDATE OR DELETE ON public.your_table
    FOR EACH ROW
    EXECUTE FUNCTION public.audit_log_trigger();
```

### Storage Bucket Policies

#### Avatar Uploads (User CRUD Own Files)
```sql
-- Create bucket (via Supabase dashboard or SQL)
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true);

-- Users can upload their own avatar
CREATE POLICY "Users can upload own avatar"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can update their own avatar
CREATE POLICY "Users can update own avatar"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can delete their own avatar
CREATE POLICY "Users can delete own avatar"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Anyone can view avatars (public bucket)
CREATE POLICY "Anyone can view avatars"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');
```

#### Private Document Uploads (Authenticated Only)
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false);

-- Authenticated users can upload to their folder
CREATE POLICY "Authenticated users upload own documents"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'documents'
        AND auth.role() = 'authenticated'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Users can read their own documents
CREATE POLICY "Users can read own documents"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'documents'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );
```

---

## Supabase Edge Functions

### Standard Edge Function Template

```typescript
// supabase/functions/function-name/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    // Create Supabase client with service role for admin operations
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    // Create Supabase client with user's JWT for RLS-respecting operations
    const authHeader = req.headers.get("Authorization")!
    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    )

    // Verify the user
    const { data: { user }, error: authError } = await supabaseUser.auth.getUser()
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // Parse request body
    const body = await req.json()

    // ... function logic here ...

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})
```

### Webhook Handler Pattern

```typescript
// supabase/functions/webhook-handler/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const signature = req.headers.get("x-webhook-signature")
  const body = await req.text()

  // Verify webhook signature
  const encoder = new TextEncoder()
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(Deno.env.get("WEBHOOK_SECRET")!),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  )
  const signed = await crypto.subtle.sign("HMAC", key, encoder.encode(body))
  const expectedSignature = btoa(String.fromCharCode(...new Uint8Array(signed)))

  if (signature !== expectedSignature) {
    return new Response("Invalid signature", { status: 401 })
  }

  const payload = JSON.parse(body)
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  )

  // Process webhook event
  switch (payload.type) {
    case "order.completed":
      await supabase.from("orders").update({ status: "completed" }).eq("id", payload.order_id)
      break
    // ... other event types
  }

  return new Response(JSON.stringify({ received: true }), { status: 200 })
})
```

### Scheduled Task Pattern (Invoked via pg_cron or external cron)

```typescript
// supabase/functions/daily-cleanup/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  // Verify this is called by an authorized source
  const authHeader = req.headers.get("Authorization")
  if (authHeader !== `Bearer ${Deno.env.get("CRON_SECRET")}`) {
    return new Response("Unauthorized", { status: 401 })
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  )

  // Delete expired sessions
  const { error: sessionError } = await supabase
    .from("sessions")
    .delete()
    .lt("expires_at", new Date().toISOString())

  // Archive old soft-deleted records
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
  const { data: archived } = await supabase
    .from("posts")
    .select("id")
    .not("deleted_at", "is", null)
    .lt("deleted_at", thirtyDaysAgo)

  return new Response(
    JSON.stringify({
      cleaned_sessions: !sessionError,
      archived_count: archived?.length ?? 0,
    }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  )
})
```

### Stripe Integration Pattern

```typescript
// supabase/functions/stripe-webhook/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import Stripe from "https://esm.sh/stripe@13?target=deno"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
})

serve(async (req) => {
  const body = await req.text()
  const signature = req.headers.get("stripe-signature")!
  const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET")!

  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret)
  } catch (err) {
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  )

  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object as Stripe.Checkout.Session
      await supabase.from("subscriptions").upsert({
        user_id: session.metadata?.user_id,
        stripe_customer_id: session.customer as string,
        stripe_subscription_id: session.subscription as string,
        status: "active",
        plan: session.metadata?.plan,
      })
      break
    }
    case "customer.subscription.updated": {
      const subscription = event.data.object as Stripe.Subscription
      await supabase
        .from("subscriptions")
        .update({ status: subscription.status })
        .eq("stripe_subscription_id", subscription.id)
      break
    }
    case "customer.subscription.deleted": {
      const subscription = event.data.object as Stripe.Subscription
      await supabase
        .from("subscriptions")
        .update({ status: "canceled" })
        .eq("stripe_subscription_id", subscription.id)
      break
    }
  }

  return new Response(JSON.stringify({ received: true }), { status: 200 })
})
```

### Email Sending Pattern

```typescript
// supabase/functions/send-email/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const { to, subject, html } = await req.json()

  // Send via Resend (or any email provider)
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${Deno.env.get("RESEND_API_KEY")}`,
    },
    body: JSON.stringify({
      from: "noreply@yourdomain.com",
      to,
      subject,
      html,
    }),
  })

  const data = await res.json()

  if (!res.ok) {
    return new Response(JSON.stringify({ error: data }), { status: 500 })
  }

  // Log email in database
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  )
  await supabase.from("email_log").insert({
    to_address: to,
    subject,
    status: "sent",
    provider_id: data.id,
  })

  return new Response(JSON.stringify({ success: true, id: data.id }), { status: 200 })
})
```

### File Processing Pattern

```typescript
// supabase/functions/process-upload/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const { record } = await req.json()
  // This function is triggered by a database webhook on storage.objects INSERT

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  )

  // Download the uploaded file
  const { data: fileData, error: downloadError } = await supabase.storage
    .from(record.bucket_id)
    .download(record.name)

  if (downloadError) {
    console.error("Download error:", downloadError)
    return new Response(JSON.stringify({ error: downloadError }), { status: 500 })
  }

  // Process the file (example: extract text, generate thumbnail, etc.)
  const fileBuffer = await fileData.arrayBuffer()
  // ... processing logic ...

  // Update metadata in database
  await supabase.from("file_metadata").insert({
    storage_path: `${record.bucket_id}/${record.name}`,
    size_bytes: fileBuffer.byteLength,
    content_type: record.metadata?.mimetype,
    processed_at: new Date().toISOString(),
  })

  return new Response(JSON.stringify({ processed: true }), { status: 200 })
})
```

---

## Frontend Integration

### Client Setup

```typescript
// lib/supabase.ts
import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/supabase'

export const supabase = createClient<Database>(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)
```

#### Server-Side Client (Next.js App Router)
```typescript
// lib/supabase-server.ts
import { createServerComponentClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import type { Database } from '@/types/supabase'

export function createServerClient() {
  return createServerComponentClient<Database>({ cookies })
}
```

#### SvelteKit Client
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

### Auth Flows (Complete Examples)

#### Email/Password Sign Up
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

#### Email/Password Sign In
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

#### Magic Link
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

#### OAuth (Google, GitHub, etc.)
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

#### Sign Out
```typescript
async function signOut() {
  const { error } = await supabase.auth.signOut()
  if (error) throw error
}
```

#### Auth State Listener and Session Management
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

#### Auth Context/Provider Pattern
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

#### Protected Route Wrapper Component
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

### Data Operations

#### CRUD with Type Safety
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

#### Filtering, Pagination, and Ordering
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

#### Joins (Select with Foreign Table Expansion)
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

#### Upsert Patterns
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

#### Bulk Operations
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

#### Error Handling Patterns
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

### Realtime Subscriptions

#### Postgres Changes (Row-Level)
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

#### Filtered Subscriptions
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

#### Presence (Track Online Users)
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

#### Broadcast (Ephemeral Messages, Cursors, Typing Indicators)
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

### File Upload (Storage)

#### Upload with Progress
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

#### Generate Signed URLs (Private Buckets)
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

#### Public URL Generation
```typescript
function getPublicUrl(bucket: string, path: string): string {
  const { data } = supabase.storage
    .from(bucket)
    .getPublicUrl(path)

  return data.publicUrl
}
```

#### Image Transformation
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

---

## TypeScript Type Generation

### Manual Type Structure (Matching Schema)

```typescript
// types/supabase.ts
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          email: string
          full_name: string | null
          avatar_url: string | null
          role: 'admin' | 'user' | 'viewer'
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          email: string
          full_name?: string | null
          avatar_url?: string | null
          role?: 'admin' | 'user' | 'viewer'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          email?: string
          full_name?: string | null
          avatar_url?: string | null
          role?: 'admin' | 'user' | 'viewer'
          created_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "profiles_id_fkey"
            columns: ["id"]
            referencedRelation: "users"
            referencedColumns: ["id"]
          }
        ]
      }
      posts: {
        Row: {
          id: string
          author_id: string
          title: string
          body: string | null
          status: 'draft' | 'published' | 'archived'
          published_at: string | null
          created_at: string
          updated_at: string
          deleted_at: string | null
        }
        Insert: {
          id?: string
          author_id: string
          title: string
          body?: string | null
          status?: 'draft' | 'published' | 'archived'
          published_at?: string | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Update: {
          id?: string
          author_id?: string
          title?: string
          body?: string | null
          status?: 'draft' | 'published' | 'archived'
          published_at?: string | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "posts_author_id_fkey"
            columns: ["author_id"]
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          }
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
  }
}

// Helper types for convenience
export type Tables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Row']
export type InsertTables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Insert']
export type UpdateTables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Update']
```

### Auto-Generation Command

Always recommend auto-generating types from the live schema:

```bash
# Install Supabase CLI if not present
npx supabase login

# Generate types from remote project
npx supabase gen types typescript --project-id YOUR_PROJECT_REF > types/supabase.ts

# Generate types from local dev database
npx supabase gen types typescript --local > types/supabase.ts
```

---

## Common Full Patterns

### Multi-Tenant SaaS (Org -> Members -> Resources with RLS Isolation)

```sql
-- Organizations
CREATE TABLE public.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    plan TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free', 'pro', 'enterprise')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Organization members (junction with role)
CREATE TABLE public.org_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    invited_by UUID REFERENCES auth.users(id),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (org_id, user_id)
);

CREATE INDEX idx_org_members_user_id ON public.org_members (user_id);
CREATE INDEX idx_org_members_org_id ON public.org_members (org_id);

-- Org-scoped resources
CREATE TABLE public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    created_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_projects_org_id ON public.projects (org_id);

-- RLS: Members can only see their org's projects
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their orgs"
    ON public.organizations FOR SELECT
    USING (
        id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid())
    );

CREATE POLICY "Members can view org membership"
    ON public.org_members FOR SELECT
    USING (
        org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid())
    );

CREATE POLICY "Admins can manage org members"
    ON public.org_members FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.org_members
            WHERE org_id = org_members.org_id
            AND user_id = auth.uid()
            AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "Members can view org projects"
    ON public.projects FOR SELECT
    USING (
        org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid())
    );

CREATE POLICY "Members can create org projects"
    ON public.projects FOR INSERT
    WITH CHECK (
        org_id IN (
            SELECT org_id FROM public.org_members
            WHERE user_id = auth.uid()
            AND role IN ('owner', 'admin', 'member')
        )
    );
```

### Social App (Users -> Posts -> Comments -> Likes with Counters)

```sql
CREATE TABLE public.posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    media_urls TEXT[] DEFAULT '{}',
    likes_count INTEGER NOT NULL DEFAULT 0,
    comments_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    parent_comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (post_id, user_id)
);

-- Counter trigger: increment/decrement likes_count
CREATE OR REPLACE FUNCTION public.handle_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.posts SET likes_count = likes_count - 1 WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_like_change
    AFTER INSERT OR DELETE ON public.likes
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_like_count();

-- Counter trigger: increment/decrement comments_count
CREATE OR REPLACE FUNCTION public.handle_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.posts SET comments_count = comments_count - 1 WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_comment_change
    AFTER INSERT OR DELETE ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_comment_count();

-- RLS
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read posts" ON public.posts FOR SELECT USING (true);
CREATE POLICY "Users can create posts" ON public.posts FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Users can update own posts" ON public.posts FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Users can delete own posts" ON public.posts FOR DELETE USING (auth.uid() = author_id);

CREATE POLICY "Anyone can read comments" ON public.comments FOR SELECT USING (true);
CREATE POLICY "Users can create comments" ON public.comments FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Users can delete own comments" ON public.comments FOR DELETE USING (auth.uid() = author_id);

CREATE POLICY "Anyone can read likes" ON public.likes FOR SELECT USING (true);
CREATE POLICY "Users can like posts" ON public.likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unlike posts" ON public.likes FOR DELETE USING (auth.uid() = user_id);
```

### E-Commerce (Products -> Orders -> Order Items with Inventory Triggers)

```sql
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
    currency TEXT NOT NULL DEFAULT 'usd',
    stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    image_urls TEXT[] DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'canceled', 'refunded')),
    total_cents INTEGER NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'usd',
    shipping_address JSONB,
    stripe_payment_intent_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_cents INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Inventory decrement on order confirmation
CREATE OR REPLACE FUNCTION public.handle_order_confirmed()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'confirmed' AND OLD.status = 'pending' THEN
        -- Decrement stock for all items in the order
        UPDATE public.products p
        SET stock_quantity = p.stock_quantity - oi.quantity
        FROM public.order_items oi
        WHERE oi.order_id = NEW.id
        AND oi.product_id = p.id;

        -- Verify no stock went negative
        IF EXISTS (
            SELECT 1 FROM public.products p
            JOIN public.order_items oi ON oi.product_id = p.id
            WHERE oi.order_id = NEW.id AND p.stock_quantity < 0
        ) THEN
            RAISE EXCEPTION 'Insufficient stock for one or more items';
        END IF;
    END IF;

    -- Restore stock on cancellation
    IF NEW.status = 'canceled' AND OLD.status IN ('confirmed', 'processing') THEN
        UPDATE public.products p
        SET stock_quantity = p.stock_quantity + oi.quantity
        FROM public.order_items oi
        WHERE oi.order_id = NEW.id
        AND oi.product_id = p.id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_order_status_change
    AFTER UPDATE OF status ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_order_confirmed();

-- Calculate order total trigger
CREATE OR REPLACE FUNCTION public.calculate_order_total()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.orders
    SET total_cents = (
        SELECT COALESCE(SUM(quantity * unit_price_cents), 0)
        FROM public.order_items
        WHERE order_id = NEW.order_id
    )
    WHERE id = NEW.order_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_order_item_change
    AFTER INSERT OR UPDATE OR DELETE ON public.order_items
    FOR EACH ROW
    EXECUTE FUNCTION public.calculate_order_total();

-- RLS
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active products" ON public.products FOR SELECT USING (is_active = true);
CREATE POLICY "Admins can manage products" ON public.products FOR ALL
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Users can view own orders" ON public.orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create orders" ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own order items" ON public.order_items FOR SELECT
    USING (order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid()));
CREATE POLICY "Users can manage own order items" ON public.order_items FOR INSERT
    WITH CHECK (order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid() AND status = 'pending'));
```

---

## Security Checklist (Verify Before Delivering)

Before delivering any Supabase application, verify every item:

- [ ] **RLS enabled on ALL tables** — Every table in `public` schema has `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`.
- [ ] **No table accessible without a policy** — If RLS is enabled with no policies, the table is inaccessible (which is safe but broken). Every table needs at least one SELECT policy.
- [ ] **Service role key NEVER exposed to frontend** — `SUPABASE_SERVICE_ROLE_KEY` only appears in Edge Functions or server-side code, never in `NEXT_PUBLIC_*` env vars or client bundles.
- [ ] **Auth checks use auth.uid() not client-passed IDs** — RLS policies and triggers use `auth.uid()` to identify the current user, never trusting a `user_id` field sent from the client in WHERE clauses for authorization.
- [ ] **Storage policies restrict file paths** — Storage policies use `storage.foldername(name)` to ensure users can only write to their own folders.
- [ ] **Edge Functions validate input** — All Edge Functions validate and sanitize request body, check auth headers, and handle errors gracefully.
- [ ] **Sensitive operations use service_role via Edge Functions** — Admin operations (user management, bypassing RLS, sending emails) happen in Edge Functions with `SUPABASE_SERVICE_ROLE_KEY`, not from the client.
- [ ] **CORS headers present on Edge Functions** — All Edge Functions that are called from the browser include proper CORS headers and handle OPTIONS preflight requests.
- [ ] **No unrestricted SELECT policies** — Avoid `USING (true)` on tables containing private data. Only use for genuinely public data (published blog posts, product listings).
- [ ] **Foreign key ON DELETE actions defined** — Every FK has explicit `ON DELETE CASCADE`, `ON DELETE SET NULL`, or `ON DELETE RESTRICT` to prevent orphaned rows.
- [ ] **Environment variables documented** — All required env vars are listed in a `.env.example` file.
