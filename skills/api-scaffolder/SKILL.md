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

#### Project Structure

```
project-name/
├── app/
│   ├── __init__.py
│   ├── main.py                  # FastAPI app, startup/shutdown, middleware registration
│   ├── config.py                # Pydantic Settings (env vars, secrets)
│   ├── database.py              # SQLAlchemy engine, session factory, Base
│   ├── dependencies.py          # Shared dependencies (get_db, get_current_user)
│   ├── models/                  # SQLAlchemy ORM models
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── {entity}.py
│   ├── schemas/                 # Pydantic schemas (Create, Update, Response)
│   │   ├── __init__.py
│   │   ├── common.py            # Pagination, error response, health check
│   │   ├── auth.py              # Login, register, token schemas
│   │   ├── user.py
│   │   └── {entity}.py
│   ├── routes/                  # One file per entity
│   │   ├── __init__.py
│   │   ├── auth.py              # Register, login, refresh, me
│   │   ├── health.py            # Health check endpoint
│   │   ├── user.py
│   │   └── {entity}.py
│   ├── services/                # Business logic layer
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── user.py
│   │   └── {entity}.py
│   ├── middleware/
│   │   ├── __init__.py
│   │   ├── error_handler.py     # Global exception handlers
│   │   ├── logging.py           # Request/response logging
│   │   └── rate_limiter.py      # Rate limiting (slowapi)
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── security.py          # Password hashing, JWT encode/decode
│   │   ├── pagination.py        # Pagination helper
│   │   └── filters.py           # Dynamic query filtering
│   └── tests/
│       ├── __init__.py
│       ├── conftest.py           # Fixtures: test client, test DB, auth headers
│       ├── test_auth.py
│       ├── test_health.py
│       └── test_{entity}.py
├── alembic/                     # Database migrations
│   ├── env.py
│   ├── script.py.mako
│   └── versions/
├── alembic.ini
├── requirements.txt
├── requirements-dev.txt
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── .gitignore
├── pyproject.toml
└── README.md
```

#### Model Example (SQLAlchemy)

```python
# app/models/user.py
import uuid
from datetime import datetime

from sqlalchemy import Column, String, Boolean, DateTime, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, server_default=text("gen_random_uuid()"))
    email = Column(String(255), nullable=False, unique=True, index=True)
    password_hash = Column(String(255), nullable=False)
    first_name = Column(String(100))
    last_name = Column(String(100))
    is_active = Column(Boolean, nullable=False, server_default=text("true"))
    role = Column(String(50), nullable=False, server_default=text("'user'"))

    created_at = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"), onupdate=datetime.utcnow)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    posts = relationship("Post", back_populates="author", lazy="selectin")

    @property
    def full_name(self) -> str:
        return f"{self.first_name or ''} {self.last_name or ''}".strip()
```

#### Schema Example (Pydantic)

```python
# app/schemas/user.py
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, ConfigDict


# --- Base ---
class UserBase(BaseModel):
    email: EmailStr
    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)


# --- Create ---
class UserCreate(UserBase):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)


# --- Update (full) ---
class UserUpdate(UserBase):
    email: EmailStr
    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)


# --- Patch (partial) ---
class UserPatch(BaseModel):
    email: Optional[EmailStr] = None
    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)


# --- Response ---
class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    is_active: bool
    role: str
    created_at: datetime
    updated_at: datetime


# --- List response (with pagination) ---
class UserListResponse(BaseModel):
    items: list[UserResponse]
    total: int
    page: int
    per_page: int
    pages: int
```

#### Route Example (CRUD with Pagination, Filtering, Sorting)

```python
# app/routes/user.py
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import asc, desc, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db, get_current_user, require_role
from app.models.user import User
from app.schemas.user import (
    UserCreate, UserUpdate, UserPatch, UserResponse, UserListResponse,
)
from app.services.user import UserService

router = APIRouter(prefix="/users", tags=["users"])


@router.get("", response_model=UserListResponse)
async def list_users(
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(20, ge=1, le=100, description="Items per page"),
    sort_by: str = Query("created_at", description="Field to sort by"),
    order: str = Query("desc", regex="^(asc|desc)$", description="Sort order"),
    search: Optional[str] = Query(None, description="Search by name or email"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List users with pagination, filtering, and sorting."""
    service = UserService(db)
    filters = {}
    if is_active is not None:
        filters["is_active"] = is_active
    return await service.list(
        page=page, per_page=per_page,
        sort_by=sort_by, order=order,
        search=search, filters=filters,
    )


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a single user by ID."""
    service = UserService(db)
    user = await service.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user


@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    data: UserCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_role("admin")),
):
    """Create a new user. Requires admin role."""
    service = UserService(db)
    existing = await service.get_by_email(data.email)
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")
    return await service.create(data)


@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: UUID,
    data: UserUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Full update of a user."""
    service = UserService(db)
    user = await service.update(user_id, data)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user


@router.patch("/{user_id}", response_model=UserResponse)
async def patch_user(
    user_id: UUID,
    data: UserPatch,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Partial update of a user."""
    service = UserService(db)
    user = await service.patch(user_id, data)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_role("admin")),
):
    """Soft delete a user. Requires admin role."""
    service = UserService(db)
    success = await service.soft_delete(user_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return None


# --- Relationship endpoint ---
@router.get("/{user_id}/posts", response_model=PostListResponse)
async def list_user_posts(
    user_id: UUID,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all posts by a specific user."""
    service = UserService(db)
    user = await service.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return await service.list_posts(user_id, page=page, per_page=per_page)
```

#### Auth Middleware

```python
# app/dependencies.py
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_async_session
from app.models.user import User
from app.utils.security import decode_access_token

security_scheme = HTTPBearer()


async def get_db() -> AsyncSession:
    async with get_async_session() as session:
        yield session


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    token = credentials.credentials
    payload = decode_access_token(token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user_id = payload.get("sub")
    user = await db.get(User, user_id)
    if user is None or user.deleted_at is not None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or deactivated",
        )
    return user


def require_role(*roles: str):
    """Dependency factory for role-based access control."""
    async def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Requires one of roles: {', '.join(roles)}",
            )
        return current_user
    return role_checker


async def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(HTTPBearer(auto_error=False)),
    db: AsyncSession = Depends(get_db),
) -> Optional[User]:
    """Returns the user if a valid token is present, None otherwise."""
    if credentials is None:
        return None
    payload = decode_access_token(credentials.credentials)
    if payload is None:
        return None
    user_id = payload.get("sub")
    return await db.get(User, user_id)
```

#### Database Setup (Async SQLAlchemy)

```python
# app/database.py
from contextlib import asynccontextmanager

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import declarative_base

from app.config import settings

engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,
    pool_size=settings.db_pool_size,
    max_overflow=settings.db_max_overflow,
    pool_pre_ping=True,
)

AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

Base = declarative_base()


@asynccontextmanager
async def get_async_session():
    session = AsyncSessionLocal()
    try:
        yield session
        await session.commit()
    except Exception:
        await session.rollback()
        raise
    finally:
        await session.close()
```

#### Config (Pydantic Settings)

```python
# app/config.py
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # App
    app_name: str = "My API"
    debug: bool = False
    api_prefix: str = "/api/v1"

    # Database
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/mydb"
    db_pool_size: int = 10
    db_max_overflow: int = 20

    # Auth
    secret_key: str = "change-me-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7

    # CORS
    cors_origins: list[str] = ["http://localhost:3000"]

    # Rate Limiting
    rate_limit: str = "100/minute"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
```

#### Alembic Configuration

```python
# alembic/env.py
import asyncio
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.ext.asyncio import async_engine_from_config
from alembic import context

from app.config import settings
from app.database import Base
# Import all models so Alembic detects them
from app.models import user  # noqa: F401
# from app.models import post  # noqa: F401  — add each model here

config = context.config
config.set_main_option("sqlalchemy.url", settings.database_url.replace("+asyncpg", ""))

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(url=url, target_metadata=target_metadata, literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection):
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


async def run_migrations_online() -> None:
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    asyncio.run(run_migrations_online())
```

#### Main Application Entry Point

```python
# app/main.py
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.middleware.error_handler import register_error_handlers
from app.middleware.logging import LoggingMiddleware
from app.routes import auth, health, user  # import all route modules


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    yield
    # Shutdown


app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    docs_url=f"{settings.api_prefix}/docs",
    redoc_url=f"{settings.api_prefix}/redoc",
    openapi_url=f"{settings.api_prefix}/openapi.json",
    lifespan=lifespan,
)

# Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(LoggingMiddleware)
register_error_handlers(app)

# Routes
app.include_router(health.router, prefix=settings.api_prefix)
app.include_router(auth.router, prefix=settings.api_prefix)
app.include_router(user.router, prefix=settings.api_prefix)
# app.include_router({entity}.router, prefix=settings.api_prefix)
```

#### Service Layer Example

```python
# app/services/user.py
import math
from typing import Optional
from uuid import UUID

from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate, UserPatch, UserListResponse
from app.utils.security import hash_password


class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, user_id: UUID) -> Optional[User]:
        result = await self.db.execute(
            select(User).where(User.id == user_id, User.deleted_at.is_(None))
        )
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> Optional[User]:
        result = await self.db.execute(
            select(User).where(User.email == email, User.deleted_at.is_(None))
        )
        return result.scalar_one_or_none()

    async def list(
        self, page: int, per_page: int,
        sort_by: str, order: str,
        search: Optional[str] = None,
        filters: Optional[dict] = None,
    ) -> UserListResponse:
        query = select(User).where(User.deleted_at.is_(None))

        # Apply search
        if search:
            search_term = f"%{search}%"
            query = query.where(
                or_(
                    User.email.ilike(search_term),
                    User.first_name.ilike(search_term),
                    User.last_name.ilike(search_term),
                )
            )

        # Apply filters
        if filters:
            for key, value in filters.items():
                if hasattr(User, key):
                    query = query.where(getattr(User, key) == value)

        # Count total
        count_query = select(func.count()).select_from(query.subquery())
        total_result = await self.db.execute(count_query)
        total = total_result.scalar()

        # Apply sorting
        sort_column = getattr(User, sort_by, User.created_at)
        query = query.order_by(sort_column.desc() if order == "desc" else sort_column.asc())

        # Apply pagination
        offset = (page - 1) * per_page
        query = query.offset(offset).limit(per_page)

        result = await self.db.execute(query)
        items = result.scalars().all()

        return UserListResponse(
            items=items,
            total=total,
            page=page,
            per_page=per_page,
            pages=math.ceil(total / per_page) if per_page else 0,
        )

    async def create(self, data: UserCreate) -> User:
        user = User(
            email=data.email,
            password_hash=hash_password(data.password),
            first_name=data.first_name,
            last_name=data.last_name,
        )
        self.db.add(user)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def update(self, user_id: UUID, data: UserUpdate) -> Optional[User]:
        user = await self.get_by_id(user_id)
        if not user:
            return None
        for field, value in data.model_dump().items():
            setattr(user, field, value)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def patch(self, user_id: UUID, data: UserPatch) -> Optional[User]:
        user = await self.get_by_id(user_id)
        if not user:
            return None
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(user, field, value)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def soft_delete(self, user_id: UUID) -> bool:
        user = await self.get_by_id(user_id)
        if not user:
            return False
        from datetime import datetime, timezone
        user.deleted_at = datetime.now(timezone.utc)
        await self.db.flush()
        return True
```

#### Error Handler Middleware

```python
# app/middleware/error_handler.py
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError


class APIError(Exception):
    def __init__(self, status_code: int, message: str, details: dict | None = None):
        self.status_code = status_code
        self.message = message
        self.details = details


def register_error_handlers(app: FastAPI):
    @app.exception_handler(APIError)
    async def api_error_handler(request: Request, exc: APIError):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "status": "error",
                "message": exc.message,
                "details": exc.details,
            },
        )

    @app.exception_handler(IntegrityError)
    async def integrity_error_handler(request: Request, exc: IntegrityError):
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={
                "status": "error",
                "message": "A database constraint was violated.",
                "details": {"info": str(exc.orig) if exc.orig else None},
            },
        )

    @app.exception_handler(Exception)
    async def general_exception_handler(request: Request, exc: Exception):
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "status": "error",
                "message": "An unexpected error occurred.",
                "details": None,
            },
        )
```

---

### Express (Node.js / TypeScript)

#### Project Structure

```
project-name/
├── src/
│   ├── index.ts                 # Express app bootstrap, middleware registration
│   ├── config/
│   │   ├── index.ts             # Environment config (dotenv)
│   │   ├── cors.ts              # CORS options
│   │   └── logger.ts            # Winston/Pino logger setup
│   ├── db/
│   │   ├── client.ts            # Prisma client singleton
│   │   └── seed.ts              # Database seeding script
│   ├── models/                  # TypeScript types/interfaces
│   │   ├── index.ts
│   │   ├── user.ts
│   │   └── {entity}.ts
│   ├── schemas/                 # Zod validation schemas
│   │   ├── common.ts            # Pagination, ID params, error response
│   │   ├── auth.ts              # Login, register, token schemas
│   │   ├── user.ts
│   │   └── {entity}.ts
│   ├── routes/                  # One file per entity
│   │   ├── index.ts             # Route aggregator
│   │   ├── auth.ts              # Register, login, refresh, me
│   │   ├── health.ts            # Health check endpoint
│   │   ├── user.ts
│   │   └── {entity}.ts
│   ├── middleware/
│   │   ├── auth.ts              # JWT verification + role check
│   │   ├── errorHandler.ts      # Global error handling
│   │   ├── validate.ts          # Zod validation middleware
│   │   ├── rateLimiter.ts       # express-rate-limit setup
│   │   └── requestLogger.ts     # Request/response logging
│   ├── services/                # Business logic
│   │   ├── auth.ts
│   │   ├── user.ts
│   │   └── {entity}.ts
│   ├── utils/
│   │   ├── jwt.ts               # JWT sign/verify helpers
│   │   ├── password.ts          # bcrypt hash/compare
│   │   ├── pagination.ts        # Pagination helper
│   │   └── ApiError.ts          # Custom error class
│   └── tests/
│       ├── setup.ts             # Test setup (test DB, fixtures)
│       ├── auth.test.ts
│       ├── health.test.ts
│       └── {entity}.test.ts
├── prisma/
│   ├── schema.prisma
│   ├── seed.ts
│   └── migrations/
├── Dockerfile
├── docker-compose.yml
├── package.json
├── tsconfig.json
├── .eslintrc.json
├── .prettierrc
├── .env.example
├── .gitignore
├── jest.config.ts
└── README.md
```

#### Prisma Schema Example

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id           String    @id @default(uuid())
  email        String    @unique
  passwordHash String    @map("password_hash")
  firstName    String?   @map("first_name")
  lastName     String?   @map("last_name")
  isActive     Boolean   @default(true) @map("is_active")
  role         String    @default("user")

  createdAt    DateTime  @default(now()) @map("created_at")
  updatedAt    DateTime  @updatedAt @map("updated_at")
  deletedAt    DateTime? @map("deleted_at")

  posts        Post[]

  @@map("users")
}

model Post {
  id        String    @id @default(uuid())
  title     String
  body      String?
  status    String    @default("draft")

  authorId  String    @map("author_id")
  author    User      @relation(fields: [authorId], references: [id], onDelete: Cascade)

  createdAt DateTime  @default(now()) @map("created_at")
  updatedAt DateTime  @updatedAt @map("updated_at")
  deletedAt DateTime? @map("deleted_at")

  tags      PostTag[]

  @@map("posts")
}

model Tag {
  id    String    @id @default(uuid())
  name  String    @unique

  posts PostTag[]

  @@map("tags")
}

model PostTag {
  postId String @map("post_id")
  tagId  String @map("tag_id")
  post   Post   @relation(fields: [postId], references: [id], onDelete: Cascade)
  tag    Tag    @relation(fields: [tagId], references: [id], onDelete: Cascade)

  @@id([postId, tagId])
  @@map("posts_tags")
}
```

#### Zod Schema Example

```typescript
// src/schemas/user.ts
import { z } from "zod";

export const UserCreateSchema = z.object({
  email: z.string().email("Invalid email address"),
  password: z.string().min(8, "Password must be at least 8 characters").max(128),
  firstName: z.string().max(100).optional(),
  lastName: z.string().max(100).optional(),
});

export const UserUpdateSchema = z.object({
  email: z.string().email("Invalid email address"),
  firstName: z.string().max(100).optional(),
  lastName: z.string().max(100).optional(),
});

export const UserPatchSchema = z.object({
  email: z.string().email("Invalid email address").optional(),
  firstName: z.string().max(100).optional(),
  lastName: z.string().max(100).optional(),
});

export type UserCreate = z.infer<typeof UserCreateSchema>;
export type UserUpdate = z.infer<typeof UserUpdateSchema>;
export type UserPatch = z.infer<typeof UserPatchSchema>;
```

#### Route Example (Express + Zod + Prisma)

```typescript
// src/routes/user.ts
import { Router, Request, Response } from "express";
import { UserService } from "../services/user";
import { authenticate, requireRole } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { UserCreateSchema, UserUpdateSchema, UserPatchSchema } from "../schemas/user";
import { PaginationSchema } from "../schemas/common";
import { ApiError } from "../utils/ApiError";

const router = Router();
const userService = new UserService();

// GET /users — List with pagination, filtering, sorting
router.get(
  "/",
  authenticate,
  validate({ query: PaginationSchema }),
  async (req: Request, res: Response) => {
    const { page, perPage, sortBy, order, search, isActive } = req.query;
    const result = await userService.list({
      page: Number(page) || 1,
      perPage: Number(perPage) || 20,
      sortBy: (sortBy as string) || "createdAt",
      order: (order as string) || "desc",
      search: search as string | undefined,
      filters: { isActive: isActive === "true" ? true : isActive === "false" ? false : undefined },
    });
    res.json(result);
  }
);

// GET /users/:id
router.get("/:id", authenticate, async (req: Request, res: Response) => {
  const user = await userService.getById(req.params.id);
  if (!user) throw new ApiError(404, "User not found");
  res.json(user);
});

// POST /users
router.post(
  "/",
  authenticate,
  requireRole("admin"),
  validate({ body: UserCreateSchema }),
  async (req: Request, res: Response) => {
    const existing = await userService.getByEmail(req.body.email);
    if (existing) throw new ApiError(409, "Email already registered");
    const user = await userService.create(req.body);
    res.status(201).json(user);
  }
);

// PUT /users/:id — Full update
router.put(
  "/:id",
  authenticate,
  validate({ body: UserUpdateSchema }),
  async (req: Request, res: Response) => {
    const user = await userService.update(req.params.id, req.body);
    if (!user) throw new ApiError(404, "User not found");
    res.json(user);
  }
);

// PATCH /users/:id — Partial update
router.patch(
  "/:id",
  authenticate,
  validate({ body: UserPatchSchema }),
  async (req: Request, res: Response) => {
    const user = await userService.patch(req.params.id, req.body);
    if (!user) throw new ApiError(404, "User not found");
    res.json(user);
  }
);

// DELETE /users/:id — Soft delete
router.delete(
  "/:id",
  authenticate,
  requireRole("admin"),
  async (req: Request, res: Response) => {
    const success = await userService.softDelete(req.params.id);
    if (!success) throw new ApiError(404, "User not found");
    res.status(204).send();
  }
);

// GET /users/:id/posts — Relationship endpoint
router.get("/:id/posts", authenticate, async (req: Request, res: Response) => {
  const user = await userService.getById(req.params.id);
  if (!user) throw new ApiError(404, "User not found");
  const posts = await userService.listPosts(req.params.id, {
    page: Number(req.query.page) || 1,
    perPage: Number(req.query.perPage) || 20,
  });
  res.json(posts);
});

export default router;
```

#### Auth Middleware (Express)

```typescript
// src/middleware/auth.ts
import { Request, Response, NextFunction } from "express";
import { verifyAccessToken } from "../utils/jwt";
import { prisma } from "../db/client";
import { ApiError } from "../utils/ApiError";

export interface AuthRequest extends Request {
  user?: {
    id: string;
    email: string;
    role: string;
  };
}

export const authenticate = async (
  req: AuthRequest,
  _res: Response,
  next: NextFunction
) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    throw new ApiError(401, "Missing or invalid authorization header");
  }

  const token = authHeader.split(" ")[1];
  const payload = verifyAccessToken(token);
  if (!payload) {
    throw new ApiError(401, "Invalid or expired token");
  }

  const user = await prisma.user.findUnique({
    where: { id: payload.sub },
    select: { id: true, email: true, role: true, deletedAt: true },
  });

  if (!user || user.deletedAt) {
    throw new ApiError(401, "User not found or deactivated");
  }

  req.user = { id: user.id, email: user.email, role: user.role };
  next();
};

export const requireRole = (...roles: string[]) => {
  return (req: AuthRequest, _res: Response, next: NextFunction) => {
    if (!req.user || !roles.includes(req.user.role)) {
      throw new ApiError(403, `Requires one of roles: ${roles.join(", ")}`);
    }
    next();
  };
};
```

#### Zod Validation Middleware

```typescript
// src/middleware/validate.ts
import { Request, Response, NextFunction } from "express";
import { AnyZodObject, ZodError } from "zod";
import { ApiError } from "../utils/ApiError";

interface ValidationSchemas {
  body?: AnyZodObject;
  query?: AnyZodObject;
  params?: AnyZodObject;
}

export const validate = (schemas: ValidationSchemas) => {
  return (req: Request, _res: Response, next: NextFunction) => {
    try {
      if (schemas.body) req.body = schemas.body.parse(req.body);
      if (schemas.query) req.query = schemas.query.parse(req.query) as any;
      if (schemas.params) req.params = schemas.params.parse(req.params) as any;
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        throw new ApiError(422, "Validation failed", {
          errors: error.errors.map((e) => ({
            field: e.path.join("."),
            message: e.message,
          })),
        });
      }
      throw error;
    }
  };
};
```

#### Error Handler (Express)

```typescript
// src/middleware/errorHandler.ts
import { Request, Response, NextFunction } from "express";
import { ApiError } from "../utils/ApiError";
import { logger } from "../config/logger";

export const errorHandler = (
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
) => {
  if (err instanceof ApiError) {
    res.status(err.statusCode).json({
      status: "error",
      message: err.message,
      details: err.details ?? null,
    });
    return;
  }

  logger.error("Unhandled error:", err);
  res.status(500).json({
    status: "error",
    message: "An unexpected error occurred.",
    details: null,
  });
};
```

#### ApiError Utility

```typescript
// src/utils/ApiError.ts
export class ApiError extends Error {
  public readonly statusCode: number;
  public readonly details: Record<string, unknown> | null;

  constructor(
    statusCode: number,
    message: string,
    details?: Record<string, unknown>
  ) {
    super(message);
    this.statusCode = statusCode;
    this.details = details ?? null;
    Object.setPrototypeOf(this, ApiError.prototype);
  }
}
```

#### Express App Entry Point

```typescript
// src/index.ts
import "express-async-errors";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import { config } from "./config";
import { corsOptions } from "./config/cors";
import { logger } from "./config/logger";
import { errorHandler } from "./middleware/errorHandler";
import { requestLogger } from "./middleware/requestLogger";
import { rateLimiter } from "./middleware/rateLimiter";
import healthRouter from "./routes/health";
import authRouter from "./routes/auth";
import userRouter from "./routes/user";
// import {entity}Router from "./routes/{entity}";

const app = express();

// Global middleware
app.use(helmet());
app.use(cors(corsOptions));
app.use(express.json({ limit: "10mb" }));
app.use(requestLogger);
app.use(rateLimiter);

// Routes
const prefix = config.apiPrefix;
app.use(`${prefix}/health`, healthRouter);
app.use(`${prefix}/auth`, authRouter);
app.use(`${prefix}/users`, userRouter);
// app.use(`${prefix}/{entities}`, {entity}Router);

// Error handler (must be last)
app.use(errorHandler);

app.listen(config.port, () => {
  logger.info(`Server running on port ${config.port}`);
});

export default app;
```

#### Service Layer Example (Express + Prisma)

```typescript
// src/services/user.ts
import { prisma } from "../db/client";
import { UserCreate, UserUpdate, UserPatch } from "../schemas/user";
import { hashPassword } from "../utils/password";
import { Prisma } from "@prisma/client";

interface ListOptions {
  page: number;
  perPage: number;
  sortBy: string;
  order: string;
  search?: string;
  filters?: { isActive?: boolean };
}

const userSelect = {
  id: true,
  email: true,
  firstName: true,
  lastName: true,
  isActive: true,
  role: true,
  createdAt: true,
  updatedAt: true,
} satisfies Prisma.UserSelect;

export class UserService {
  async getById(id: string) {
    return prisma.user.findFirst({
      where: { id, deletedAt: null },
      select: userSelect,
    });
  }

  async getByEmail(email: string) {
    return prisma.user.findFirst({
      where: { email, deletedAt: null },
      select: userSelect,
    });
  }

  async list(options: ListOptions) {
    const { page, perPage, sortBy, order, search, filters } = options;
    const where: Prisma.UserWhereInput = { deletedAt: null };

    if (search) {
      where.OR = [
        { email: { contains: search, mode: "insensitive" } },
        { firstName: { contains: search, mode: "insensitive" } },
        { lastName: { contains: search, mode: "insensitive" } },
      ];
    }

    if (filters?.isActive !== undefined) {
      where.isActive = filters.isActive;
    }

    const [items, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: userSelect,
        orderBy: { [sortBy]: order },
        skip: (page - 1) * perPage,
        take: perPage,
      }),
      prisma.user.count({ where }),
    ]);

    return {
      items,
      total,
      page,
      perPage,
      pages: Math.ceil(total / perPage),
    };
  }

  async create(data: UserCreate) {
    return prisma.user.create({
      data: {
        email: data.email,
        passwordHash: await hashPassword(data.password),
        firstName: data.firstName,
        lastName: data.lastName,
      },
      select: userSelect,
    });
  }

  async update(id: string, data: UserUpdate) {
    const user = await this.getById(id);
    if (!user) return null;
    return prisma.user.update({
      where: { id },
      data: {
        email: data.email,
        firstName: data.firstName,
        lastName: data.lastName,
      },
      select: userSelect,
    });
  }

  async patch(id: string, data: UserPatch) {
    const user = await this.getById(id);
    if (!user) return null;
    return prisma.user.update({
      where: { id },
      data,
      select: userSelect,
    });
  }

  async softDelete(id: string): Promise<boolean> {
    const user = await this.getById(id);
    if (!user) return false;
    await prisma.user.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
    return true;
  }

  async listPosts(userId: string, options: { page: number; perPage: number }) {
    const { page, perPage } = options;
    const where: Prisma.PostWhereInput = { authorId: userId, deletedAt: null };

    const [items, total] = await Promise.all([
      prisma.post.findMany({
        where,
        orderBy: { createdAt: "desc" },
        skip: (page - 1) * perPage,
        take: perPage,
      }),
      prisma.post.count({ where }),
    ]);

    return {
      items,
      total,
      page,
      perPage,
      pages: Math.ceil(total / perPage),
    };
  }
}
```

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

### Pagination

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

### Filtering

Map query parameters to WHERE clauses:

```
GET /posts?status=published&author_id=abc-123
GET /users?is_active=true&role=admin
```

For date ranges:
```
GET /posts?created_after=2024-01-01&created_before=2024-12-31
```

### Sorting

```
GET /users?sort_by=created_at&order=desc
GET /posts?sort_by=title&order=asc
```

Validate that `sort_by` maps to an actual column. Reject unknown fields with 422.

### Error Response Format

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

### JWT Auth Flow

1. **Register** — Hash password (bcrypt, 12 rounds), store user, return user response (no token).
2. **Login** — Verify credentials, return `{ access_token, refresh_token, token_type: "bearer" }`.
3. **Refresh** — Accept refresh token, verify, issue new access token.
4. **Access token** — Short-lived (30 minutes), contains `{ sub: user_id, role: user_role }`.
5. **Refresh token** — Long-lived (7 days), stored in DB or signed JWT.

### Role-Based Access Control

Define roles in the user model (`admin`, `editor`, `viewer`, or custom). Apply middleware:

- **Public routes**: No auth required (health check, login, register).
- **Authenticated routes**: Valid token required (list, get, update own profile).
- **Admin routes**: Specific role required (create users, delete, manage settings).

### Request Validation

- **FastAPI**: Pydantic models with `Field` constraints (min_length, max_length, regex, ge, le).
- **Express**: Zod schemas parsed in validation middleware. Return 422 with field-level errors.

Always validate:
- Request body on POST, PUT, PATCH.
- Query parameters on GET (pagination bounds, sort field whitelist).
- Path parameters (UUID format).

### HTTP Status Codes

Use precise status codes — see the `references/http-status-codes.md` reference for the complete guide.

Key conventions:
- **201 Created** for successful POST (not 200).
- **204 No Content** for successful DELETE (empty body).
- **409 Conflict** for unique constraint violations (duplicate email).
- **422 Unprocessable Entity** for validation failures (not 400).
- **400 Bad Request** only for malformed requests (invalid JSON syntax).

### Logging Middleware

Log every request with:
- Timestamp, method, path, status code, response time (ms).
- Request ID (UUID) for tracing.
- Sanitize sensitive fields (password, tokens) from logs.

### Rate Limiting

- Default: 100 requests per minute per IP.
- Auth endpoints: 10 requests per minute per IP (brute force protection).
- Configurable via environment variables.

### CORS Configuration

- Development: Allow `http://localhost:3000` (or configurable origins).
- Production: Restrict to specific domains via `CORS_ORIGINS` env var.
- Allow credentials for cookie-based auth flows.

---

## Docker Configuration

### Multi-Stage Dockerfile (FastAPI)

```dockerfile
# Build stage
FROM python:3.12-slim AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Production stage
FROM python:3.12-slim

WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .

ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Multi-Stage Dockerfile (Express)

```dockerfile
# Build stage
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx prisma generate
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/prisma ./prisma

ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

### docker-compose.yml

```yaml
version: "3.8"

services:
  app:
    build: .
    ports:
      - "${APP_PORT:-8000}:8000"
    env_file: .env
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - .:/app        # Dev: hot reload
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${DB_NAME:-mydb}
      POSTGRES_USER: ${DB_USER:-postgres}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-postgres}
    ports:
      - "${DB_PORT:-5432}:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    ports:
      - "${REDIS_PORT:-6379}:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  pgdata:
```

### .env.example

```
# App
APP_NAME=my-api
DEBUG=false
APP_PORT=8000
API_PREFIX=/api/v1

# Database
DATABASE_URL=postgresql+asyncpg://postgres:postgres@db:5432/mydb
DB_NAME=mydb
DB_USER=postgres
DB_PASSWORD=postgres
DB_PORT=5432

# Auth
SECRET_KEY=replace-with-a-secure-random-string
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS
CORS_ORIGINS=http://localhost:3000

# Redis
REDIS_URL=redis://redis:6379/0

# Rate Limiting
RATE_LIMIT=100/minute
```

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
