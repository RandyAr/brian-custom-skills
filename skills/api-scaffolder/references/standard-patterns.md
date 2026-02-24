# Standard Patterns

Common API patterns covering pagination, filtering, sorting, error handling, authentication, authorization, validation, logging, rate limiting, CORS, relationship handling, and scale considerations.

---

## Pagination

Support both offset-based and page-based pagination via query parameters:

```
GET /users?page=2&per_page=20
GET /users?offset=40&limit=20
```

Response envelope:
```json
{
  "items": [...],
  "total": 156,
  "page": 2,
  "per_page": 20,
  "pages": 8
}
```

## Filtering

Map query parameters to WHERE clauses:

```
GET /posts?status=published&author_id=abc-123
GET /users?is_active=true&role=admin
```

For date ranges:
```
GET /posts?created_after=2024-01-01&created_before=2024-12-31
```

## Sorting

```
GET /users?sort_by=created_at&order=desc
GET /posts?sort_by=title&order=asc
```

Validate that `sort_by` maps to an actual column. Reject unknown fields with 422.

## Error Response Format

All errors follow this consistent structure:

```json
{
  "status": "error",
  "message": "Human-readable description of what went wrong",
  "details": {
    "errors": [
      { "field": "email", "message": "Invalid email address" }
    ]
  }
}
```

## JWT Auth Flow

1. **Register** — Hash password (bcrypt, 12 rounds), store user, return user response (no token).
2. **Login** — Verify credentials, return `{ access_token, refresh_token, token_type: "bearer" }`.
3. **Refresh** — Accept refresh token, verify, issue new access token.
4. **Access token** — Short-lived (30 minutes), contains `{ sub: user_id, role: user_role }`.
5. **Refresh token** — Long-lived (7 days), stored in DB or signed JWT.

## Role-Based Access Control

Define roles in the user model (`admin`, `editor`, `viewer`, or custom). Apply middleware:

- **Public routes**: No auth required (health check, login, register).
- **Authenticated routes**: Valid token required (list, get, update own profile).
- **Admin routes**: Specific role required (create users, delete, manage settings).

## Request Validation

- **FastAPI**: Pydantic models with `Field` constraints (min_length, max_length, regex, ge, le).
- **Express**: Zod schemas parsed in validation middleware. Return 422 with field-level errors.

Always validate:
- Request body on POST, PUT, PATCH.
- Query parameters on GET (pagination bounds, sort field whitelist).
- Path parameters (UUID format).

## HTTP Status Codes

Use precise status codes — see the `references/http-status-codes.md` reference for the complete guide.

Key conventions:
- **201 Created** for successful POST (not 200).
- **204 No Content** for successful DELETE (empty body).
- **409 Conflict** for unique constraint violations (duplicate email).
- **422 Unprocessable Entity** for validation failures (not 400).
- **400 Bad Request** only for malformed requests (invalid JSON syntax).

## Logging Middleware

Log every request with:
- Timestamp, method, path, status code, response time (ms).
- Request ID (UUID) for tracing.
- Sanitize sensitive fields (password, tokens) from logs.

## Rate Limiting

- Default: 100 requests per minute per IP.
- Auth endpoints: 10 requests per minute per IP (brute force protection).
- Configurable via environment variables.

## CORS Configuration

- Development: Allow `http://localhost:3000` (or configurable origins).
- Production: Restrict to specific domains via `CORS_ORIGINS` env var.
- Allow credentials for cookie-based auth flows.

---

## Relationship Handling

### One-to-Many (1:N)

- FK column on the child table (`author_id` on `posts`).
- Parent route gets nested endpoint: `GET /users/:id/posts`.
- Child response can optionally include parent via `?include=author` query param.
- When creating child, accept parent ID in the request body.

### Many-to-Many (N:N)

- Junction table (e.g., `posts_tags`) with composite PK.
- Endpoints:
  - `GET /posts/:id/tags` — list attached tags.
  - `POST /posts/:id/tags` — attach tags (`{ "tag_ids": ["uuid-1", "uuid-2"] }`).
  - `DELETE /posts/:id/tags/:tagId` — detach a single tag.
- Support bulk attach/detach in a single request.

### Circular Dependencies

When entities reference each other (e.g., `User` has `manager_id` referencing `User`):
- Use `Optional` / nullable for the self-referencing FK.
- In Pydantic: use `model_rebuild()` or `from __future__ import annotations` for forward references.
- In Prisma: Prisma handles self-relations natively with `@relation`.
- Limit serialization depth to prevent infinite recursion (max 2 levels).

### Include/Expand Pattern

Support `?include=relation1,relation2` query parameter to control eager loading:

```
GET /posts?include=author,tags
GET /users/123?include=posts
```

- FastAPI: Use `selectinload` or `joinedload` in SQLAlchemy query based on include param.
- Express: Use Prisma `include` option dynamically.
- Validate include values against a whitelist of allowed relations per entity.

---

## Scale Considerations

This skill is designed to handle large schemas efficiently. For context, Brian's Vitae project requires 22 tables and 72 endpoints.

Principles for large projects:
- **One route file per entity** — never combine multiple entities into a single routes file.
- **One service file per entity** — isolate business logic to prevent monolithic service files.
- **One model file per entity** — keep ORM definitions separate and importable.
- **One schema file per entity** — separate validation from ORM models.
- **Shared utilities** — pagination, filtering, and sorting logic should be reusable helpers, not duplicated across services.
- **Route registration** — use a loop or dynamic import to register all entity routers in `main.py` / `index.ts` to avoid a growing list of manual imports.
- **Consistent naming** — file names match entity names (singular): `user.py`, `post.py`, `tag.py`.
- **Batch generation** — when given many entities, generate all files systematically rather than one entity at a time.
