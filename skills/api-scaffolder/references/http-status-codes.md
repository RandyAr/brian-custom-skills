# HTTP Status Codes — REST API Quick Reference

When generating API scaffolds, use the precise HTTP status code for each situation. This reference covers every status code commonly needed in REST APIs, with the exact scenarios where each applies.

---

## 2xx — Success

### 200 OK

The request succeeded and the response body contains the requested resource or result.

**Use when:**
- Returning a single resource: `GET /users/123`
- Returning a list of resources: `GET /users`
- Returning the updated resource after `PUT` or `PATCH`
- Successful login returning tokens: `POST /auth/login`
- Successful token refresh: `POST /auth/refresh`
- Any successful operation that returns data in the body

**Do NOT use when:**
- A new resource was created (use 201).
- The operation succeeded but there is no body to return (use 204).

### 201 Created

A new resource was successfully created.

**Use when:**
- `POST /users` creates a new user.
- `POST /auth/register` creates a new account.
- `POST /posts` creates a new post.
- Any `POST` that results in a new persistent resource.

**Response requirements:**
- Body should contain the created resource (with its server-generated `id`, `created_at`, etc.).
- Optionally include a `Location` header pointing to the new resource: `Location: /api/v1/users/abc-123`.

**Example:**
```json
// POST /users → 201 Created
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "alice@example.com",
  "firstName": "Alice",
  "lastName": "Smith",
  "role": "user",
  "createdAt": "2024-06-15T10:30:00Z",
  "updatedAt": "2024-06-15T10:30:00Z"
}
```

### 204 No Content

The request succeeded but there is no content to return.

**Use when:**
- `DELETE /users/123` successfully soft-deletes a user.
- Any operation where the client does not need a response body.
- Bulk operations where returning every affected resource is impractical.

**Response requirements:**
- The response body MUST be empty.
- Do NOT return `{ "message": "Deleted successfully" }` — that should be a 200.

---

## 3xx — Redirection

### 301 Moved Permanently

The resource has been permanently moved to a new URL.

**Use when:**
- An API version is deprecated and the endpoint has been permanently relocated.
- Example: `GET /api/v1/users` redirects to `GET /api/v2/users`.
- Rarely used in APIs; more common in web applications.

### 304 Not Modified

The resource has not changed since the last request (used with conditional requests).

**Use when:**
- The client sends `If-None-Match` (ETag) or `If-Modified-Since` headers.
- The resource has not changed — the client can use its cached version.
- Reduces bandwidth for frequently polled resources.

**Note:** Most REST API scaffolds do not implement conditional caching by default. Include this only when the user specifically requests caching support.

---

## 4xx — Client Errors

### 400 Bad Request

The request is syntactically malformed and cannot be parsed.

**Use when:**
- The request body is not valid JSON (malformed syntax).
- Required headers are missing (e.g., `Content-Type`).
- The request cannot be understood at all.

**Do NOT use when:**
- The JSON is valid but fails validation rules (use 422).
- A field has an invalid value like a bad email format (use 422).

**Example:**
```json
// Malformed JSON in request body → 400
{
  "status": "error",
  "message": "Invalid JSON in request body",
  "details": null
}
```

### 401 Unauthorized

Authentication is missing or invalid. The client must authenticate to access this resource.

**Use when:**
- No `Authorization` header is provided on a protected endpoint.
- The JWT token is expired.
- The JWT token has an invalid signature.
- The JWT token references a user that no longer exists.
- Login attempt with wrong password: `POST /auth/login` with invalid credentials.
- Refresh token is expired or revoked.

**Response requirements:**
- Include `WWW-Authenticate: Bearer` header.
- Do NOT reveal whether it was the username or password that was wrong (prevent enumeration).

**Example:**
```json
// Expired token → 401
{
  "status": "error",
  "message": "Invalid or expired token",
  "details": null
}
```

### 403 Forbidden

The client is authenticated but does not have permission to perform this action.

**Use when:**
- A `user` role tries to access an `admin`-only endpoint.
- A user tries to modify another user's resource (ownership check fails).
- A user tries to access a resource outside their tenant/organization.
- The account is deactivated (`is_active = false`).

**Key distinction from 401:**
- 401 = "Who are you?" (authentication problem).
- 403 = "I know who you are, but you are not allowed." (authorization problem).

**Example:**
```json
// Non-admin tries to delete a user → 403
{
  "status": "error",
  "message": "Requires one of roles: admin",
  "details": null
}
```

### 404 Not Found

The requested resource does not exist or has been soft-deleted.

**Use when:**
- `GET /users/nonexistent-id` — the ID does not match any record.
- `GET /users/deleted-user-id` — the record exists but `deleted_at` is set (treat as not found).
- `PUT /users/nonexistent-id` — trying to update a resource that does not exist.
- `DELETE /users/nonexistent-id` — trying to delete a resource that does not exist.
- The route itself does not exist (framework default).

**Security note:** Do NOT return 404 for resources the user is not authorized to see. Return 403 instead (or 404 if you want to hide the resource's existence — choose one approach consistently).

**Example:**
```json
// GET /users/nonexistent-uuid → 404
{
  "status": "error",
  "message": "User not found",
  "details": null
}
```

### 405 Method Not Allowed

The HTTP method is not supported for this endpoint.

**Use when:**
- `DELETE /auth/login` — the endpoint only accepts `POST`.
- Generally handled automatically by the framework's router.

**Response requirements:**
- Include `Allow` header listing valid methods: `Allow: GET, POST`.

### 409 Conflict

The request conflicts with the current state of a resource.

**Use when:**
- `POST /users` with an email that already exists (unique constraint violation).
- `POST /auth/register` with a duplicate email.
- Trying to create a resource that violates a unique constraint.
- Optimistic concurrency conflict (version mismatch on update).
- Trying to transition a resource to an invalid state (e.g., publishing an already-archived post).

**Example:**
```json
// POST /users with duplicate email → 409
{
  "status": "error",
  "message": "Email already registered",
  "details": {
    "field": "email",
    "value": "alice@example.com"
  }
}
```

### 422 Unprocessable Entity

The request body is syntactically valid JSON but fails semantic validation rules.

**Use when:**
- A required field is missing from the request body.
- A field value fails validation: email format, string length, numeric range.
- An enum field has an invalid value.
- A referenced foreign key ID does not exist.
- Business rule validation fails (e.g., end_date must be after start_date).

**This is the correct code for validation errors, not 400.**

**Example:**
```json
// POST /users with invalid data → 422
{
  "status": "error",
  "message": "Validation failed",
  "details": {
    "errors": [
      { "field": "email", "message": "Invalid email address" },
      { "field": "password", "message": "Password must be at least 8 characters" }
    ]
  }
}
```

### 429 Too Many Requests

The client has exceeded the rate limit.

**Use when:**
- The IP or user has sent too many requests in the configured window.
- Particularly important on auth endpoints (brute force protection).

**Response requirements:**
- Include `Retry-After` header with seconds until the limit resets.
- Optionally include `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` headers.

**Example:**
```json
// Too many login attempts → 429
{
  "status": "error",
  "message": "Rate limit exceeded. Try again in 45 seconds.",
  "details": {
    "retryAfter": 45
  }
}
```

---

## 5xx — Server Errors

### 500 Internal Server Error

An unexpected error occurred on the server.

**Use when:**
- An unhandled exception reaches the global error handler.
- A database query fails due to a server-side issue (not a constraint violation).
- An external service call fails unexpectedly.
- Any bug or unanticipated condition.

**CRITICAL:** Never expose internal error details (stack traces, SQL queries, file paths) in the response body. Log them server-side; return a generic message to the client.

**Example:**
```json
// Unhandled exception → 500
{
  "status": "error",
  "message": "An unexpected error occurred.",
  "details": null
}
```

### 502 Bad Gateway

The server received an invalid response from an upstream service.

**Use when:**
- A reverse proxy (Nginx, AWS ALB) cannot reach the application server.
- Typically not generated by your application code directly.

### 503 Service Unavailable

The server is temporarily unable to handle the request.

**Use when:**
- The database connection is down (health check endpoint).
- The application is starting up or shutting down.
- The server is in maintenance mode.
- A critical dependency (Redis, external API) is unreachable.

**Response requirements:**
- Include `Retry-After` header if the downtime duration is known.

**Example:**
```json
// Health check with dead DB → 503
{
  "status": "error",
  "message": "Service unavailable: database connection failed",
  "details": {
    "database": "unreachable",
    "redis": "ok"
  }
}
```

---

## Quick Decision Matrix

Use this matrix to pick the right status code quickly:

| Scenario | Status Code |
|----------|-------------|
| Successful GET returning data | 200 |
| Successful PUT/PATCH returning updated resource | 200 |
| Successful login returning tokens | 200 |
| Successful POST creating a new resource | 201 |
| Successful DELETE (no body returned) | 204 |
| Invalid JSON syntax in request body | 400 |
| No auth token provided | 401 |
| Expired or invalid auth token | 401 |
| Wrong login credentials | 401 |
| Authenticated user lacks required role | 403 |
| User tries to access another user's data | 403 |
| Resource does not exist | 404 |
| Soft-deleted resource (treated as not found) | 404 |
| HTTP method not supported on endpoint | 405 |
| Unique constraint violation (duplicate email) | 409 |
| Request body fails validation rules | 422 |
| Missing required field in request body | 422 |
| Invalid field format (bad email, too short) | 422 |
| Rate limit exceeded | 429 |
| Unhandled server exception | 500 |
| Database is unreachable (health check) | 503 |

---

## Status Code Ranges — Summary

| Range | Category | Who is at fault? |
|-------|----------|-----------------|
| 2xx | Success | Nobody — everything worked |
| 3xx | Redirection | Nobody — resource moved |
| 4xx | Client Error | The client sent a bad request |
| 5xx | Server Error | The server failed to process a valid request |
