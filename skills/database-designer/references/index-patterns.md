# Index Patterns Reference

## When to Add Indexes

### Always Index
- **Primary keys** — automatic in all dialects.
- **Foreign key columns** — not automatic in PostgreSQL/SQLite. Always add explicitly.
- **Unique constraints** — automatic index, but verify.
- **Columns in WHERE clauses** used in frequent queries.
- **Columns in JOIN conditions**.

### Consider Indexing
- **Columns in ORDER BY** if the query is paginated or sorted frequently.
- **Columns in GROUP BY** for aggregation-heavy workloads.
- **Composite indexes** for multi-column filter patterns (column order matters — most selective first, or match the query's WHERE order).

### Avoid Indexing
- **Low-cardinality boolean columns** (unless combined in a composite index or partial index).
- **Write-heavy tables with many indexes** — each index adds write overhead.
- **Columns rarely queried** — indexes without queries are dead weight.

## Index Types by Dialect

### PostgreSQL
```sql
-- B-tree (default, general purpose)
CREATE INDEX idx_users_email ON users (email);

-- Partial index (index subset of rows)
CREATE INDEX idx_users_active ON users (email) WHERE deleted_at IS NULL;

-- GIN index (JSONB, arrays, full-text search)
CREATE INDEX idx_posts_metadata ON posts USING GIN (metadata);

-- GiST index (geometric, range types, full-text)
CREATE INDEX idx_events_range ON events USING GIST (date_range);

-- BRIN index (large sequential tables, e.g., time-series)
CREATE INDEX idx_logs_created ON logs USING BRIN (created_at);

-- Composite index
CREATE INDEX idx_orders_user_status ON orders (user_id, status);

-- Expression index
CREATE INDEX idx_users_lower_email ON users (LOWER(email));

-- Unique index
CREATE UNIQUE INDEX uq_users_email ON users (email);

-- Covering index (INCLUDE)
CREATE INDEX idx_orders_user ON orders (user_id) INCLUDE (total, status);
```

### MySQL
```sql
-- B-tree (default)
CREATE INDEX idx_users_email ON users (email);

-- Fulltext index
CREATE FULLTEXT INDEX idx_posts_content ON posts (title, body);

-- Prefix index (for long strings)
CREATE INDEX idx_users_email_prefix ON users (email(50));

-- Composite index
CREATE INDEX idx_orders_user_status ON orders (user_id, status);
```

### SQLite
```sql
-- B-tree (only type available)
CREATE INDEX idx_users_email ON users (email);

-- Partial index (3.8.0+)
CREATE INDEX idx_users_active ON users (email) WHERE deleted_at IS NULL;

-- Expression index (3.9.0+)
CREATE INDEX idx_users_lower_email ON users (LOWER(email));
```

## Composite Index Column Order

The order of columns in a composite index matters. The index can satisfy queries that filter on:
- The first column only.
- The first + second column.
- All columns.

It **cannot** efficiently satisfy queries filtering only on the second or third column.

**Rule of thumb**: Place the most selective (highest cardinality) column first, or match the most common query pattern.

```sql
-- Good for: WHERE user_id = ? AND status = ?
-- Good for: WHERE user_id = ?
-- Bad for:  WHERE status = ?
CREATE INDEX idx_orders_user_status ON orders (user_id, status);
```

## Monitoring Index Usage

### PostgreSQL
```sql
-- Find unused indexes
SELECT schemaname, relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- Find missing indexes (sequential scans on large tables)
SELECT relname, seq_scan, idx_scan, n_live_tup
FROM pg_stat_user_tables
WHERE seq_scan > 100 AND n_live_tup > 10000
ORDER BY seq_scan DESC;
```

### MySQL
```sql
-- Check if query uses index
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';

-- Show index statistics
SHOW INDEX FROM users;
```
