# Skills Development Brief for Claude Code

## Overview
Develop 5 custom skills for Claude. Each skill should follow the standard skill structure:
```
skill-name/
├── SKILL.md (required - YAML frontmatter + markdown instructions)
└── resources/ (optional - scripts, references, assets)
```

Priority order for development (can be parallelized):

---

## 1. `dax-optimizer`
**What it does:** Analyzes DAX code (Power BI measures, calculated columns, calculated tables), identifies anti-patterns, suggests optimizations, and generates improved versions.

**When to trigger:** User shares DAX code, mentions Power BI measures, asks about DAX performance, query optimization, or mentions slow reports/datasets.

**Key capabilities:**
- Detect common anti-patterns: unnecessary CALCULATE wrapping, FILTER vs direct filter, iterator vs aggregator misuse, excessive context transitions
- Suggest SUMMARIZECOLUMNS over ADDCOLUMNS+SUMMARIZE patterns
- Identify variable reuse opportunities (VAR/RETURN)
- Recommend proper use of KEEPFILTERS, REMOVEFILTERS, ALL variants
- Detect cardinality issues in relationships
- Format and restructure messy DAX for readability
- Explain the optimization rationale (why it's faster)
- Suggest proper time intelligence patterns (DATEADD vs SAMEPERIODLASTYEAR, etc.)

**Output format:** Optimized DAX code with inline comments explaining changes + a summary of what was improved and estimated performance impact.

**Reference material to include:**
- Common anti-patterns list with before/after examples
- SQLBI best practices (DAX patterns from sqlbi.com methodology)
- VertiPaq engine behavior notes (storage engine vs formula engine)

---

## 2. `api-scaffolder`
**What it does:** Given a database schema, PRD, or description of entities/endpoints, generates a complete backend API scaffold.

**When to trigger:** User wants to create a REST API, mentions endpoints, asks to scaffold a backend, shares a database schema or PRD and wants code generated, or mentions "generate API from schema."

**Key capabilities:**
- Input: Accept DB schema (SQL CREATE statements), JSON schema, PRD text, or entity descriptions
- Generate complete project structure for **FastAPI (Python)** or **Express (Node.js)**
- Output includes:
  - Project structure with proper folder organization
  - Models/schemas (Pydantic for FastAPI, Zod for Express)
  - CRUD route handlers for each entity
  - Authentication middleware (JWT-based)
  - Input validation
  - Error handling middleware
  - Database connection setup (SQLAlchemy/Prisma)
  - OpenAPI/Swagger documentation config
  - Docker setup (Dockerfile + docker-compose.yml)
  - Basic test files structure
  - .env.example with required variables
- Support relationship handling (1:N, N:N with junction tables)
- Generate proper HTTP status codes and error responses

**Output format:** Complete project files ready to run.

**User context:** Brian's Vitae project has 22 tables and 72 endpoints — this skill should handle that scale efficiently.

---

## 3. `supabase-fullstack`
**What it does:** Generates complete Supabase-powered fullstack applications with proper security, schemas, and connected frontend.

**When to trigger:** User mentions Supabase, wants to create a project with Supabase backend, asks about RLS policies, Supabase Edge Functions, or wants to generate a fullstack app with Supabase.

**Key capabilities:**
- Generate SQL migrations with:
  - Tables with proper types, constraints, indexes
  - Row Level Security (RLS) policies per table/role
  - Triggers and functions (updated_at, soft delete, etc.)
  - Storage bucket policies
- Generate Supabase Edge Functions (Deno/TypeScript)
- Generate frontend integration code:
  - Supabase client setup
  - Auth flows (email/password, magic link, OAuth)
  - Real-time subscriptions setup
  - Type-safe queries using generated types
- Generate TypeScript types from schema
- Include common patterns:
  - Multi-tenant data isolation
  - Soft delete with RLS
  - Audit logging via triggers
  - File upload with Storage
- Security checklist and RLS verification

**Output format:** SQL migration files + Edge Function files + Frontend integration code + setup instructions.

---

## 4. `database-designer`
**What it does:** Designs database schemas visually (Mermaid ERD diagrams) and generates migration SQL from descriptions or existing schemas.

**When to trigger:** User wants to design a database, create an ERD diagram, model data relationships, normalize a schema, or generate migrations from a description of their data model.

**Key capabilities:**
- Convert natural language descriptions into normalized schemas
- Generate Mermaid ERD diagrams (renderable in artifacts)
- Support multiple SQL dialects: PostgreSQL, MySQL, SQLite
- Apply normalization rules (1NF through 3NF, with explanation)
- Detect and suggest:
  - Missing indexes for common query patterns
  - Proper foreign key relationships and cascade rules
  - Enum types vs lookup tables decisions
  - Timestamp fields (created_at, updated_at, deleted_at)
  - UUID vs serial primary keys tradeoffs
- Generate migration files (up/down) compatible with:
  - Raw SQL
  - Prisma schema
  - SQLAlchemy/Alembic
  - Supabase migrations
- Reverse engineer: take existing SQL and produce ERD + optimization suggestions
- Handle evolution: given current schema + desired changes, generate ALTER migration

**Output format:** Mermaid ERD diagram (as .mermaid or in .html artifact) + SQL migration files + schema documentation.

---

## 5. `email-template`
**What it does:** Creates responsive HTML email templates that work across all major email clients (Gmail, Outlook, Apple Mail, Yahoo).

**When to trigger:** User wants to create an HTML email, email template, newsletter, transactional email, or mentions email design/layout challenges.

**Key capabilities:**
- Generate table-based layouts (email client compatibility)
- Support responsive design with media queries + fluid tables fallback
- Include proper email-specific CSS resets
- Handle dark mode compatibility (prefers-color-scheme + Outlook dark mode hacks)
- Common template types:
  - Transactional (welcome, password reset, order confirmation, invoice)
  - Marketing (newsletter, announcement, product launch)
  - Notification (alert, reminder, digest)
- Include:
  - Inline CSS (no external stylesheets)
  - MSO conditionals for Outlook
  - Preheader text
  - Unsubscribe link placeholder
  - Alt text for all images
  - Proper DOCTYPE and meta tags
- Generate both HTML and plain-text versions
- Configurable: brand colors, logo URL, font choices (web-safe fallbacks)
- Preview-friendly: output should render correctly when opened in a browser

**Output format:** Complete .html file ready for ESP (Email Service Provider) import + plain text version.

**Reference material to include:**
- Email client CSS support matrix (key limitations)
- Outlook-specific hacks reference
- Dark mode compatibility patterns

---

## Output Strategy

**Repository:** Create a GitHub repo called `brian-custom-skills` with this structure:
```
brian-custom-skills/
├── README.md
├── skills/
│   ├── dax-optimizer/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── api-scaffolder/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── supabase-fullstack/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── database-designer/
│   │   ├── SKILL.md
│   │   └── references/
│   └── email-template/
│       ├── SKILL.md
│       └── references/
├── packaged/          ← .skill files ready to upload to Claude.ai
│   ├── dax-optimizer.skill
│   ├── api-scaffolder.skill
│   ├── supabase-fullstack.skill
│   ├── database-designer.skill
│   └── email-template.skill
└── evals/             ← test prompts and results per skill
```

**Workflow:**
1. Develop each skill in `skills/<name>/`
2. Test and iterate
3. Package with `package_skill.py` → output to `packaged/`
4. User uploads `.skill` files to Claude.ai

---

## Development Notes

### For each skill:
1. Create the skill folder under `/mnt/skills/user/` (or wherever user skills go)
2. Write SKILL.md with proper YAML frontmatter (name, description)
3. Make description "pushy" — include all trigger keywords and contexts
4. Include reference files for complex domains (DAX patterns, email client quirks)
5. Add practical examples in the SKILL.md body
6. Test with realistic prompts

### Parallelization suggestion:
Skills 1 (dax-optimizer) and 5 (email-template) are independent domains — develop simultaneously.
Skills 2 (api-scaffolder), 3 (supabase-fullstack), and 4 (database-designer) share concepts — develop 4 first, then 2 and 3 can reference it.

### Quality bar:
- Each skill should produce output that's **production-ready**, not boilerplate
- Include edge cases and real-world patterns, not just happy paths
- DAX skill should reflect SQLBI-level best practices
- Email skill should actually render in Outlook (the hardest client)
