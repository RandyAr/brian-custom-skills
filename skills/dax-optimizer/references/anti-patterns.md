# DAX Anti-Patterns Reference

A comprehensive catalog of DAX anti-patterns organized by category, with severity ratings, explanations, and corrected examples. Severity levels reflect the typical performance and correctness impact on production Power BI models.

**Severity Scale:**
- **Critical** — Causes severe performance degradation or incorrect results. Fix immediately.
- **High** — Significant performance cost, especially on large datasets. Fix in current sprint.
- **Medium** — Moderate performance or readability issue. Fix when refactoring.
- **Low** — Minor readability or style issue. Fix opportunistically.

---

## Category 1: Filter Context Issues

### 1.1 FILTER(ALL(...)) Instead of Direct Filter Arguments

**Severity: Critical**

**Description:**
Using `FILTER(ALL(Table), ...)` as a CALCULATE modifier forces the formula engine to materialize the entire table (or the entire column set from ALL), iterate row by row, and apply the predicate. Direct filter arguments in CALCULATE (column predicates) are instead converted to efficient storage engine (xmSQL) queries that leverage VertiPaq's columnar indexes.

**Bad Example:**
```dax
[Electronics Sales] =
CALCULATE (
    SUM ( Sales[Amount] ),
    FILTER (
        ALL ( Products ),
        Products[Category] = "Electronics"
    )
)
```

**Good Example:**
```dax
[Electronics Sales] =
CALCULATE (
    SUM ( Sales[Amount] ),
    Products[Category] = "Electronics",
    REMOVEFILTERS ( Products[Category] )
)
```

**VertiPaq Explanation:**
Direct column predicates in CALCULATE translate to storage engine (SE) filter conditions in the xmSQL query. The SE uses highly compressed dictionary-encoded column segments and bitmap filtering, making simple equality/inequality predicates extremely fast. When you wrap the predicate in FILTER(ALL(...)), the query plan instead materializes a temporary table in the formula engine (FE), which is single-threaded and operates row by row. For a table with millions of rows, this is orders of magnitude slower. The materialization also appears as a "datacache" in DAX Studio query plans and produces a CallbackDataID if the FILTER is used inside an iterator.

---

### 1.2 FILTER with Full Table Scan Instead of Column Predicates

**Severity: Critical**

**Description:**
Using `FILTER(TableName, ...)` as a CALCULATE modifier when a simple column predicate would suffice. Even without ALL, wrapping the predicate in FILTER forces FE evaluation. CALCULATE can accept direct Boolean expressions on columns as filter arguments, which are translated to SE operations.

**Bad Example:**
```dax
[High Value Orders] =
CALCULATE (
    COUNTROWS ( Sales ),
    FILTER ( Sales, Sales[Amount] > 1000 )
)
```

**Good Example:**
```dax
[High Value Orders] =
CALCULATE (
    COUNTROWS ( Sales ),
    Sales[Amount] > 1000
)
```

**VertiPaq Explanation:**
CALCULATE accepts Boolean filter expressions on single columns (e.g., `Table[Column] = value`, `Table[Column] > value`). These are converted to efficient SE scan operations using VertiPaq's column indexes. Wrapping in FILTER forces row-by-row iteration in the FE. The performance difference is negligible on small tables but catastrophic on tables with millions of rows. Note: FILTER is required when the predicate involves multiple columns (e.g., `Sales[Amount] > Sales[Threshold]`) or when calling functions that cannot be expressed as a simple column predicate.

---

### 1.3 Incorrect ALL vs ALLEXCEPT vs REMOVEFILTERS Usage

**Severity: High**

**Description:**
Confusion between ALL, ALLEXCEPT, and REMOVEFILTERS leads to incorrect filter removal scope. Key distinctions:
- `ALL(Table)` — removes all filters from the table.
- `ALL(Table[Column])` — removes filters only from that column.
- `ALLEXCEPT(Table, Table[Column1], Table[Column2])` — removes all filters from the table EXCEPT the listed columns.
- `REMOVEFILTERS` — semantic alias for ALL when used as a CALCULATE modifier; makes intent clearer.
- `ALLSELECTED(Table)` — restores the filter context to the outermost query-level selection.

Common mistake: using `ALL(Table)` when the intent is only to remove a specific column filter, which inadvertently removes relationship-based cross-filters.

**Bad Example:**
```dax
// Intent: Show total sales regardless of category selection
// Problem: ALL(Products) also removes filters from Products[Brand], Products[Color], etc.
[Total Sales Ignoring Category] =
CALCULATE (
    SUM ( Sales[Amount] ),
    ALL ( Products )
)
```

**Good Example:**
```dax
// Only removes the Category filter; other Product filters remain active
[Total Sales Ignoring Category] =
CALCULATE (
    SUM ( Sales[Amount] ),
    REMOVEFILTERS ( Products[Category] )
)
```

**VertiPaq Explanation:**
The scope of filter removal directly affects the SE query plan. Removing all filters from a large dimension table (ALL(Products)) means the SE must scan all rows without applying any dimension filter, then re-aggregate. Targeted filter removal (REMOVEFILTERS on a single column) keeps other filters active, resulting in a smaller SE scan. Additionally, ALL(Table) removes cross-filter propagation through relationships, which can change results unexpectedly when bi-directional cross-filtering or many-to-many relationships are involved.

---

### 1.4 Unnecessary CALCULATE Wrapping

**Severity: Medium**

**Description:**
Wrapping an expression in CALCULATE when there are no filter arguments and no row-to-filter context transition is needed. A bare CALCULATE with no arguments is a no-op in filter context. In row context (e.g., inside a calculated column or an iterator), a bare CALCULATE triggers a context transition, which may or may not be intended.

**Bad Example:**
```dax
// In a measure (already in filter context, no row context to transition)
[Total Sales] =
CALCULATE (
    SUM ( Sales[Amount] )
)
```

**Good Example:**
```dax
[Total Sales] =
SUM ( Sales[Amount] )
```

**VertiPaq Explanation:**
In filter context, CALCULATE without filter arguments adds no value and introduces unnecessary overhead: the engine must still process the CALCULATE boundary, check for filter arguments, and determine if context transition applies. While the overhead is minimal for a single measure, it becomes measurable when this measure is referenced inside iterators or nested calculations. More importantly, unnecessary CALCULATE obscures the developer's intent, making the code harder to maintain and debug.

---

### 1.5 KEEPFILTERS Omission When Intersection Is Intended

**Severity: High**

**Description:**
By default, filter arguments in CALCULATE **overwrite** existing filters on the same column. If the intent is to **intersect** (AND) with the existing filter context, KEEPFILTERS must be used. Omitting KEEPFILTERS produces results that ignore user slicer selections on the same column.

**Bad Example:**
```dax
// User selects Category = "Electronics" in a slicer.
// This measure OVERWRITES that filter, always showing Clothing.
[Clothing Sales] =
CALCULATE (
    SUM ( Sales[Amount] ),
    Products[Category] = "Clothing"
)
```

**Good Example:**
```dax
// If user selects "Clothing", shows Clothing sales.
// If user selects "Electronics", shows BLANK (intersection is empty).
[Clothing Sales] =
CALCULATE (
    SUM ( Sales[Amount] ),
    KEEPFILTERS ( Products[Category] = "Clothing" )
)
```

**VertiPaq Explanation:**
The KEEPFILTERS modifier changes how the filter argument merges with existing filter context. Without KEEPFILTERS, the new filter replaces the existing filter on the column entirely, which modifies the SE query to ignore the original slicer predicate. With KEEPFILTERS, both filters are ANDed, and the SE receives a combined predicate. The performance difference is negligible; this is primarily a correctness issue. Using KEEPFILTERS when intersection is intended prevents subtle bugs where visuals display unexpected totals.

---

## Category 2: Iterator Misuse

### 2.1 SUMX Where SUM Suffices

**Severity: Medium**

**Description:**
Using `SUMX(Table, Table[Column])` or `SUMX(Table, Table[Column] * 1)` when `SUM(Table[Column])` produces the same result. SUM is a simple aggregator that the storage engine handles natively. SUMX is an iterator that processes row by row in the formula engine and is only needed when the expression per row involves multiple columns or complex logic.

**Bad Example:**
```dax
[Total Revenue] =
SUMX ( Sales, Sales[Revenue] )
```

**Good Example:**
```dax
[Total Revenue] =
SUM ( Sales[Revenue] )
```

**VertiPaq Explanation:**
SUM, MIN, MAX, COUNT, and DISTINCTCOUNT are simple aggregators that translate directly to SE operations on a single compressed column. SUMX forces the FE to iterate over every row of the table, read the column value, and accumulate the sum. For a single-column sum, the SE aggregator is vastly faster because it operates on compressed segments in batch mode, often leveraging SIMD instructions. SUMX is justified when the per-row expression involves multiple columns (e.g., `SUMX(Sales, Sales[Quantity] * Sales[UnitPrice])`) or conditional logic.

---

### 2.2 COUNTROWS(FILTER(...)) Instead of CALCULATE(COUNTROWS(...))

**Severity: High**

**Description:**
Using `COUNTROWS(FILTER(Table, predicate))` materializes the filtered table in the FE before counting rows. `CALCULATE(COUNTROWS(Table), predicate)` pushes the predicate to the SE as a filter and counts rows efficiently.

**Bad Example:**
```dax
[Orders Above 1000] =
COUNTROWS (
    FILTER ( Sales, Sales[Amount] > 1000 )
)
```

**Good Example:**
```dax
[Orders Above 1000] =
CALCULATE (
    COUNTROWS ( Sales ),
    Sales[Amount] > 1000
)
```

**VertiPaq Explanation:**
FILTER materializes a virtual table in the FE memory, row by row, before COUNTROWS counts the rows. This materialization is expensive on large tables. With CALCULATE + COUNTROWS, the predicate becomes a SE filter and COUNTROWS is a simple SE aggregation (a segment scan counting matching rows). The SE can process this in batch mode across compressed segments. In DAX Studio profiling, the FILTER version shows a large "datacache" materialization, while the CALCULATE version shows a lean SE query. The difference grows linearly with table size.

---

### 2.3 Context Transition in High-Cardinality Iterators

**Severity: Critical**

**Description:**
Calling a measure (which contains an implicit CALCULATE) inside an iterator (SUMX, AVERAGEX, MAXX, MINX, ADDCOLUMNS, etc.) over a high-cardinality table triggers a context transition for every row. Each context transition generates a separate SE query or, worse, a single query with a CallbackDataID that forces row-by-row FE evaluation.

**Bad Example:**
```dax
// Sales table has 10 million rows. Each row triggers [Margin %] evaluation.
[Weighted Margin] =
SUMX (
    Sales,
    Sales[Amount] * [Margin %]
)
```

**Good Example:**
```dax
// Pre-compute the values needed, iterate over a smaller granularity
[Weighted Margin] =
VAR _ProductMargins =
    ADDCOLUMNS (
        VALUES ( Products[ProductKey] ),
        "@Margin", [Margin %],
        "@Sales", CALCULATE ( SUM ( Sales[Amount] ) )
    )
RETURN
    SUMX (
        _ProductMargins,
        [@Sales] * [@Margin]
    )
```

**VertiPaq Explanation:**
Context transition converts the current row context into an equivalent filter context by adding a filter for each column of the iterated table. For a table with N rows and M columns, this means N separate filter contexts, each potentially generating its own SE query. The SE query cache helps when many rows share the same combination of values, but on high-cardinality tables the cache hit rate drops and the engine emits thousands of SE queries. In the worst case, the SE cannot answer the query directly, and a CallbackDataID is used: the SE calls back to the FE for each row, destroying any possibility of batch processing. The fix is to reduce the iterator granularity by pre-aggregating at a coarser level (e.g., product level instead of transaction level).

---

### 2.4 Unnecessary Iterator for Simple Aggregation

**Severity: Medium**

**Description:**
Using MAXX/MINX to get the max/min of a single column when MAX/MIN would suffice. Same principle as SUMX vs SUM.

**Bad Example:**
```dax
[Latest Order Date] =
MAXX ( Sales, Sales[OrderDate] )
```

**Good Example:**
```dax
[Latest Order Date] =
MAX ( Sales[OrderDate] )
```

**VertiPaq Explanation:**
MAX/MIN on a single column is a direct SE aggregation that reads only the column's dictionary (the min/max values are stored in segment metadata in many cases). MAXX/MINX forces an iteration over all rows in the FE. For date columns, which typically have good compression, the SE can return MAX almost instantly from segment headers.

---

## Category 3: Structure and Readability

### 3.1 Missing VAR/RETURN — Repeated Subexpressions

**Severity: Medium**

**Description:**
The same subexpression appears multiple times in a measure without being extracted into a VAR. Each occurrence is evaluated independently, multiplying computation cost. VAR stores the result once, and all references to the variable reuse the cached value.

**Bad Example:**
```dax
[Profit Margin %] =
DIVIDE (
    SUM ( Sales[Revenue] ) - SUM ( Sales[Cost] ),
    SUM ( Sales[Revenue] )
)
```

**Good Example:**
```dax
[Profit Margin %] =
VAR _TotalRevenue = SUM ( Sales[Revenue] )
VAR _TotalCost = SUM ( Sales[Cost] )
VAR _Profit = _TotalRevenue - _TotalCost
RETURN
    DIVIDE ( _Profit, _TotalRevenue )
```

**VertiPaq Explanation:**
The DAX engine evaluates each subexpression independently. While internal caching may sometimes avoid re-computation, it is not guaranteed, especially in complex expressions or when the measure is called across different filter contexts. VARs guarantee single evaluation: the engine computes the VAR value once when it is defined and stores it in memory. Subsequent references are simple memory lookups. Additionally, VARs make the query plan more predictable, helping the engine optimize the execution path. Beyond performance, VARs dramatically improve readability and debuggability.

---

### 3.2 Using EARLIER Instead of VAR

**Severity: Medium**

**Description:**
EARLIER is a legacy function from DAX 1.0 that navigates to an outer row context. It is confusing, hard to debug (no way to inspect the value in DAX Studio), and limited to calculated columns. VAR captures the value explicitly and works everywhere.

**Bad Example:**
```dax
// Calculated column: rank customers by total purchases
= COUNTROWS (
    FILTER (
        Customers,
        Customers[TotalPurchases] > EARLIER ( Customers[TotalPurchases] )
    )
) + 1
```

**Good Example:**
```dax
VAR _CurrentPurchases = Customers[TotalPurchases]
RETURN
    COUNTROWS (
        FILTER (
            Customers,
            Customers[TotalPurchases] > _CurrentPurchases
        )
    ) + 1
```

**VertiPaq Explanation:**
No engine-level performance difference. EARLIER and VAR produce identical query plans. The advantage of VAR is purely in clarity and maintainability. EARLIER references are positional (referring to "the row context one level up"), which becomes ambiguous with multiple nested iterators. VAR references are named and explicit. SQLBI has officially recommended replacing all EARLIER usage with VAR since 2015.

---

### 3.3 Nested IF Chains Instead of SWITCH

**Severity: Low**

**Description:**
Deeply nested IF/ELSE structures for multi-value branching. SWITCH is cleaner and can be marginally faster because the engine can optimize it as a hash-lookup in some cases.

**Bad Example:**
```dax
[Status Label] =
IF (
    [StatusCode] = 1, "New",
    IF (
        [StatusCode] = 2, "In Progress",
        IF (
            [StatusCode] = 3, "Completed",
            IF (
                [StatusCode] = 4, "Cancelled",
                "Unknown"
            )
        )
    )
)
```

**Good Example:**
```dax
[Status Label] =
SWITCH (
    [StatusCode],
    1, "New",
    2, "In Progress",
    3, "Completed",
    4, "Cancelled",
    "Unknown"
)
```

**VertiPaq Explanation:**
The FE processes nested IFs by evaluating each condition sequentially. SWITCH on a single expression is semantically equivalent but allows the engine to potentially optimize the evaluation as a single lookup. The performance difference is typically negligible, but on expressions evaluated millions of times (e.g., inside an iterator), SWITCH can be measurably faster. For `SWITCH(TRUE(), ...)` patterns (multiple unrelated conditions), the engine evaluates conditions sequentially like IF, so the benefit is purely readability.

---

### 3.4 Nested CALCULATE Without Purpose

**Severity: Medium**

**Description:**
Multiple layers of CALCULATE where the inner CALCULATE's filter arguments could be merged into the outer one, or where one of the CALCULATE layers has no filter arguments and is not needed for context transition.

**Bad Example:**
```dax
[Filtered Sales] =
CALCULATE (
    CALCULATE (
        SUM ( Sales[Amount] ),
        Sales[Region] = "West"
    ),
    Products[Category] = "Electronics"
)
```

**Good Example:**
```dax
[Filtered Sales] =
CALCULATE (
    SUM ( Sales[Amount] ),
    Sales[Region] = "West",
    Products[Category] = "Electronics"
)
```

**VertiPaq Explanation:**
Each CALCULATE boundary forces the engine to create a new filter context snapshot, evaluate filter arguments, and merge them with the existing context. Nested CALCULATE adds overhead for context creation and increases query plan complexity. Merging filter arguments into a single CALCULATE produces a simpler query plan with a single filter context evaluation. Exception: nested CALCULATE is intentional when the inner CALCULATE must override a filter set by the outer CALCULATE, or when context transition is needed at a specific scope boundary.

---

### 3.5 ADDCOLUMNS + SUMMARIZE Instead of SUMMARIZECOLUMNS

**Severity: High**

**Description:**
The pattern `ADDCOLUMNS(SUMMARIZE(Table, GroupColumn), "Measure", [Measure])` was common in early DAX but has known issues: SUMMARIZE may produce incorrect results when used with expressions (not just grouping). SUMMARIZECOLUMNS is the recommended replacement. It is optimized by the engine and correctly handles blank rows (via IGNORE).

**Bad Example:**
```dax
SalesReport =
ADDCOLUMNS (
    SUMMARIZE ( Sales, Products[Category] ),
    "Total Amount", [Total Sales],
    "Order Count", [Order Count]
)
```

**Good Example:**
```dax
SalesReport =
SUMMARIZECOLUMNS (
    Products[Category],
    "Total Amount", [Total Sales],
    "Order Count", [Order Count]
)
```

**VertiPaq Explanation:**
SUMMARIZE + ADDCOLUMNS forces a two-phase evaluation: first, SUMMARIZE groups the table (SE operation), then ADDCOLUMNS iterates over the result and evaluates each expression with a context transition (FE operation). SUMMARIZECOLUMNS combines both phases into a single optimized operation that the SE can handle in many cases. The SE generates a single xmSQL query that performs grouping and aggregation together. Additionally, SUMMARIZECOLUMNS automatically removes rows where all measure values are blank (unless wrapped in IGNORE), which is the expected behavior for report visuals. Note: SUMMARIZECOLUMNS cannot be used directly inside CALCULATE filter arguments; in that context, the SUMMARIZE + ADDCOLUMNS pattern may still be necessary.

---

## Category 4: Time Intelligence

### 4.1 Manual Date Filtering Instead of Built-in Time Intelligence

**Severity: High**

**Description:**
Writing custom FILTER + date arithmetic instead of using built-in time intelligence functions (DATEADD, SAMEPERIODLASTYEAR, TOTALYTD, DATESYTD, PARALLELPERIOD, DATESINPERIOD, etc.). Built-in functions are optimized for the VertiPaq date table structure and handle edge cases (leap years, month boundaries, fiscal calendars).

**Bad Example:**
```dax
[Sales Previous Year] =
CALCULATE (
    [Total Sales],
    FILTER (
        ALL ( 'Date' ),
        'Date'[Year] = YEAR ( TODAY () ) - 1
    )
)
```

**Good Example:**
```dax
[Sales Previous Year] =
CALCULATE (
    [Total Sales],
    SAMEPERIODLASTYEAR ( 'Date'[Date] )
)
```

**VertiPaq Explanation:**
Built-in time intelligence functions generate optimized SE queries that leverage the date column's sorted, contiguous nature. They produce a date range filter that the SE handles as a segment range scan. Custom FILTER(ALL('Date'), ...) forces FE materialization of the entire date table and row-by-row predicate evaluation. Built-in functions also correctly handle partial periods, leap years, and the interaction between date table marking and filter context propagation. Requirement: the date column must come from a table marked as a date table with a contiguous date range.

---

### 4.2 Calendar Table Anti-Patterns

**Severity: High**

**Description:**
Using `VALUES('Date'[Year])` or `DISTINCT('Date'[Year])` instead of a proper date dimension table. Or building time intelligence on a date column from a fact table instead of from a dedicated date table. Also includes not marking the date table as a date table in the model.

**Bad Example:**
```dax
// Using fact table date column for time intelligence
[Sales YTD] =
TOTALYTD (
    [Total Sales],
    Sales[OrderDate]  // This is a fact table column, not a date table
)

// Using VALUES to get year list
YearTable =
VALUES ( Sales[OrderYear] )
```

**Good Example:**
```dax
// Using proper date table
[Sales YTD] =
TOTALYTD (
    [Total Sales],
    'Date'[Date]  // Proper date dimension table, marked as date table
)

// Proper calendar table
DateTable =
CALENDARAUTO ()
// Or for explicit control:
DateTable =
VAR _MinDate = MIN ( Sales[OrderDate] )
VAR _MaxDate = MAX ( Sales[OrderDate] )
RETURN
    ADDCOLUMNS (
        CALENDAR ( DATE ( YEAR ( _MinDate ), 1, 1 ), DATE ( YEAR ( _MaxDate ), 12, 31 ) ),
        "Year", YEAR ( [Date] ),
        "Month", FORMAT ( [Date], "MMMM" ),
        "MonthNumber", MONTH ( [Date] ),
        "Quarter", "Q" & FORMAT ( [Date], "Q" ),
        "YearMonth", FORMAT ( [Date], "YYYY-MM" )
    )
```

**VertiPaq Explanation:**
Time intelligence functions require a date table with a contiguous range of dates (no gaps) on a column of Date data type. Using a fact table date column fails because: (a) it may have gaps (weekends, holidays), causing time intelligence functions to produce incorrect ranges; (b) the column is not marked as a date table, so the engine cannot apply date-specific optimizations; (c) the fact table may have many duplicate dates, increasing materialization cost. A proper date dimension table is small (365 rows per year), highly compressed, and enables the SE to use range-based filtering for all time intelligence operations.

---

### 4.3 Inefficient Period-over-Period with FILTER Instead of DATEADD

**Severity: Medium**

**Description:**
Manually computing period offsets with FILTER and date arithmetic instead of using DATEADD or PARALLELPERIOD.

**Bad Example:**
```dax
[Sales Previous Month] =
CALCULATE (
    [Total Sales],
    FILTER (
        ALL ( 'Date' ),
        'Date'[Year] = YEAR ( MAX ( 'Date'[Date] ) )
            && 'Date'[MonthNumber] = MONTH ( MAX ( 'Date'[Date] ) ) - 1
    )
)
// Bug: Fails for January (month - 1 = 0)
```

**Good Example:**
```dax
[Sales Previous Month] =
CALCULATE (
    [Total Sales],
    DATEADD ( 'Date'[Date], -1, MONTH )
)
```

**VertiPaq Explanation:**
DATEADD generates a contiguous date range shifted by the specified interval. The SE processes this as a range predicate on the date column, which is extremely efficient on the sorted, compressed date segments. The manual FILTER approach not only forces FE materialization but also has correctness bugs at period boundaries (January to December, year transitions, varying month lengths, leap years). DATEADD handles all these edge cases internally.

---

## Category 5: Miscellaneous

### 5.1 SELECTEDVALUE vs HASONEVALUE + VALUES

**Severity: Low**

**Description:**
The legacy pattern `IF(HASONEVALUE(Table[Column]), VALUES(Table[Column]), alternateResult)` has been superseded by `SELECTEDVALUE(Table[Column], alternateResult)`, which was introduced to simplify this common pattern.

**Bad Example:**
```dax
[Selected Category] =
IF (
    HASONEVALUE ( Products[Category] ),
    VALUES ( Products[Category] ),
    "All Categories"
)
```

**Good Example:**
```dax
[Selected Category] =
SELECTEDVALUE ( Products[Category], "All Categories" )
```

**VertiPaq Explanation:**
No significant engine-level difference. SELECTEDVALUE is syntactic sugar over the HASONEVALUE + VALUES pattern. The engine produces equivalent query plans. The benefit is purely in code brevity and readability. SELECTEDVALUE also avoids the subtle bug where VALUES could return a table (if HASONEVALUE check is accidentally omitted or the logic is wrong), causing a runtime error.

---

### 5.2 DISTINCTCOUNT via COUNTROWS + VALUES

**Severity: Medium**

**Description:**
Using `COUNTROWS(VALUES(Table[Column]))` or `COUNTROWS(DISTINCT(Table[Column]))` instead of `DISTINCTCOUNT(Table[Column])`. DISTINCTCOUNT is a dedicated aggregator optimized by the SE.

**Bad Example:**
```dax
[Unique Customers] =
COUNTROWS ( VALUES ( Customers[CustomerID] ) )
```

**Good Example:**
```dax
[Unique Customers] =
DISTINCTCOUNT ( Customers[CustomerID] )
```

**VertiPaq Explanation:**
DISTINCTCOUNT is translated to a single SE aggregation operation that leverages the column's dictionary encoding. The dictionary already stores unique values, so the SE can return the count by examining dictionary metadata in many cases (or performing a bitmap scan for filtered contexts). COUNTROWS(VALUES(...)) first materializes the list of distinct values as a table in the FE, then counts the rows. The materialization is the expensive part, especially for high-cardinality columns (millions of unique customers). DISTINCTCOUNT avoids this materialization entirely.

---

### 5.3 Division Without DIVIDE (Division by Zero Risk)

**Severity: Medium**

**Description:**
Using the `/` operator without handling division by zero. The `/` operator returns an error when the denominator is zero or blank. DIVIDE returns BLANK (or an alternate result) by default, which is the expected behavior in most report scenarios.

**Bad Example:**
```dax
[Avg Order Value] =
SUM ( Sales[Amount] ) / COUNTROWS ( Sales )
```

**Good Example:**
```dax
[Avg Order Value] =
DIVIDE (
    SUM ( Sales[Amount] ),
    COUNTROWS ( Sales )
)
```

**VertiPaq Explanation:**
No significant engine-level performance difference. DIVIDE is a thin wrapper around division with a zero-check. The benefit is correctness: in Power BI visuals, an error value propagates and can break conditional formatting, KPI indicators, and downstream calculations. DIVIDE returning BLANK integrates cleanly with the VertiPaq auto-exist behavior and visual rendering (blank rows are suppressed in tables and matrices). Exception: when you are certain the denominator is never zero (e.g., dividing by a constant), the `/` operator is acceptable and marginally faster.

---

### 5.4 Overusing Calculated Columns for Dynamic Logic

**Severity: High**

**Description:**
Creating calculated columns for logic that depends on filter context (aggregations, comparisons to totals, rankings within sliced data). Calculated columns are computed at model refresh time and stored in the VertiPaq model, consuming memory. They do not respond to filter context because they have fixed values per row.

**Bad Example:**
```dax
// Calculated column — always shows the same rank regardless of slicer selection
Sales[Revenue Rank] =
RANKX ( ALL ( Sales ), Sales[Revenue] )
```

**Good Example:**
```dax
// Measure — dynamically ranks based on current filter context
[Revenue Rank] =
RANKX (
    ALLSELECTED ( Products[ProductName] ),
    [Total Sales]
)
```

**VertiPaq Explanation:**
Calculated columns are materialized during refresh and stored as additional columns in the VertiPaq model. Each calculated column increases model size (memory consumption) and refresh time. If the column has high cardinality (unique values per row), it compresses poorly and may significantly increase the model's memory footprint. Measures, by contrast, are computed at query time and respond to the current filter context. Use calculated columns only for values that are static per row and needed for relationships, sorting, or simple row-level categorization.

---

## Quick Reference Summary

| # | Anti-Pattern | Category | Severity | Key Fix |
|---|-------------|----------|----------|---------|
| 1.1 | FILTER(ALL(...)) table scan | Filter Context | Critical | Direct column predicate + REMOVEFILTERS |
| 1.2 | FILTER full table scan | Filter Context | Critical | Direct column predicate in CALCULATE |
| 1.3 | Incorrect ALL/ALLEXCEPT/REMOVEFILTERS | Filter Context | High | Use targeted REMOVEFILTERS on specific columns |
| 1.4 | Unnecessary CALCULATE | Filter Context | Medium | Remove redundant CALCULATE wrapper |
| 1.5 | Missing KEEPFILTERS | Filter Context | High | Add KEEPFILTERS for intersection semantics |
| 2.1 | SUMX where SUM suffices | Iterator Misuse | Medium | Replace with simple aggregator |
| 2.2 | COUNTROWS(FILTER(...)) | Iterator Misuse | High | CALCULATE(COUNTROWS(...), predicate) |
| 2.3 | Context transition in iterators | Iterator Misuse | Critical | Reduce iterator granularity |
| 2.4 | Unnecessary MAXX/MINX | Iterator Misuse | Medium | Replace with MAX/MIN |
| 3.1 | Missing VAR/RETURN | Structure | Medium | Extract repeated subexpressions |
| 3.2 | Using EARLIER | Structure | Medium | Replace with VAR |
| 3.3 | Nested IF instead of SWITCH | Structure | Low | Refactor to SWITCH |
| 3.4 | Nested CALCULATE | Structure | Medium | Merge filter arguments |
| 3.5 | ADDCOLUMNS+SUMMARIZE | Structure | High | Replace with SUMMARIZECOLUMNS |
| 4.1 | Manual date filtering | Time Intelligence | High | Use built-in time intelligence functions |
| 4.2 | Calendar table anti-patterns | Time Intelligence | High | Proper date dimension table |
| 4.3 | Manual period-over-period | Time Intelligence | Medium | Use DATEADD/PARALLELPERIOD |
| 5.1 | HASONEVALUE+VALUES | Miscellaneous | Low | SELECTEDVALUE |
| 5.2 | COUNTROWS(VALUES(...)) | Miscellaneous | Medium | DISTINCTCOUNT |
| 5.3 | Division without DIVIDE | Miscellaneous | Medium | Use DIVIDE function |
| 5.4 | Overusing calculated columns | Miscellaneous | High | Convert to measures |
