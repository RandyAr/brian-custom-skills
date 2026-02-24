# SQL Migration Generation

## Table Conventions

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

## Migration Template

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

## RLS Policies Per Table Per Role

Always enable RLS on every table and create explicit policies. Common patterns:

### Owner-Based Access
```sql
-- User owns the row via user_id column
CREATE POLICY "Users can CRUD own rows"
    ON public.todos FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

### Organization Membership
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

### Public Read, Authenticated Write
```sql
-- Anyone can read, only authenticated users can insert
CREATE POLICY "Public read access"
    ON public.posts FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can create posts"
    ON public.posts FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);
```

### Admin-Only Access
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

### Row-Level Tenant Isolation
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

## Trigger Functions

Always include these reusable trigger functions:

### handle_updated_at — Auto-Update Timestamps
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

### handle_new_user — Create Profile on Signup
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

### handle_soft_delete — Archive Instead of Delete
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

### audit_log_trigger — Log All Changes
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

## Storage Bucket Policies

### Avatar Uploads (User CRUD Own Files)
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

### Private Document Uploads (Authenticated Only)
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
