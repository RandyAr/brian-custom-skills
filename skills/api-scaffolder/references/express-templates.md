# Express Templates

Complete code templates for Express (Node.js / TypeScript) API scaffolds using Prisma, Zod, and related tooling.

---

## Project Structure

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

## Prisma Schema Example

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

## Zod Schema Example

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

## Route Example (Express + Zod + Prisma)

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

## Auth Middleware (Express)

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

## Zod Validation Middleware

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

## Error Handler (Express)

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

## ApiError Utility

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

## Express App Entry Point

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

## Service Layer Example (Express + Prisma)

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
