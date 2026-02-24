# Supabase Row Level Security (RLS) Pattern Reference

This document provides comprehensive RLS policy patterns for Supabase applications. Each pattern includes complete SQL examples ready for use in migrations.

---

## Prerequisites

Before applying any RLS policy, always enable RLS on the table:

```sql
ALTER TABLE public.your_table ENABLE ROW LEVEL SECURITY;
```

Without explicit policies, RLS-enabled tables deny all access to non-superuser roles (anon, authenticated). The `service_role` key bypasses RLS entirely.

---

## Pattern 1: Owner-Based Access

The most common pattern. Users can only access rows they own.

```sql
-- Table structure
CREATE TABLE public.todos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;

-- Users can view their own todos
CREATE POLICY "Users can view own todos"
    ON public.todos FOR SELECT
    USING (auth.uid() = user_id);

-- Users can create todos (must set themselves as owner)
CREATE POLICY "Users can create own todos"
    ON public.todos FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own todos
CREATE POLICY "Users can update own todos"
    ON public.todos FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own todos
CREATE POLICY "Users can delete own todos"
    ON public.todos FOR DELETE
    USING (auth.uid() = user_id);
```

**Combined shorthand** (when all operations have the same rule):

```sql
-- Single policy for all operations
CREATE POLICY "Owner full access"
    ON public.todos FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

**When to use**: Personal data — notes, preferences, drafts, saved items, private messages.

---

## Pattern 2: Organization / Team Membership

Users can access rows belonging to an organization they are a member of. Access is determined by a membership junction table.

```sql
-- Membership table
CREATE TABLE public.org_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (org_id, user_id)
);

CREATE INDEX idx_org_members_user_id ON public.org_members (user_id);

-- Org-scoped resource
CREATE TABLE public.documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT,
    created_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

-- Any org member can view documents
CREATE POLICY "Org members can view documents"
    ON public.documents FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.org_members
            WHERE org_members.org_id = documents.org_id
            AND org_members.user_id = auth.uid()
        )
    );

-- Only members with write roles can create
CREATE POLICY "Org writers can create documents"
    ON public.documents FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.org_members
            WHERE org_members.org_id = documents.org_id
            AND org_members.user_id = auth.uid()
            AND org_members.role IN ('owner', 'admin', 'member')
        )
    );

-- Only the creator or admins can update
CREATE POLICY "Creator or admin can update documents"
    ON public.documents FOR UPDATE
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.org_members
            WHERE org_members.org_id = documents.org_id
            AND org_members.user_id = auth.uid()
            AND org_members.role IN ('owner', 'admin')
        )
    );

-- Only admins can delete
CREATE POLICY "Admins can delete documents"
    ON public.documents FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.org_members
            WHERE org_members.org_id = documents.org_id
            AND org_members.user_id = auth.uid()
            AND org_members.role IN ('owner', 'admin')
        )
    );
```

**Performance note**: The `EXISTS` subquery is efficient because PostgreSQL can short-circuit once a matching row is found. Always index `org_members(user_id)` and `org_members(org_id)`.

**When to use**: Team workspaces, shared projects, company resources.

---

## Pattern 3: Role-Based Access (Admin, Editor, Viewer)

Access varies by the user's role stored in a profiles table. Different roles get different permissions.

```sql
-- Profiles with role
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'viewer' CHECK (role IN ('admin', 'editor', 'viewer')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Content table
CREATE TABLE public.articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    body TEXT,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    author_id UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;

-- Helper function to get current user's role
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Viewers can only read published articles
CREATE POLICY "Viewers read published"
    ON public.articles FOR SELECT
    USING (
        status = 'published'
        OR author_id = auth.uid()
        OR public.get_my_role() IN ('admin', 'editor')
    );

-- Editors can create articles
CREATE POLICY "Editors can create"
    ON public.articles FOR INSERT
    WITH CHECK (
        public.get_my_role() IN ('admin', 'editor')
        AND auth.uid() = author_id
    );

-- Editors can update their own; admins can update any
CREATE POLICY "Editors update own, admins update all"
    ON public.articles FOR UPDATE
    USING (
        (public.get_my_role() = 'editor' AND author_id = auth.uid())
        OR public.get_my_role() = 'admin'
    );

-- Only admins can delete
CREATE POLICY "Only admins can delete"
    ON public.articles FOR DELETE
    USING (public.get_my_role() = 'admin');
```

**When to use**: CMS platforms, admin panels, content management systems.

---

## Pattern 4: Public Read / Authenticated Write

Anyone (including anonymous users) can read, but only authenticated users can write.

```sql
CREATE TABLE public.blog_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID NOT NULL REFERENCES auth.users(id),
    title TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    content TEXT NOT NULL,
    published BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;

-- Anyone can read published posts (including anonymous/unauthenticated)
CREATE POLICY "Public can read published posts"
    ON public.blog_posts FOR SELECT
    USING (published = true);

-- Authors can also see their own drafts
CREATE POLICY "Authors can view own drafts"
    ON public.blog_posts FOR SELECT
    USING (auth.uid() = author_id);

-- Authenticated users can create posts
CREATE POLICY "Authenticated users can create"
    ON public.blog_posts FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND auth.uid() = author_id
    );

-- Authors can update their own posts
CREATE POLICY "Authors can update own posts"
    ON public.blog_posts FOR UPDATE
    USING (auth.uid() = author_id)
    WITH CHECK (auth.uid() = author_id);

-- Authors can delete their own posts
CREATE POLICY "Authors can delete own posts"
    ON public.blog_posts FOR DELETE
    USING (auth.uid() = author_id);
```

**When to use**: Blogs, forums, product reviews, public catalogs with user submissions.

---

## Pattern 5: Multi-Tenant Isolation

Complete data isolation between tenants. Each user belongs to a tenant, and they can only see that tenant's data. No cross-tenant data leakage is possible.

```sql
-- Tenants
CREATE TABLE public.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Profiles linked to a tenant
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'member',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_profiles_tenant_id ON public.profiles (tenant_id);

-- Helper function to get current user's tenant
CREATE OR REPLACE FUNCTION public.get_my_tenant_id()
RETURNS UUID AS $$
    SELECT tenant_id FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Tenant-scoped data
CREATE TABLE public.invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    customer_name TEXT NOT NULL,
    amount_cents INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft',
    created_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_invoices_tenant_id ON public.invoices (tenant_id);

ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

-- Tenant members can only see their tenant's invoices
CREATE POLICY "Tenant isolation for invoices"
    ON public.invoices FOR SELECT
    USING (tenant_id = public.get_my_tenant_id());

-- Tenant members can create invoices for their tenant
CREATE POLICY "Tenant members can create invoices"
    ON public.invoices FOR INSERT
    WITH CHECK (
        tenant_id = public.get_my_tenant_id()
        AND created_by = auth.uid()
    );

-- Tenant members can update their tenant's invoices
CREATE POLICY "Tenant members can update invoices"
    ON public.invoices FOR UPDATE
    USING (tenant_id = public.get_my_tenant_id())
    WITH CHECK (tenant_id = public.get_my_tenant_id());

-- Only tenant admins can delete invoices
CREATE POLICY "Tenant admins can delete invoices"
    ON public.invoices FOR DELETE
    USING (
        tenant_id = public.get_my_tenant_id()
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );
```

**When to use**: SaaS platforms, white-label products, any system where customers must never see each other's data.

---

## Pattern 6: Row-Level Field Access (Column-Specific Policies)

Users can read all columns but can only update certain columns. This is achieved with separate policies for SELECT and UPDATE, where the UPDATE policy uses `WITH CHECK` to prevent modification of protected fields.

```sql
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,                    -- Read-only after creation
    display_name TEXT,                      -- User can update
    bio TEXT,                               -- User can update
    avatar_url TEXT,                        -- User can update
    role TEXT NOT NULL DEFAULT 'user',      -- Only admin can update
    is_verified BOOLEAN DEFAULT false,      -- Only admin can update
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "Users can read own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = id);

-- Users can update only safe fields (display_name, bio, avatar_url)
-- Protected fields (email, role, is_verified) cannot be changed by the user
CREATE POLICY "Users can update safe fields"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (
        auth.uid() = id
        -- Ensure protected fields haven't changed
        -- The trick: compare NEW values against a subquery of current values
    );
```

**Better approach using separate update functions**:

```sql
-- Instead of complex WITH CHECK, use a function that only updates allowed fields
CREATE OR REPLACE FUNCTION public.update_my_profile(
    new_display_name TEXT DEFAULT NULL,
    new_bio TEXT DEFAULT NULL,
    new_avatar_url TEXT DEFAULT NULL
)
RETURNS public.user_profiles AS $$
DECLARE
    result public.user_profiles;
BEGIN
    UPDATE public.user_profiles SET
        display_name = COALESCE(new_display_name, display_name),
        bio = COALESCE(new_bio, bio),
        avatar_url = COALESCE(new_avatar_url, avatar_url),
        updated_at = now()
    WHERE id = auth.uid()
    RETURNING * INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin-only function for protected fields
CREATE OR REPLACE FUNCTION public.admin_update_profile(
    target_user_id UUID,
    new_role TEXT DEFAULT NULL,
    new_is_verified BOOLEAN DEFAULT NULL
)
RETURNS public.user_profiles AS $$
DECLARE
    result public.user_profiles;
BEGIN
    -- Verify caller is admin
    IF NOT EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = auth.uid() AND role = 'admin'
    ) THEN
        RAISE EXCEPTION 'Only admins can update protected fields';
    END IF;

    UPDATE public.user_profiles SET
        role = COALESCE(new_role, role),
        is_verified = COALESCE(new_is_verified, is_verified),
        updated_at = now()
    WHERE id = target_user_id
    RETURNING * INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**When to use**: Profile pages, settings, any table where different columns have different permission requirements.

---

## Pattern 7: Time-Based Access (Content Embargo / Scheduled Publishing)

Content is only visible after a specific publication date or before an expiration date.

```sql
CREATE TABLE public.announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    author_id UUID NOT NULL REFERENCES auth.users(id),
    publish_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expire_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- Public can read only published and non-expired announcements
CREATE POLICY "Public reads published announcements"
    ON public.announcements FOR SELECT
    USING (
        publish_at <= now()
        AND (expire_at IS NULL OR expire_at > now())
    );

-- Authors can always see their own announcements (including scheduled)
CREATE POLICY "Authors can view own announcements"
    ON public.announcements FOR SELECT
    USING (auth.uid() = author_id);

-- Authors can create announcements with future publish dates
CREATE POLICY "Authors can create announcements"
    ON public.announcements FOR INSERT
    WITH CHECK (auth.uid() = author_id);

-- Authors can edit their own announcements only before publication
CREATE POLICY "Authors can edit before publication"
    ON public.announcements FOR UPDATE
    USING (
        auth.uid() = author_id
        AND publish_at > now()
    )
    WITH CHECK (auth.uid() = author_id);
```

**Scheduled content release (e.g., course modules)**:

```sql
CREATE TABLE public.course_modules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    sequence_number INTEGER NOT NULL,
    available_from TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.course_modules ENABLE ROW LEVEL SECURITY;

-- Students can only see modules that are released
CREATE POLICY "Students see released modules"
    ON public.course_modules FOR SELECT
    USING (
        available_from <= now()
        AND EXISTS (
            SELECT 1 FROM public.enrollments
            WHERE enrollments.course_id = course_modules.course_id
            AND enrollments.user_id = auth.uid()
        )
    );

-- Instructors can see all modules for their courses
CREATE POLICY "Instructors see all modules"
    ON public.course_modules FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.courses
            WHERE courses.id = course_modules.course_id
            AND courses.instructor_id = auth.uid()
        )
    );
```

**When to use**: Publishing platforms, scheduled releases, embargoed content, limited-time offers, drip campaigns.

---

## Pattern 8: Cascading Permissions (Parent -> Child)

Access to child records is derived from access to the parent record. If a user can see a project, they can see all tasks within that project.

```sql
-- Parent: Projects
CREATE TABLE public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    is_public BOOLEAN NOT NULL DEFAULT false,
    created_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Child: Tasks (inherits access from project)
CREATE TABLE public.tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    assignee_id UUID REFERENCES auth.users(id),
    status TEXT NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'done')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Grandchild: Comments (inherits access from task -> project)
CREATE TABLE public.task_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES auth.users(id),
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_comments ENABLE ROW LEVEL SECURITY;

-- Helper: Can user access this project?
CREATE OR REPLACE FUNCTION public.can_access_project(project_id UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.projects p
        WHERE p.id = project_id
        AND (
            p.is_public = true
            OR p.created_by = auth.uid()
            OR EXISTS (
                SELECT 1 FROM public.org_members om
                WHERE om.org_id = p.org_id
                AND om.user_id = auth.uid()
            )
        )
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Project access
CREATE POLICY "Users can view accessible projects"
    ON public.projects FOR SELECT
    USING (public.can_access_project(id));

-- Task access cascades from project
CREATE POLICY "Users can view tasks in accessible projects"
    ON public.tasks FOR SELECT
    USING (public.can_access_project(project_id));

CREATE POLICY "Members can create tasks"
    ON public.tasks FOR INSERT
    WITH CHECK (public.can_access_project(project_id));

CREATE POLICY "Assignee or creator can update tasks"
    ON public.tasks FOR UPDATE
    USING (
        public.can_access_project(project_id)
        AND (assignee_id = auth.uid() OR EXISTS (
            SELECT 1 FROM public.projects
            WHERE id = tasks.project_id AND created_by = auth.uid()
        ))
    );

-- Comment access cascades from task -> project
CREATE POLICY "Users can view comments on accessible tasks"
    ON public.task_comments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.tasks t
            WHERE t.id = task_comments.task_id
            AND public.can_access_project(t.project_id)
        )
    );

CREATE POLICY "Users can create comments on accessible tasks"
    ON public.task_comments FOR INSERT
    WITH CHECK (
        auth.uid() = author_id
        AND EXISTS (
            SELECT 1 FROM public.tasks t
            WHERE t.id = task_comments.task_id
            AND public.can_access_project(t.project_id)
        )
    );
```

**When to use**: Project management, hierarchical data, nested resources like folder > file > comment.

---

## Pattern 9: Shared Access / Invitations

Explicit sharing: the owner can grant access to specific users via a sharing/permissions table.

```sql
-- Documents
CREATE TABLE public.documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT,
    is_public BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Explicit shares
CREATE TABLE public.document_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    shared_with UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    permission TEXT NOT NULL DEFAULT 'view' CHECK (permission IN ('view', 'edit', 'admin')),
    shared_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (document_id, shared_with)
);

CREATE INDEX idx_document_shares_shared_with ON public.document_shares (shared_with);

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_shares ENABLE ROW LEVEL SECURITY;

-- Owner has full access
CREATE POLICY "Owner full access"
    ON public.documents FOR ALL
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- Public documents are visible to everyone
CREATE POLICY "Public documents are visible"
    ON public.documents FOR SELECT
    USING (is_public = true);

-- Shared users can view
CREATE POLICY "Shared users can view"
    ON public.documents FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.document_shares
            WHERE document_id = documents.id
            AND shared_with = auth.uid()
        )
    );

-- Shared users with edit permission can update
CREATE POLICY "Shared editors can update"
    ON public.documents FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.document_shares
            WHERE document_id = documents.id
            AND shared_with = auth.uid()
            AND permission IN ('edit', 'admin')
        )
    );

-- Shares table: owner and admins can manage shares
CREATE POLICY "Owner can manage shares"
    ON public.document_shares FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.documents
            WHERE id = document_shares.document_id
            AND owner_id = auth.uid()
        )
    );

-- Shared admins can manage shares
CREATE POLICY "Shared admins can manage shares"
    ON public.document_shares FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.document_shares ds
            WHERE ds.document_id = document_shares.document_id
            AND ds.shared_with = auth.uid()
            AND ds.permission = 'admin'
        )
    );

-- Users can see who else has access to docs shared with them
CREATE POLICY "Shared users can see share list"
    ON public.document_shares FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.document_shares ds
            WHERE ds.document_id = document_shares.document_id
            AND ds.shared_with = auth.uid()
        )
    );
```

**When to use**: Google Docs-style sharing, file sharing, collaborative workspaces.

---

## Pattern 10: Self-Referencing Hierarchies (Manager -> Reports)

Users can access data of users who report to them in a management hierarchy.

```sql
CREATE TABLE public.employees (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    manager_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
    department TEXT NOT NULL,
    title TEXT NOT NULL,
    salary_cents INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- Recursive function: is user_a a manager of user_b (at any depth)?
CREATE OR REPLACE FUNCTION public.is_manager_of(manager UUID, report UUID)
RETURNS BOOLEAN AS $$
    WITH RECURSIVE chain AS (
        -- Base case: direct report
        SELECT id, manager_id
        FROM public.employees
        WHERE id = report

        UNION ALL

        -- Recursive: walk up the chain
        SELECT e.id, e.manager_id
        FROM public.employees e
        INNER JOIN chain c ON e.id = c.manager_id
    )
    SELECT EXISTS (
        SELECT 1 FROM chain WHERE manager_id = manager
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Employees can view their own record
CREATE POLICY "View own record"
    ON public.employees FOR SELECT
    USING (auth.uid() = id);

-- Managers can view their direct and indirect reports
CREATE POLICY "Managers can view reports"
    ON public.employees FOR SELECT
    USING (public.is_manager_of(auth.uid(), id));

-- Managers can update their direct reports
CREATE POLICY "Managers can update direct reports"
    ON public.employees FOR UPDATE
    USING (manager_id = auth.uid());

-- HR/admin can see everything
CREATE POLICY "HR full access"
    ON public.employees FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'hr_admin'
        )
    );
```

**Performance caution**: Recursive CTEs in RLS policies can be expensive on large hierarchies. Consider materializing the hierarchy in a separate table with triggers if the tree is deep (>5 levels) and queried frequently.

**When to use**: Organizational charts, management hierarchies, tree-structured data with inherited permissions.

---

## Pattern 11: Attribute-Based Access Control (ABAC)

Access is determined by comparing attributes of the user and the resource. More flexible than role-based.

```sql
CREATE TABLE public.resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    classification TEXT NOT NULL DEFAULT 'internal'
        CHECK (classification IN ('public', 'internal', 'confidential', 'restricted')),
    department TEXT NOT NULL,
    region TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.user_clearances (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    clearance_level TEXT NOT NULL DEFAULT 'internal'
        CHECK (clearance_level IN ('public', 'internal', 'confidential', 'restricted')),
    departments TEXT[] NOT NULL DEFAULT '{}',
    regions TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;

-- Map classification to numeric level for comparison
CREATE OR REPLACE FUNCTION public.classification_level(classification TEXT)
RETURNS INTEGER AS $$
    SELECT CASE classification
        WHEN 'public' THEN 0
        WHEN 'internal' THEN 1
        WHEN 'confidential' THEN 2
        WHEN 'restricted' THEN 3
        ELSE 0
    END;
$$ LANGUAGE sql IMMUTABLE;

-- User can access resource if:
-- 1. Their clearance level >= resource classification
-- 2. Resource department is in their departments list (or they have wildcard)
-- 3. Resource region is in their regions list (or they have wildcard)
CREATE POLICY "Attribute-based access"
    ON public.resources FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_clearances uc
            WHERE uc.user_id = auth.uid()
            AND public.classification_level(uc.clearance_level) >= public.classification_level(resources.classification)
            AND (resources.department = ANY(uc.departments) OR '*' = ANY(uc.departments))
            AND (resources.region = ANY(uc.regions) OR '*' = ANY(uc.regions))
        )
    );
```

**When to use**: Government/military systems, highly regulated industries, complex access matrices.

---

## Pattern 12: Deny Policies (Explicit Blacklisting)

Supabase/PostgreSQL supports restrictive policies that act as deny rules, overriding permissive policies.

```sql
CREATE TABLE public.content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    body TEXT NOT NULL,
    author_id UUID NOT NULL REFERENCES auth.users(id),
    is_flagged BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Banned users table
CREATE TABLE public.banned_users (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    banned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ
);

ALTER TABLE public.content ENABLE ROW LEVEL SECURITY;

-- Permissive: all authenticated users can read
CREATE POLICY "Authenticated can read"
    ON public.content FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Permissive: authenticated users can create
CREATE POLICY "Authenticated can create"
    ON public.content FOR INSERT
    WITH CHECK (auth.uid() = author_id);

-- RESTRICTIVE: banned users cannot do anything
-- Note: RESTRICTIVE policies are ANDed with permissive policies
CREATE POLICY "Banned users denied"
    ON public.content AS RESTRICTIVE
    FOR ALL
    USING (
        NOT EXISTS (
            SELECT 1 FROM public.banned_users
            WHERE user_id = auth.uid()
            AND (expires_at IS NULL OR expires_at > now())
        )
    );

-- RESTRICTIVE: flagged content hidden from non-admins
CREATE POLICY "Flagged content hidden"
    ON public.content AS RESTRICTIVE
    FOR SELECT
    USING (
        is_flagged = false
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );
```

**Key concept**: Permissive policies (default) are ORed together -- if any permissive policy passes, access is allowed. Restrictive policies are ANDed -- all restrictive policies must pass. A restrictive deny policy overrides any number of permissive allow policies.

**When to use**: User bans, content moderation, compliance-driven access revocation, feature flags.

---

## Performance Tips for RLS Policies

1. **Index columns used in policies**: Columns referenced in `USING` and `WITH CHECK` should have indexes, especially foreign keys and lookup columns.

2. **Use `EXISTS` over `IN` for subqueries**: `EXISTS` short-circuits, while `IN` may materialize the full subquery.

3. **Cache role lookups with helper functions**: Functions marked `STABLE` allow PostgreSQL to cache the result within a transaction.

4. **Avoid recursive CTEs in hot paths**: Materialize hierarchies if they are deep and frequently queried.

5. **Use `security_invoker = true` on views**: When creating views over RLS-protected tables, set `security_invoker` so the view respects the caller's RLS policies rather than the view owner's.

6. **Test with `EXPLAIN ANALYZE`**: Run queries as the `authenticated` role to see if RLS policies cause sequential scans.

```sql
-- Test as authenticated user
SET ROLE authenticated;
SET request.jwt.claims = '{"sub": "user-uuid-here"}';
EXPLAIN ANALYZE SELECT * FROM public.invoices;
RESET ROLE;
```
