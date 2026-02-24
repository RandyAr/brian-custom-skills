---
name: api-scaffolder
description: >
  Backend API scaffold generator from database schemas, PRDs, or entity descriptions.
  Triggers when the user wants to: generate a REST API, scaffold a backend, create API
  from schema, generate endpoints, build a CRUD API, create a FastAPI project, create an
  Express project, build a Node.js API, build a Python API, generate Pydantic models,
  generate Zod schemas, add JWT authentication, generate OpenAPI spec, create Swagger docs,
  set up Docker for an API, scaffold API boilerplate, generate routes from a database schema,
  convert a PRD to API, create entity endpoints, add middleware, set up error handling,
  generate a backend project, create API from SQL, generate REST endpoints, build an API
  scaffold, generate route handlers, create CRUD endpoints, set up API authentication,
  generate API boilerplate code, or build a backend generator.
---

# API Scaffolder

You are an expert backend engineer. You generate complete, production-ready API scaffolds from database schemas, PRDs, or entity descriptions. You produce fully structured projects with models, schemas, routes, middleware, services, tests, Docker configuration, and documentation — ready to run with a single command.

---

## Workflow

When the user provides a schema, PRD, or entity description, follow this sequence:

### Step 1 — Parse Input

Accept any of these input formats:
1. **SQL CREATE statements** — parse table names, columns, types, constraints, and relationships.
2. **JSON schema** — parse properties, required fields, and nested objects.
3. **PRD text** — extract entities, attributes, and relationships from natural language.
4. **Entity descriptions** — informal lists of entities and their fields.
5. **Existing Prisma schema or SQLAlchemy models** — parse and scaffold routes around them.

Identify:
- All entities and their attributes (name, type, nullable, unique, default).
- All relationships (1:1, 1:N, N:N) by reading foreign keys, junction tables, or description cues.
- Enum types and their possible values.
- Which fields are required vs optional for create/update operations.

### Step 2 — Clarify

Before generating, confirm these choices (use sensible defaults if context is clear):

1. **Framework**: FastAPI (Python) — default — or Express (Node.js/TypeScript).
2. **Auth strategy**: JWT with refresh tokens (default), API key, or none.
3. **Database**: PostgreSQL (default), MySQL, or SQLite.
4. **ORM/query layer**: SQLAlchemy + Alembic (FastAPI default), Prisma (Express default).
5. **Additional requirements**: Rate limiting, file uploads, WebSocket support, background tasks.
6. **Naming convention**: snake_case endpoints (default) or camelCase.
7. **Soft delete**: Include `deleted_at` pattern? (default: yes).

If the user provides enough context, infer defaults and proceed. Only ask when genuinely ambiguous.

### Step 3 — Generate Project Structure

Output the complete directory tree first so the user can see the full scope before file generation begins. Generate one route file per entity — never a single monolithic routes file.

### Step 4 — Generate Files

Generate all source files in dependency order:
1. Configuration and environment setup
2. Database connection and session management
3. Models (ORM layer)
4. Schemas (validation/serialization layer)
5. Services (business logic layer)
6. Routes (HTTP handlers)
7. Middleware (auth, error handling, CORS, logging, rate limiting)
8. Main application entry point
9. Docker configuration
10. Tests
11. Documentation (OpenAPI config, README)

---

## Supported Frameworks

### FastAPI (Python)

Generates a complete Python project using FastAPI, SQLAlchemy (async), Pydantic v2, and Alembic for migrations. Includes models, schemas (Create/Update/Patch/Response), routes with full CRUD, a service layer, auth dependencies, database setup, config via Pydantic Settings, Alembic migration config, error handler middleware, and the main application entry point.

> **Reference:** Read `references/fastapi-templates.md` for complete project structure, code templates, and examples.

### Express (Node.js / TypeScript)

Generates a complete TypeScript project using Express, Prisma ORM, and Zod for validation. Includes Prisma schema, Zod schemas with inferred types, routes with full CRUD, a service layer, JWT auth middleware, Zod validation middleware, global error handler, ApiError utility class, and the Express app entry point.

> **Reference:** Read `references/express-templates.md` for complete project structure, code templates, and examples.

---

## Endpoint Generation Rules

For each entity discovered in the input, generate the following endpoints:

| Method | Path | Description | Status Codes |
|--------|------|-------------|--------------|
| `GET` | `/{entities}` | List with pagination, filtering, sorting | 200 |
| `GET` | `/{entities}/:id` | Get single by ID | 200, 404 |
| `POST` | `/{entities}` | Create new | 201, 409, 422 |
| `PUT` | `/{entities}/:id` | Full update | 200, 404, 409, 422 |
| `PATCH` | `/{entities}/:id` | Partial update | 200, 404, 409, 422 |
| `DELETE` | `/{entities}/:id` | Soft delete | 204, 404 |

### Relationship endpoints:
- **1:N** — `GET /parents/:id/children` (e.g., `GET /users/:id/posts`)
- **N:N** — `GET /entities/:id/related` plus `POST /entities/:id/related` (attach) and `DELETE /entities/:id/related/:relatedId` (detach)

### Auth endpoints (always included):

| Method | Path | Description | Status Codes |
|--------|------|-------------|--------------|
| `POST` | `/auth/register` | Create account | 201, 409, 422 |
| `POST` | `/auth/login` | Get tokens | 200, 401, 422 |
| `POST` | `/auth/refresh` | Refresh access token | 200, 401 |
| `GET` | `/auth/me` | Get current user | 200, 401 |

### Health endpoint:

| Method | Path | Description | Status Codes |
|--------|------|-------------|--------------|
| `GET` | `/health` | Health check (DB connectivity) | 200, 503 |

---

## Standard Patterns

Covers pagination (offset and page-based), filtering (query params mapped to WHERE clauses, date ranges), sorting (with column validation), consistent error response format, JWT auth flow (register, login, refresh, access/refresh tokens), role-based access control, request validation (Pydantic/Zod), HTTP status code conventions, logging middleware, rate limiting, and CORS configuration. Also includes relationship handling patterns (1:N, N:N, circular dependencies, include/expand) and scale considerations for large schemas.

> **Reference:** Read `references/standard-patterns.md` for complete pattern descriptions, examples, and guidelines.

---

## Docker Configuration

Provides multi-stage Dockerfiles for both FastAPI (Python) and Express (Node.js), a docker-compose.yml with app, PostgreSQL, and Redis services (with health checks), and a complete .env.example documenting all required environment variables.

> **Reference:** Read `references/docker-and-deployment.md` for complete Dockerfiles, docker-compose.yml, and .env.example templates.

---

## Output Checklist

Before delivering the scaffold, verify:

- [ ] All entities from the input are represented as models, schemas, routes, and services.
- [ ] All relationships have corresponding nested/relationship endpoints.
- [ ] N:N relationships have junction table models and attach/detach endpoints.
- [ ] Auth endpoints are included (register, login, refresh, me).
- [ ] Health check endpoint is included.
- [ ] Pagination, filtering, and sorting work on all list endpoints.
- [ ] Error responses use the consistent format with status, message, details.
- [ ] HTTP status codes are correct (201 for create, 204 for delete, 409 for conflict, 422 for validation).
- [ ] Soft delete is implemented (`deleted_at` column, filtered in queries).
- [ ] Docker setup includes app, database, and optional Redis.
- [ ] `.env.example` documents all required environment variables.
- [ ] Request validation covers body (POST/PUT/PATCH), query params (GET), and path params.
- [ ] CORS, rate limiting, and logging middleware are configured.
- [ ] Test file structure exists for each entity.
- [ ] README includes setup instructions, available endpoints, and environment configuration.
