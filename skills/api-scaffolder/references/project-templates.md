# Project Templates Reference

Complete file structure templates, dependency versions, and configuration file contents for both FastAPI (Python) and Express (Node.js/TypeScript) scaffolds.

---

## FastAPI (Python) — Complete Template

### Directory Structure

```
project-name/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── config.py
│   ├── database.py
│   ├── dependencies.py
│   ├── models/
│   │   ├── __init__.py
│   │   └── user.py
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── common.py
│   │   ├── auth.py
│   │   └── user.py
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── health.py
│   │   └── user.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   └── user.py
│   ├── middleware/
│   │   ├── __init__.py
│   │   ├── error_handler.py
│   │   ├── logging.py
│   │   └── rate_limiter.py
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── security.py
│   │   ├── pagination.py
│   │   └── filters.py
│   └── tests/
│       ├── __init__.py
│       ├── conftest.py
│       ├── test_auth.py
│       ├── test_health.py
│       └── test_user.py
├── alembic/
│   ├── env.py
│   ├── script.py.mako
│   └── versions/
│       └── .gitkeep
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

### requirements.txt

```
# Web framework
fastapi==0.115.6
uvicorn[standard]==0.34.0
python-multipart==0.0.18

# Database
sqlalchemy[asyncio]==2.0.36
asyncpg==0.30.0
alembic==1.14.1

# Validation & settings
pydantic==2.10.4
pydantic-settings==2.7.1
email-validator==2.2.0

# Authentication
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
bcrypt==4.2.1

# Middleware
slowapi==0.1.9

# HTTP client (for external API calls)
httpx==0.28.1

# Redis (optional — for rate limiting, caching)
redis==5.2.1
```

### requirements-dev.txt

```
-r requirements.txt

# Testing
pytest==8.3.4
pytest-asyncio==0.24.0
pytest-cov==6.0.0
httpx==0.28.1

# Linting & formatting
ruff==0.8.6
mypy==1.14.1

# Type stubs
types-passlib==1.7.7.20240819
types-python-jose==3.3.4.20240106
```

### pyproject.toml

```toml
[project]
name = "my-api"
version = "1.0.0"
description = "REST API scaffold"
requires-python = ">=3.11"

[tool.ruff]
target-version = "py311"
line-length = 120

[tool.ruff.lint]
select = [
    "E",    # pycodestyle errors
    "W",    # pycodestyle warnings
    "F",    # pyflakes
    "I",    # isort
    "N",    # pep8-naming
    "UP",   # pyupgrade
    "B",    # flake8-bugbear
    "SIM",  # flake8-simplify
    "TCH",  # flake8-type-checking
]
ignore = [
    "E501",  # line too long (handled by formatter)
]

[tool.ruff.lint.isort]
known-first-party = ["app"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
plugins = ["pydantic.mypy"]

[[tool.mypy.overrides]]
module = ["alembic.*"]
ignore_missing_imports = true

[tool.pydantic-mypy]
init_forbid_extra = true
init_typed = true
warn_required_dynamic_aliases = true

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["app/tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
addopts = "-v --tb=short --cov=app --cov-report=term-missing"
filterwarnings = [
    "ignore::DeprecationWarning",
]
```

### alembic.ini

```ini
[alembic]
script_location = alembic
prepend_sys_path = .
sqlalchemy.url = driver://user:pass@localhost/dbname

[post_write_hooks]

[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
```

### alembic/script.py.mako

```mako
"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
${imports if imports else ""}

# revision identifiers, used by Alembic.
revision: str = ${repr(up_revision)}
down_revision: Union[str, None] = ${repr(down_revision)}
branch_labels: Union[str, Sequence[str], None] = ${repr(branch_labels)}
depends_on: Union[str, Sequence[str], None] = ${repr(depends_on)}


def upgrade() -> None:
    ${upgrades if upgrades else "pass"}


def downgrade() -> None:
    ${downgrades if downgrades else "pass"}
```

### alembic/env.py

```python
import asyncio
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.ext.asyncio import async_engine_from_config
from alembic import context

from app.config import settings
from app.database import Base
# IMPORTANT: Import every model module here so Alembic can detect them
from app.models import user  # noqa: F401

config = context.config

# Override sqlalchemy.url from env — use synchronous driver for Alembic
# asyncpg does not work with Alembic directly; use psycopg2 or replace driver
sync_url = settings.database_url.replace("+asyncpg", "+psycopg2").replace("+aiosqlite", "")
config.set_main_option("sqlalchemy.url", sync_url)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode — generate SQL script without DB connection."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection):
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


async def run_migrations_online() -> None:
    """Run migrations in 'online' mode — requires DB connection."""
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
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

### Dockerfile (FastAPI)

```dockerfile
# ---- Build stage ----
FROM python:3.12-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ---- Production stage ----
FROM python:3.12-slim

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy installed packages from builder
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# Copy application code
COPY . .

# Runtime settings
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import httpx; r = httpx.get('http://localhost:8000/api/v1/health'); r.raise_for_status()"

# Run with uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

### docker-compose.yml (FastAPI)

```yaml
version: "3.8"

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "${APP_PORT:-8000}:8000"
    env_file: .env
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - .:/app  # Development: hot reload
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
    restart: unless-stopped
    networks:
      - backend

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
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-postgres}"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - backend

  redis:
    image: redis:7-alpine
    ports:
      - "${REDIS_PORT:-6379}:6379"
    volumes:
      - redisdata:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - backend

volumes:
  pgdata:
  redisdata:

networks:
  backend:
    driver: bridge
```

### .env.example (FastAPI)

```
# =============================================
# Application
# =============================================
APP_NAME=my-api
DEBUG=false
APP_PORT=8000
API_PREFIX=/api/v1

# =============================================
# Database (PostgreSQL)
# =============================================
DATABASE_URL=postgresql+asyncpg://postgres:postgres@db:5432/mydb
DB_NAME=mydb
DB_USER=postgres
DB_PASSWORD=postgres
DB_PORT=5432
DB_POOL_SIZE=10
DB_MAX_OVERFLOW=20

# =============================================
# Authentication (JWT)
# =============================================
SECRET_KEY=replace-with-openssl-rand-hex-64
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# =============================================
# CORS
# =============================================
CORS_ORIGINS=["http://localhost:3000","http://localhost:5173"]

# =============================================
# Redis
# =============================================
REDIS_URL=redis://redis:6379/0

# =============================================
# Rate Limiting
# =============================================
RATE_LIMIT=100/minute
AUTH_RATE_LIMIT=10/minute
```

### .gitignore (FastAPI)

```
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
*.egg-info/
dist/
build/
*.egg

# Virtual environment
.venv/
venv/
env/

# IDE
.vscode/
.idea/
*.swp
*.swo

# Environment
.env
.env.local
.env.production

# Testing
.coverage
htmlcov/
.pytest_cache/

# mypy
.mypy_cache/

# Alembic
alembic/versions/*.pyc

# Docker
docker-compose.override.yml

# OS
.DS_Store
Thumbs.db
```

### app/schemas/common.py

```python
"""Shared schemas used across multiple endpoints."""
from typing import Any, Optional

from pydantic import BaseModel, Field


class PaginationParams(BaseModel):
    """Query parameters for paginated list endpoints."""
    page: int = Field(1, ge=1, description="Page number (1-indexed)")
    per_page: int = Field(20, ge=1, le=100, description="Items per page")
    sort_by: str = Field("created_at", description="Column to sort by")
    order: str = Field("desc", pattern="^(asc|desc)$", description="Sort direction")


class PaginatedResponse(BaseModel):
    """Base schema for paginated list responses."""
    items: list[Any]
    total: int
    page: int
    per_page: int
    pages: int


class ErrorResponse(BaseModel):
    """Standard error response format."""
    status: str = "error"
    message: str
    details: Optional[dict] = None


class HealthResponse(BaseModel):
    """Health check response."""
    status: str = "ok"
    database: str = "connected"
    redis: Optional[str] = None
    version: str = "1.0.0"
```

### app/schemas/auth.py

```python
"""Authentication schemas."""
from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    first_name: str | None = Field(None, max_length=100)
    last_name: str | None = Field(None, max_length=100)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str
```

### app/utils/security.py

```python
"""Security utilities: password hashing, JWT encoding/decoding."""
from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(data: dict, expires_delta: timedelta | None = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.access_token_expire_minutes)
    )
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)


def create_refresh_token(data: dict, expires_delta: timedelta | None = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(days=settings.refresh_token_expire_days)
    )
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)


def decode_access_token(token: str) -> dict | None:
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        if payload.get("type") != "access":
            return None
        return payload
    except JWTError:
        return None


def decode_refresh_token(token: str) -> dict | None:
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        if payload.get("type") != "refresh":
            return None
        return payload
    except JWTError:
        return None
```

### app/utils/pagination.py

```python
"""Reusable pagination utility for service layer."""
import math
from typing import Any, TypeVar, Generic, Sequence

from pydantic import BaseModel
from sqlalchemy import Select, func, select
from sqlalchemy.ext.asyncio import AsyncSession

T = TypeVar("T")


async def paginate(
    db: AsyncSession,
    query: Select,
    page: int = 1,
    per_page: int = 20,
) -> dict[str, Any]:
    """Apply pagination to a SQLAlchemy select query and return envelope."""
    # Count total
    count_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    # Apply offset/limit
    offset = (page - 1) * per_page
    paginated_query = query.offset(offset).limit(per_page)
    result = await db.execute(paginated_query)
    items = result.scalars().all()

    return {
        "items": items,
        "total": total,
        "page": page,
        "per_page": per_page,
        "pages": math.ceil(total / per_page) if per_page else 0,
    }
```

### app/middleware/logging.py

```python
"""Request/response logging middleware."""
import time
import uuid
import logging

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger("api")


class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id

        start_time = time.perf_counter()
        response: Response = await call_next(request)
        duration_ms = round((time.perf_counter() - start_time) * 1000, 2)

        logger.info(
            "%s %s %s %s %.2fms",
            request_id[:8],
            request.method,
            request.url.path,
            response.status_code,
            duration_ms,
        )

        response.headers["X-Request-ID"] = request_id
        response.headers["X-Response-Time"] = f"{duration_ms}ms"
        return response
```

### app/middleware/rate_limiter.py

```python
"""Rate limiting middleware using slowapi."""
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.config import settings

limiter = Limiter(key_func=get_remote_address, default_limits=[settings.rate_limit])


def setup_rate_limiting(app):
    """Register rate limiter with the FastAPI app."""
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
```

### app/routes/health.py

```python
"""Health check endpoint."""
from fastapi import APIRouter, status
from sqlalchemy import text

from app.database import AsyncSessionLocal
from app.schemas.common import HealthResponse

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """Check API and database health."""
    db_status = "connected"
    try:
        async with AsyncSessionLocal() as session:
            await session.execute(text("SELECT 1"))
    except Exception:
        db_status = "unreachable"
        return HealthResponse(
            status="degraded",
            database=db_status,
        )

    return HealthResponse(status="ok", database=db_status)
```

### app/routes/auth.py

```python
"""Authentication endpoints: register, login, refresh, me."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db, get_current_user
from app.models.user import User
from app.schemas.auth import RegisterRequest, LoginRequest, TokenResponse, RefreshRequest
from app.schemas.user import UserResponse
from app.services.auth import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(data: RegisterRequest, db: AsyncSession = Depends(get_db)):
    service = AuthService(db)
    existing = await service.get_user_by_email(data.email)
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")
    user = await service.register(data)
    return user


@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, db: AsyncSession = Depends(get_db)):
    service = AuthService(db)
    tokens = await service.login(data.email, data.password)
    if not tokens:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    return tokens


@router.post("/refresh", response_model=TokenResponse)
async def refresh(data: RefreshRequest, db: AsyncSession = Depends(get_db)):
    service = AuthService(db)
    tokens = await service.refresh(data.refresh_token)
    if not tokens:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired refresh token")
    return tokens


@router.get("/me", response_model=UserResponse)
async def me(current_user: User = Depends(get_current_user)):
    return current_user
```

### app/tests/conftest.py

```python
"""Test fixtures: async test client, test database, auth helpers."""
import asyncio
from typing import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

from app.config import settings
from app.database import Base
from app.dependencies import get_db
from app.main import app
from app.utils.security import create_access_token

# Use a separate test database
TEST_DATABASE_URL = settings.database_url.replace("/mydb", "/mydb_test")

engine = create_async_engine(TEST_DATABASE_URL, echo=False)
TestSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(autouse=True)
async def setup_database():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    async with TestSessionLocal() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
def auth_headers() -> dict[str, str]:
    """Return auth headers with a valid test token."""
    token = create_access_token({"sub": "test-user-id", "role": "admin"})
    return {"Authorization": f"Bearer {token}"}
```

---

## Express (Node.js / TypeScript) — Complete Template

### Directory Structure

```
project-name/
├── src/
│   ├── index.ts
│   ├── config/
│   │   ├── index.ts
│   │   ├── cors.ts
│   │   └── logger.ts
│   ├── db/
│   │   ├── client.ts
│   │   └── seed.ts
│   ├── models/
│   │   ├── index.ts
│   │   └── user.ts
│   ├── schemas/
│   │   ├── common.ts
│   │   ├── auth.ts
│   │   └── user.ts
│   ├── routes/
│   │   ├── index.ts
│   │   ├── auth.ts
│   │   ├── health.ts
│   │   └── user.ts
│   ├── middleware/
│   │   ├── auth.ts
│   │   ├── errorHandler.ts
│   │   ├── validate.ts
│   │   ├── rateLimiter.ts
│   │   └── requestLogger.ts
│   ├── services/
│   │   ├── auth.ts
│   │   └── user.ts
│   ├── utils/
│   │   ├── jwt.ts
│   │   ├── password.ts
│   │   ├── pagination.ts
│   │   └── ApiError.ts
│   └── tests/
│       ├── setup.ts
│       ├── auth.test.ts
│       ├── health.test.ts
│       └── user.test.ts
├── prisma/
│   ├── schema.prisma
│   ├── seed.ts
│   └── migrations/
│       └── .gitkeep
├── Dockerfile
├── docker-compose.yml
├── package.json
├── tsconfig.json
├── .eslintrc.json
├── .prettierrc
├── jest.config.ts
├── .env.example
├── .gitignore
└── README.md
```

### package.json

```json
{
  "name": "my-api",
  "version": "1.0.0",
  "description": "REST API scaffold",
  "main": "dist/index.js",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "lint": "eslint src/ --ext .ts",
    "lint:fix": "eslint src/ --ext .ts --fix",
    "format": "prettier --write \"src/**/*.ts\"",
    "test": "jest --runInBand",
    "test:watch": "jest --watch --runInBand",
    "test:coverage": "jest --coverage --runInBand",
    "db:generate": "prisma generate",
    "db:migrate": "prisma migrate dev",
    "db:migrate:prod": "prisma migrate deploy",
    "db:seed": "tsx prisma/seed.ts",
    "db:studio": "prisma studio",
    "db:reset": "prisma migrate reset",
    "docker:up": "docker compose up -d",
    "docker:down": "docker compose down",
    "docker:build": "docker compose build"
  },
  "dependencies": {
    "@prisma/client": "^6.2.1",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.7",
    "express": "^4.21.2",
    "express-async-errors": "^3.1.1",
    "express-rate-limit": "^7.5.0",
    "helmet": "^8.0.0",
    "jsonwebtoken": "^9.0.2",
    "pino": "^9.6.0",
    "pino-pretty": "^13.0.0",
    "zod": "^3.24.1"
  },
  "devDependencies": {
    "@types/bcryptjs": "^2.4.6",
    "@types/cors": "^2.8.17",
    "@types/express": "^5.0.0",
    "@types/jest": "^29.5.14",
    "@types/jsonwebtoken": "^9.0.7",
    "@types/node": "^22.10.5",
    "@types/supertest": "^6.0.2",
    "@typescript-eslint/eslint-plugin": "^8.19.1",
    "@typescript-eslint/parser": "^8.19.1",
    "eslint": "^9.17.0",
    "eslint-config-prettier": "^9.1.0",
    "jest": "^29.7.0",
    "prettier": "^3.4.2",
    "prisma": "^6.2.1",
    "supertest": "^7.0.0",
    "ts-jest": "^29.2.5",
    "tsx": "^4.19.2",
    "typescript": "^5.7.3"
  },
  "engines": {
    "node": ">=20.0.0"
  }
}
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "moduleResolution": "node",
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "exactOptionalPropertyTypes": false,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist", "src/tests"]
}
```

### .eslintrc.json

```json
{
  "root": true,
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": 2022,
    "sourceType": "module",
    "project": "./tsconfig.json"
  },
  "plugins": ["@typescript-eslint"],
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:@typescript-eslint/recommended-requiring-type-checking",
    "prettier"
  ],
  "rules": {
    "@typescript-eslint/no-unused-vars": [
      "error",
      { "argsIgnorePattern": "^_", "varsIgnorePattern": "^_" }
    ],
    "@typescript-eslint/no-explicit-any": "warn",
    "@typescript-eslint/explicit-function-return-type": "off",
    "@typescript-eslint/no-floating-promises": "error",
    "@typescript-eslint/no-misused-promises": "error",
    "no-console": ["warn", { "allow": ["warn", "error"] }]
  },
  "env": {
    "node": true,
    "jest": true
  }
}
```

### .prettierrc

```json
{
  "semi": true,
  "trailingComma": "all",
  "singleQuote": false,
  "printWidth": 100,
  "tabWidth": 2,
  "endOfLine": "lf",
  "arrowParens": "always"
}
```

### jest.config.ts

```typescript
import type { Config } from "jest";

const config: Config = {
  preset: "ts-jest",
  testEnvironment: "node",
  roots: ["<rootDir>/src"],
  testMatch: ["**/*.test.ts"],
  moduleNameMapper: {
    "^@/(.*)$": "<rootDir>/src/$1",
  },
  setupFilesAfterSetup: ["<rootDir>/src/tests/setup.ts"],
  coverageDirectory: "coverage",
  coveragePathIgnorePatterns: ["/node_modules/", "/dist/", "/tests/"],
  clearMocks: true,
  verbose: true,
};

export default config;
```

### src/config/index.ts

```typescript
import dotenv from "dotenv";

dotenv.config();

export const config = {
  // App
  appName: process.env.APP_NAME || "my-api",
  nodeEnv: process.env.NODE_ENV || "development",
  port: parseInt(process.env.APP_PORT || "3000", 10),
  apiPrefix: process.env.API_PREFIX || "/api/v1",

  // Database
  databaseUrl: process.env.DATABASE_URL || "postgresql://postgres:postgres@localhost:5432/mydb",

  // Auth
  jwtSecret: process.env.JWT_SECRET || "change-me-in-production",
  jwtAlgorithm: "HS256" as const,
  accessTokenExpiresIn: process.env.ACCESS_TOKEN_EXPIRES_IN || "30m",
  refreshTokenExpiresIn: process.env.REFRESH_TOKEN_EXPIRES_IN || "7d",

  // CORS
  corsOrigins: (process.env.CORS_ORIGINS || "http://localhost:3000").split(","),

  // Rate Limiting
  rateLimitWindowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || "60000", 10),
  rateLimitMax: parseInt(process.env.RATE_LIMIT_MAX || "100", 10),
  authRateLimitMax: parseInt(process.env.AUTH_RATE_LIMIT_MAX || "10", 10),

  // Redis
  redisUrl: process.env.REDIS_URL || "redis://localhost:6379/0",
} as const;
```

### src/config/cors.ts

```typescript
import { CorsOptions } from "cors";
import { config } from "./index";

export const corsOptions: CorsOptions = {
  origin: config.corsOrigins,
  credentials: true,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "X-Request-ID"],
  exposedHeaders: ["X-Request-ID", "X-Response-Time"],
  maxAge: 86400, // 24 hours
};
```

### src/config/logger.ts

```typescript
import pino from "pino";
import { config } from "./index";

export const logger = pino({
  level: config.nodeEnv === "production" ? "info" : "debug",
  transport:
    config.nodeEnv !== "production"
      ? { target: "pino-pretty", options: { colorize: true, translateTime: "SYS:HH:MM:ss" } }
      : undefined,
  redact: {
    paths: ["req.headers.authorization", "req.body.password", "req.body.refreshToken"],
    censor: "[REDACTED]",
  },
});
```

### src/db/client.ts

```typescript
import { PrismaClient } from "@prisma/client";
import { config } from "../config";
import { logger } from "../config/logger";

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient | undefined };

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log:
      config.nodeEnv === "development"
        ? [
            { emit: "event", level: "query" },
            { emit: "stdout", level: "error" },
            { emit: "stdout", level: "warn" },
          ]
        : [{ emit: "stdout", level: "error" }],
  });

if (config.nodeEnv !== "production") {
  globalForPrisma.prisma = prisma;
}

// Log slow queries in development
if (config.nodeEnv === "development") {
  prisma.$on("query" as never, (e: { duration: number; query: string }) => {
    if (e.duration > 100) {
      logger.warn({ duration: e.duration, query: e.query }, "Slow query detected");
    }
  });
}
```

### src/db/seed.ts

```typescript
import { PrismaClient } from "@prisma/client";
import { hashPassword } from "../utils/password";

const prisma = new PrismaClient();

async function main() {
  console.log("Seeding database...");

  // Create admin user
  const adminPassword = await hashPassword("admin123456");
  await prisma.user.upsert({
    where: { email: "admin@example.com" },
    update: {},
    create: {
      email: "admin@example.com",
      passwordHash: adminPassword,
      firstName: "Admin",
      lastName: "User",
      role: "admin",
    },
  });

  console.log("Seeding complete.");
}

main()
  .catch((e) => {
    console.error("Seeding failed:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

### src/utils/jwt.ts

```typescript
import jwt, { JwtPayload } from "jsonwebtoken";
import { config } from "../config";

export interface TokenPayload extends JwtPayload {
  sub: string;
  role: string;
  type: "access" | "refresh";
}

export function signAccessToken(payload: { sub: string; role: string }): string {
  return jwt.sign({ ...payload, type: "access" }, config.jwtSecret, {
    expiresIn: config.accessTokenExpiresIn,
    algorithm: config.jwtAlgorithm,
  });
}

export function signRefreshToken(payload: { sub: string; role: string }): string {
  return jwt.sign({ ...payload, type: "refresh" }, config.jwtSecret, {
    expiresIn: config.refreshTokenExpiresIn,
    algorithm: config.jwtAlgorithm,
  });
}

export function verifyAccessToken(token: string): TokenPayload | null {
  try {
    const payload = jwt.verify(token, config.jwtSecret) as TokenPayload;
    if (payload.type !== "access") return null;
    return payload;
  } catch {
    return null;
  }
}

export function verifyRefreshToken(token: string): TokenPayload | null {
  try {
    const payload = jwt.verify(token, config.jwtSecret) as TokenPayload;
    if (payload.type !== "refresh") return null;
    return payload;
  } catch {
    return null;
  }
}
```

### src/utils/password.ts

```typescript
import bcrypt from "bcryptjs";

const SALT_ROUNDS = 12;

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, SALT_ROUNDS);
}

export async function verifyPassword(plain: string, hashed: string): Promise<boolean> {
  return bcrypt.compare(plain, hashed);
}
```

### src/utils/ApiError.ts

```typescript
export class ApiError extends Error {
  public readonly statusCode: number;
  public readonly details: Record<string, unknown> | null;

  constructor(statusCode: number, message: string, details?: Record<string, unknown>) {
    super(message);
    this.statusCode = statusCode;
    this.details = details ?? null;
    Object.setPrototypeOf(this, ApiError.prototype);
  }

  static badRequest(message: string, details?: Record<string, unknown>) {
    return new ApiError(400, message, details);
  }

  static unauthorized(message = "Authentication required") {
    return new ApiError(401, message);
  }

  static forbidden(message = "Insufficient permissions") {
    return new ApiError(403, message);
  }

  static notFound(resource = "Resource") {
    return new ApiError(404, `${resource} not found`);
  }

  static conflict(message: string, details?: Record<string, unknown>) {
    return new ApiError(409, message, details);
  }

  static unprocessable(message: string, details?: Record<string, unknown>) {
    return new ApiError(422, message, details);
  }

  static tooManyRequests(retryAfter: number) {
    return new ApiError(429, `Rate limit exceeded. Try again in ${retryAfter} seconds.`, {
      retryAfter,
    });
  }
}
```

### src/utils/pagination.ts

```typescript
export interface PaginationOptions {
  page: number;
  perPage: number;
}

export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  perPage: number;
  pages: number;
}

export function paginationArgs(options: PaginationOptions) {
  const { page, perPage } = options;
  return {
    skip: (page - 1) * perPage,
    take: perPage,
  };
}

export function buildPaginatedResult<T>(
  items: T[],
  total: number,
  options: PaginationOptions,
): PaginatedResult<T> {
  return {
    items,
    total,
    page: options.page,
    perPage: options.perPage,
    pages: Math.ceil(total / options.perPage),
  };
}
```

### src/schemas/common.ts

```typescript
import { z } from "zod";

export const PaginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  perPage: z.coerce.number().int().min(1).max(100).default(20),
  sortBy: z.string().default("createdAt"),
  order: z.enum(["asc", "desc"]).default("desc"),
  search: z.string().optional(),
});

export const UuidParamSchema = z.object({
  id: z.string().uuid("Invalid ID format"),
});

export type PaginationQuery = z.infer<typeof PaginationSchema>;
```

### src/schemas/auth.ts

```typescript
import { z } from "zod";

export const RegisterSchema = z.object({
  email: z.string().email("Invalid email address"),
  password: z.string().min(8, "Password must be at least 8 characters").max(128),
  firstName: z.string().max(100).optional(),
  lastName: z.string().max(100).optional(),
});

export const LoginSchema = z.object({
  email: z.string().email("Invalid email address"),
  password: z.string().min(1, "Password is required"),
});

export const RefreshSchema = z.object({
  refreshToken: z.string().min(1, "Refresh token is required"),
});

export type RegisterInput = z.infer<typeof RegisterSchema>;
export type LoginInput = z.infer<typeof LoginSchema>;
export type RefreshInput = z.infer<typeof RefreshSchema>;
```

### src/middleware/auth.ts

```typescript
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

export const authenticate = async (req: AuthRequest, _res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    throw ApiError.unauthorized("Missing or invalid authorization header");
  }

  const token = authHeader.split(" ")[1];
  const payload = verifyAccessToken(token);
  if (!payload) {
    throw ApiError.unauthorized("Invalid or expired token");
  }

  const user = await prisma.user.findUnique({
    where: { id: payload.sub },
    select: { id: true, email: true, role: true, deletedAt: true },
  });

  if (!user || user.deletedAt) {
    throw ApiError.unauthorized("User not found or deactivated");
  }

  req.user = { id: user.id, email: user.email, role: user.role };
  next();
};

export const requireRole = (...roles: string[]) => {
  return (req: AuthRequest, _res: Response, next: NextFunction) => {
    if (!req.user || !roles.includes(req.user.role)) {
      throw ApiError.forbidden(`Requires one of roles: ${roles.join(", ")}`);
    }
    next();
  };
};
```

### src/middleware/errorHandler.ts

```typescript
import { Request, Response, NextFunction } from "express";
import { ApiError } from "../utils/ApiError";
import { logger } from "../config/logger";
import { Prisma } from "@prisma/client";

export const errorHandler = (err: Error, _req: Request, res: Response, _next: NextFunction) => {
  // Custom API errors
  if (err instanceof ApiError) {
    res.status(err.statusCode).json({
      status: "error",
      message: err.message,
      details: err.details,
    });
    return;
  }

  // Prisma unique constraint violation
  if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
    const target = (err.meta?.target as string[]) || [];
    res.status(409).json({
      status: "error",
      message: `A record with this ${target.join(", ")} already exists.`,
      details: { fields: target },
    });
    return;
  }

  // Prisma record not found
  if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2025") {
    res.status(404).json({
      status: "error",
      message: "Record not found.",
      details: null,
    });
    return;
  }

  // Unhandled errors
  logger.error(err, "Unhandled error");
  res.status(500).json({
    status: "error",
    message: "An unexpected error occurred.",
    details: null,
  });
};
```

### src/middleware/validate.ts

```typescript
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
        throw ApiError.unprocessable("Validation failed", {
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

### src/middleware/rateLimiter.ts

```typescript
import rateLimit from "express-rate-limit";
import { config } from "../config";

export const rateLimiter = rateLimit({
  windowMs: config.rateLimitWindowMs,
  max: config.rateLimitMax,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    status: "error",
    message: "Too many requests, please try again later.",
    details: null,
  },
});

export const authRateLimiter = rateLimit({
  windowMs: config.rateLimitWindowMs,
  max: config.authRateLimitMax,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    status: "error",
    message: "Too many authentication attempts, please try again later.",
    details: null,
  },
});
```

### src/middleware/requestLogger.ts

```typescript
import { Request, Response, NextFunction } from "express";
import { randomUUID } from "crypto";
import { logger } from "../config/logger";

export const requestLogger = (req: Request, res: Response, next: NextFunction) => {
  const requestId = (req.headers["x-request-id"] as string) || randomUUID();
  const start = process.hrtime.bigint();

  res.setHeader("X-Request-ID", requestId);

  res.on("finish", () => {
    const durationMs = Number(process.hrtime.bigint() - start) / 1_000_000;

    logger.info({
      requestId: requestId.slice(0, 8),
      method: req.method,
      path: req.originalUrl,
      statusCode: res.statusCode,
      durationMs: Math.round(durationMs * 100) / 100,
    });
  });

  next();
};
```

### src/routes/index.ts

```typescript
import { Router } from "express";
import healthRouter from "./health";
import authRouter from "./auth";
import userRouter from "./user";

const router = Router();

router.use("/health", healthRouter);
router.use("/auth", authRouter);
router.use("/users", userRouter);
// router.use("/{entities}", {entity}Router);

export default router;
```

### src/routes/health.ts

```typescript
import { Router, Request, Response } from "express";
import { prisma } from "../db/client";

const router = Router();

router.get("/", async (_req: Request, res: Response) => {
  let dbStatus = "connected";
  try {
    await prisma.$queryRaw`SELECT 1`;
  } catch {
    dbStatus = "unreachable";
    res.status(503).json({
      status: "degraded",
      database: dbStatus,
      version: "1.0.0",
    });
    return;
  }

  res.json({
    status: "ok",
    database: dbStatus,
    version: "1.0.0",
  });
});

export default router;
```

### src/routes/auth.ts

```typescript
import { Router, Request, Response } from "express";
import { AuthService } from "../services/auth";
import { authenticate, AuthRequest } from "../middleware/auth";
import { validate } from "../middleware/validate";
import { authRateLimiter } from "../middleware/rateLimiter";
import { RegisterSchema, LoginSchema, RefreshSchema } from "../schemas/auth";
import { ApiError } from "../utils/ApiError";

const router = Router();
const authService = new AuthService();

router.post(
  "/register",
  authRateLimiter,
  validate({ body: RegisterSchema }),
  async (req: Request, res: Response) => {
    const existing = await authService.getUserByEmail(req.body.email);
    if (existing) throw ApiError.conflict("Email already registered");
    const user = await authService.register(req.body);
    res.status(201).json(user);
  },
);

router.post(
  "/login",
  authRateLimiter,
  validate({ body: LoginSchema }),
  async (req: Request, res: Response) => {
    const tokens = await authService.login(req.body.email, req.body.password);
    if (!tokens) throw ApiError.unauthorized("Invalid email or password");
    res.json(tokens);
  },
);

router.post(
  "/refresh",
  validate({ body: RefreshSchema }),
  async (req: Request, res: Response) => {
    const tokens = await authService.refresh(req.body.refreshToken);
    if (!tokens) throw ApiError.unauthorized("Invalid or expired refresh token");
    res.json(tokens);
  },
);

router.get("/me", authenticate, async (req: AuthRequest, res: Response) => {
  res.json(req.user);
});

export default router;
```

### src/index.ts

```typescript
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
import routes from "./routes";

const app = express();

// Global middleware
app.use(helmet());
app.use(cors(corsOptions));
app.use(express.json({ limit: "10mb" }));
app.use(requestLogger);
app.use(rateLimiter);

// Routes
app.use(config.apiPrefix, routes);

// Error handler (must be registered last)
app.use(errorHandler);

app.listen(config.port, () => {
  logger.info(`Server running on port ${config.port} [${config.nodeEnv}]`);
});

export default app;
```

### src/tests/setup.ts

```typescript
import { prisma } from "../db/client";

beforeAll(async () => {
  // Ensure test database is clean
  // Use a test-specific DATABASE_URL in .env.test
});

afterAll(async () => {
  await prisma.$disconnect();
});

afterEach(async () => {
  // Clean up test data between tests
  // Delete in reverse dependency order
  const tablenames = await prisma.$queryRaw<
    Array<{ tablename: string }>
  >`SELECT tablename FROM pg_tables WHERE schemaname='public'`;

  for (const { tablename } of tablenames) {
    if (tablename !== "_prisma_migrations") {
      await prisma.$executeRawUnsafe(`TRUNCATE TABLE "${tablename}" CASCADE;`);
    }
  }
});
```

### Dockerfile (Express)

```dockerfile
# ---- Build stage ----
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN npx prisma generate
RUN npm run build

# ---- Production stage ----
FROM node:20-alpine

WORKDIR /app

# Install production dependencies only
COPY package*.json ./
RUN npm ci --omit=dev

# Copy built output and Prisma files
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/prisma ./prisma

# Runtime settings
ENV NODE_ENV=production
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/v1/health || exit 1

CMD ["node", "dist/index.js"]
```

### docker-compose.yml (Express)

```yaml
version: "3.8"

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "${APP_PORT:-3000}:3000"
    env_file: .env
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - .:/app             # Development: hot reload
      - /app/node_modules  # Preserve container node_modules
    command: npm run dev
    restart: unless-stopped
    networks:
      - backend

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
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-postgres}"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - backend

  redis:
    image: redis:7-alpine
    ports:
      - "${REDIS_PORT:-6379}:6379"
    volumes:
      - redisdata:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - backend

volumes:
  pgdata:
  redisdata:

networks:
  backend:
    driver: bridge
```

### .env.example (Express)

```
# =============================================
# Application
# =============================================
APP_NAME=my-api
NODE_ENV=development
APP_PORT=3000
API_PREFIX=/api/v1

# =============================================
# Database (PostgreSQL via Prisma)
# =============================================
DATABASE_URL=postgresql://postgres:postgres@db:5432/mydb?schema=public
DB_NAME=mydb
DB_USER=postgres
DB_PASSWORD=postgres
DB_PORT=5432

# =============================================
# Authentication (JWT)
# =============================================
JWT_SECRET=replace-with-openssl-rand-hex-64
ACCESS_TOKEN_EXPIRES_IN=30m
REFRESH_TOKEN_EXPIRES_IN=7d

# =============================================
# CORS
# =============================================
CORS_ORIGINS=http://localhost:3000,http://localhost:5173

# =============================================
# Redis
# =============================================
REDIS_URL=redis://redis:6379/0

# =============================================
# Rate Limiting
# =============================================
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX=100
AUTH_RATE_LIMIT_MAX=10
```

### .gitignore (Express)

```
# Dependencies
node_modules/

# Build output
dist/

# Environment
.env
.env.local
.env.production
.env.test

# IDE
.vscode/
.idea/
*.swp
*.swo

# Testing
coverage/

# Prisma
prisma/migrations/**/migration_lock.toml

# Docker
docker-compose.override.yml

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/
```

---

## Prisma Schema — Starter Template

Use this as the base Prisma schema when scaffolding Express projects. Extend it per the user's entities.

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// =============================================
// Auth / Users
// =============================================
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

  // Add relationships here as entities are generated
  // posts Post[]

  @@index([email])
  @@index([deletedAt])
  @@map("users")
}

// =============================================
// Add entity models below
// =============================================
```

---

## SQLAlchemy — Base Model Template

Use this as the base for FastAPI projects. All entity models should inherit from `Base` and follow this pattern.

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

### Entity Model Template

```python
# app/models/{entity}.py
import uuid
from datetime import datetime

from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base


class EntityName(Base):
    __tablename__ = "entity_names"  # plural, snake_case

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, server_default=text("gen_random_uuid()"))

    # --- Fields (from schema) ---
    # name = Column(String(255), nullable=False)
    # description = Column(Text, nullable=True)
    # is_active = Column(Boolean, nullable=False, server_default=text("true"))

    # --- Foreign Keys ---
    # parent_id = Column(UUID(as_uuid=True), ForeignKey("parents.id", ondelete="CASCADE"), nullable=False)

    # --- Audit columns ---
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"))
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=text("now()"), onupdate=datetime.utcnow)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    # --- Relationships ---
    # parent = relationship("Parent", back_populates="children")
    # children = relationship("Child", back_populates="parent", lazy="selectin")
```

---

## Version Compatibility Notes

### Python Stack

| Package | Minimum Version | Notes |
|---------|----------------|-------|
| Python | 3.11 | Required for `tomllib`, `StrEnum`, improved typing |
| FastAPI | 0.100+ | Pydantic v2 support, lifespan context manager |
| Pydantic | 2.0+ | `model_config`, `ConfigDict`, `model_dump()` |
| SQLAlchemy | 2.0+ | New-style ORM, async support, `select()` API |
| Alembic | 1.12+ | Async engine support |
| asyncpg | 0.29+ | PostgreSQL async driver |

### Node.js Stack

| Package | Minimum Version | Notes |
|---------|----------------|-------|
| Node.js | 20 LTS | Native fetch, stable test runner, performance improvements |
| TypeScript | 5.3+ | `satisfies`, `const` type params, decorators |
| Prisma | 5.0+ | JSON protocol (faster), `@default(uuid())`, extended types |
| Express | 4.18+ | Stable async error handling (with express-async-errors) |
| Zod | 3.22+ | `.pipe()`, improved error messages |

### Docker Images

| Image | Tag | Size | Notes |
|-------|-----|------|-------|
| `python` | `3.12-slim` | ~50MB | Minimal Python runtime |
| `node` | `20-alpine` | ~55MB | Minimal Node.js runtime |
| `postgres` | `16-alpine` | ~85MB | Latest stable PostgreSQL |
| `redis` | `7-alpine` | ~15MB | In-memory cache/rate limiting |
