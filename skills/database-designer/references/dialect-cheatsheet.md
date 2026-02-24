# SQL Dialect Cheatsheet

Quick reference for syntax differences across PostgreSQL, MySQL, and SQLite.

## Data Types

| Concept | PostgreSQL | MySQL | SQLite |
|---------|-----------|-------|--------|
| Small integer | `SMALLINT` | `SMALLINT` | `INTEGER` |
| Integer | `INTEGER` | `INT` | `INTEGER` |
| Big integer | `BIGINT` | `BIGINT` | `INTEGER` |
| Auto-increment PK | `SERIAL` / `BIGSERIAL` | `INT AUTO_INCREMENT` | `INTEGER PRIMARY KEY` |
| UUID | `UUID` | `CHAR(36)` / `BINARY(16)` | `TEXT` |
| Variable string | `VARCHAR(n)` | `VARCHAR(n)` | `TEXT` |
| Unlimited text | `TEXT` | `TEXT` / `LONGTEXT` | `TEXT` |
| Boolean | `BOOLEAN` | `TINYINT(1)` / `BOOLEAN` | `INTEGER` |
| Timestamp w/ tz | `TIMESTAMPTZ` | `TIMESTAMP` (UTC) | `TEXT` (ISO8601) |
| Timestamp no tz | `TIMESTAMP` | `DATETIME` | `TEXT` |
| Date | `DATE` | `DATE` | `TEXT` |
| JSON | `JSONB` (binary, indexable) | `JSON` | `TEXT` |
| Binary | `BYTEA` | `BLOB` / `LONGBLOB` | `BLOB` |
| Decimal | `NUMERIC(p,s)` | `DECIMAL(p,s)` | `REAL` |
| Array | `TEXT[]`, `INT[]` etc. | Not supported | Not supported |
| Enum | `CREATE TYPE ... AS ENUM` | `ENUM(...)` inline | `CHECK` constraint |

## UUID Generation

### PostgreSQL
```sql
-- Option 1: pgcrypto extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
-- Usage: DEFAULT gen_random_uuid()

-- Option 2: uuid-ossp extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- Usage: DEFAULT uuid_generate_v4()

-- PostgreSQL 13+: gen_random_uuid() is built-in (no extension needed)
```

### MySQL
```sql
-- MySQL 8.0+
-- Usage: DEFAULT (UUID())
-- Note: UUID() generates v1 (time-based), not v4 (random)
-- For v4, use application-level generation or:
-- INSERT INTO t (id) VALUES (UUID_TO_BIN(UUID(), 1)); -- swap time bits for index locality
```

### SQLite
```
-- No built-in UUID. Generate in application code.
-- Store as TEXT: '550e8400-e29b-41d4-a716-446655440000'
```

## Enum Handling

### PostgreSQL
```sql
CREATE TYPE order_status AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled');

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    status order_status NOT NULL DEFAULT 'pending'
);

-- Adding a value (PostgreSQL 9.1+):
ALTER TYPE order_status ADD VALUE 'refunded' AFTER 'cancelled';

-- WARNING: You cannot remove or rename enum values easily.
-- Workaround requires creating a new type and migrating.
```

### MySQL
```sql
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') NOT NULL DEFAULT 'pending'
);

-- Modifying:
ALTER TABLE orders MODIFY COLUMN status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded');
```

### SQLite
```sql
CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);
```

## Auto-Updating `updated_at`

### PostgreSQL (trigger)
```sql
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON table_name
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_updated_at();
```

### MySQL (column default)
```sql
updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```

### SQLite (trigger)
```sql
CREATE TRIGGER set_updated_at_table_name
    AFTER UPDATE ON table_name
BEGIN
    UPDATE table_name SET updated_at = datetime('now') WHERE id = NEW.id;
END;
```

## Foreign Key Behavior

### Cascade Options
```sql
-- Same syntax in all dialects
FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE     -- delete child when parent deleted
    ON DELETE SET NULL     -- set FK to NULL when parent deleted
    ON DELETE RESTRICT     -- prevent parent deletion if children exist
    ON DELETE NO ACTION    -- same as RESTRICT (default)
    ON DELETE SET DEFAULT  -- set FK to default value (rarely used)
```

### SQLite Foreign Key Gotcha
```sql
-- Foreign keys are OFF by default in SQLite!
PRAGMA foreign_keys = ON;  -- Must be set per connection
```

## Transaction DDL Support

| Feature | PostgreSQL | MySQL (InnoDB) | SQLite |
|---------|-----------|----------------|--------|
| Transactional DDL | Full | No (implicit commit) | Full |
| `CREATE TABLE` in transaction | Yes | Auto-commits | Yes |
| `ALTER TABLE` in transaction | Yes | Auto-commits | Yes |
| `DROP TABLE` in transaction | Yes | Auto-commits | Yes |
| Rollback DDL | Yes | No | Yes |

**MySQL implication**: Cannot safely batch DDL operations in a single transaction. Each DDL statement commits any pending transaction. Use separate migration files for each DDL change.

## Common Gotchas

### PostgreSQL
- `VARCHAR` vs `TEXT`: No performance difference. Use `TEXT` unless you need a length constraint.
- `SERIAL` is deprecated in favor of `GENERATED ALWAYS AS IDENTITY`.
- Enum values cannot be removed, only added. Plan accordingly.

### MySQL
- Default `utf8` is actually 3-byte UTF-8. Use `utf8mb4` for full Unicode support.
- `TIMESTAMP` columns auto-update unless explicitly told not to.
- `GROUP BY` in non-strict mode may silently return indeterminate results.
- Set `sql_mode = 'STRICT_TRANS_TABLES'` for safer behavior.

### SQLite
- No `ALTER TABLE DROP COLUMN` before version 3.35.0.
- No native `DATE` or `DATETIME` types — stored as TEXT, REAL, or INTEGER.
- Type affinity system: declared types are suggestions, not enforced.
- Single writer at a time (WAL mode helps with concurrent reads).
