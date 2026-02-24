# Normalization Quick Reference

## First Normal Form (1NF)
**Rule**: Every column must contain only atomic (indivisible) values. No repeating groups or arrays.

**Violation example**:
```
| user_id | name  | phones                    |
|---------|-------|---------------------------|
| 1       | Alice | 555-0100, 555-0101        |
```

**Fix**: Create a separate `user_phones` table:
```sql
CREATE TABLE user_phones (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    phone VARCHAR(20) NOT NULL
);
```

## Second Normal Form (2NF)
**Rule**: Must be in 1NF + every non-key column must depend on the **entire** primary key (no partial dependencies).

Only relevant for composite primary keys.

**Violation example** (composite PK: `student_id, course_id`):
```
| student_id | course_id | course_name | grade |
|------------|-----------|-------------|-------|
| 1          | 101       | Math        | A     |
```
`course_name` depends only on `course_id`, not on the full PK.

**Fix**: Move `course_name` to a `courses` table.

## Third Normal Form (3NF)
**Rule**: Must be in 2NF + no transitive dependencies (non-key column depending on another non-key column).

**Violation example**:
```
| employee_id | department_id | department_name |
|-------------|---------------|-----------------|
| 1           | 10            | Engineering     |
```
`department_name` depends on `department_id`, not directly on `employee_id`.

**Fix**: Move `department_name` to a `departments` table. Keep only `department_id` as FK in `employees`.

## When to Denormalize

Normalization is the default. Consider **controlled denormalization** only when:
- Read performance is critical and joins are the measured bottleneck.
- Reporting/analytics queries aggregate across many tables.
- The denormalized data changes infrequently.

Common denormalization patterns:
- **Materialized views** (PostgreSQL) for complex aggregations.
- **Computed/stored columns** for frequently calculated values.
- **JSON columns** for truly schema-less nested data (e.g., user preferences).
- **Counter caches** (e.g., `posts_count` on `users`) updated via triggers.

Always document the reason for denormalization and the update strategy.
