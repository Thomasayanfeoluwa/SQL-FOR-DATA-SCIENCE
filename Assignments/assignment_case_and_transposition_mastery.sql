/*
====================================================================================================
           SQL FOR DATA SCIENCE & DATA ENGINEERING: PROFESSIONAL MASTERY CURRICULUM
                         MODULE: CASE LOGIC, PIVOTING & TRANSPOSITION
====================================================================================================

----------------------------------------------------------------------------------------------------
### 1. FOUNDATIONAL CHEAT SHEET & MENTAL FRAMEWORK
----------------------------------------------------------------------------------------------------

1. The Execution Engine of `CASE`:
   - `CASE` evaluates sequentially from top to bottom and SHORT-CIRCUITS on the first TRUE branch.
   - If no branch matches and `ELSE` is omitted, SQL returns `NULL`. Always specify `ELSE` when
     aggregating to avoid unintended `NULL` propagation.
   - Syntax:
       CASE 
           WHEN condition_1 THEN result_1
           WHEN condition_2 THEN result_2
           ELSE default_result
       END

2. The "Scatter and Gather" Pattern for Transposition (Rows -> Columns):
   - Transposition transforms relational row-records into matrix/column formats.
   - Step 1 (Scatter): Use `CASE WHEN category = 'X' THEN value ELSE 0 END` to isolate values into columns.
   - Step 2 (Gather): Wrap inside an aggregate function (`SUM`, `MAX`, `AVG`) with or without `GROUP BY`.
   - Modern Postgres Alternative: `SUM(value) FILTER (WHERE category = 'X')` (cleaner and faster).

3. Enterprise Day-to-Day Relevance:
   - Financial P&L statements (Revenue by Quarter).
   - Cohort Retention & Churn matrices (Users retained in Month 0, 1, 2...).
   - Multi-tier SLA and Credit Risk Score categorization.

====================================================================================================
*/

SET search_path TO public;

-- =================================================================================================
-- QUESTION 1: Fruit Supply Categorization (LOW, ENOUGH, FULL)
-- =================================================================================================
/*
[QUESTION]:
Write a query that displays 3 columns:
1. Fruit Name (`name`)
2. Total Supply (`total_supply`)
3. Supply Category (`category`):
   - 'LOW'    : Total supply < 20,000
   - 'ENOUGH' : Total supply between 20,000 and 50,000 (inclusive)
   - 'FULL'   : Total supply > 50,000

[MENTAL MODEL & RETENTION LOGIC]:
Think in 2 distinct pipeline stages:
1. Aggregation Phase: We need total supply per fruit, meaning we must `GROUP BY name` and `SUM(supply)`.
2. Categorization Phase: The `CASE` expression must evaluate the aggregated `SUM(supply)`, NOT the raw row value.
Order of conditions matters: Check `< 20000` first, then `<= 50000`, and default to `'FULL'` in `ELSE`.

[ENTERPRISE USE CASE]:
Inventory Health & Reorder Automation (Amazon, Walmart):
Classifying warehouse SKUs into Out-of-Stock Risk (LOW), Healthy (ENOUGH), or Excess Holding Cost (FULL).
*/

-- -------------------------------------------------------------------------------------------------
-- [ELEMENTARY APPROACH] (Works, but verbose / redundant range checks)
-- -------------------------------------------------------------------------------------------------
SELECT 
    name,
    SUM(supply) AS total_supply,
    CASE 
        WHEN SUM(supply) < 20000 THEN 'LOW'
        WHEN SUM(supply) >= 20000 AND SUM(supply) <= 50000 THEN 'ENOUGH'
        WHEN SUM(supply) > 50000 THEN 'FULL'
    END AS category
FROM fruits
GROUP BY name
ORDER BY total_supply DESC;

-- -------------------------------------------------------------------------------------------------
-- [PROFESSIONAL / PRODUCTION-GRADE APPROACH] (Clean, short-circuiting, CTE for modularity)
-- -------------------------------------------------------------------------------------------------
WITH fruit_aggregated_supply AS (
    SELECT 
        name,
        SUM(supply) AS total_supply
    FROM fruits
    GROUP BY name
)
SELECT 
    name,
    total_supply,
    CASE 
        WHEN total_supply < 20000 THEN 'LOW'
        WHEN total_supply <= 50000 THEN 'ENOUGH'
        ELSE 'FULL'
    END AS category
FROM fruit_aggregated_supply
ORDER BY total_supply DESC;


-- =================================================================================================
-- QUESTION 2: Transposing Seasonal Import Costs (Rows to Columns)
-- =================================================================================================
/*
[QUESTION]:
Tabulate total import cost (`supply * cost_per_unit`) and transpose the data so seasons become 
columns in a single-row summary table:
Columns: `winter_total`, `summer_total`, `all_year_total`, `spring_total`, `fall_total`.

[MENTAL MODEL & RETENTION LOGIC]:
Think: "How do I selectively sum only the rows that match season X?"
Multiply `supply * cost_per_unit` row by row. If season is 'Winter', pass the value to `SUM()`,
otherwise pass `0`. Because there is no `GROUP BY`, the entire table collapses into exactly 1 summary row.

[ENTERPRISE USE CASE]:
Executive Financial KPI Dashboards:
Converting granular transaction ledgers into single-line Q1, Q2, Q3, Q4 executive revenue summaries.
*/

-- -------------------------------------------------------------------------------------------------
-- [ELEMENTARY APPROACH] (Standard Conditional Aggregation)
-- -------------------------------------------------------------------------------------------------
SELECT 
    SUM(CASE WHEN season = 'Winter'   THEN supply * cost_per_unit ELSE 0 END) AS winter_total,
    SUM(CASE WHEN season = 'Summer'   THEN supply * cost_per_unit ELSE 0 END) AS summer_total,
    SUM(CASE WHEN season = 'All Year' THEN supply * cost_per_unit ELSE 0 END) AS all_year_total,
    SUM(CASE WHEN season = 'Spring'   THEN supply * cost_per_unit ELSE 0 END) AS spring_total,
    SUM(CASE WHEN season = 'Fall'     THEN supply * cost_per_unit ELSE 0 END) AS fall_total
FROM fruits;

-- -------------------------------------------------------------------------------------------------
-- [PROFESSIONAL / PRODUCTION-GRADE APPROACH] (PostgreSQL Standard FILTER Clause + Numeric Rounding)
-- -------------------------------------------------------------------------------------------------
SELECT 
    ROUND(SUM(supply * cost_per_unit) FILTER (WHERE season = 'Winter'), 2)   AS winter_cost,
    ROUND(SUM(supply * cost_per_unit) FILTER (WHERE season = 'Summer'), 2)   AS summer_cost,
    ROUND(SUM(supply * cost_per_unit) FILTER (WHERE season = 'All Year'), 2) AS all_year_cost,
    ROUND(SUM(supply * cost_per_unit) FILTER (WHERE season = 'Spring'), 2)   AS spring_cost,
    ROUND(SUM(supply * cost_per_unit) FILTER (WHERE season = 'Fall'), 2)     AS fall_cost,
    ROUND(SUM(supply * cost_per_unit), 2)                                    AS total_annual_cost
FROM fruits;


-- =================================================================================================
-- QUESTION 3: Dynamic 2D Matrix (Fruit Name vs Seasonal Supply Pivot)
-- =================================================================================================
/*
[QUESTION]:
Generate a 2D matrix displaying each fruit as a row, with seasonal supply breakdown as columns:
`name`, `winter_supply`, `summer_supply`, `spring_supply`, `fall_supply`, `all_year_supply`, `total_supply`.

[MENTAL MODEL & RETENTION LOGIC]:
Group by the primary entity (`name`), then scatter each seasonal value using `FILTER` or `CASE`.
Always compute a horizontal total (`SUM(supply)`) to validate reconciliation.
*/

SELECT 
    name,
    COALESCE(SUM(supply) FILTER (WHERE season = 'Winter'), 0)   AS winter_supply,
    COALESCE(SUM(supply) FILTER (WHERE season = 'Summer'), 0)   AS summer_supply,
    COALESCE(SUM(supply) FILTER (WHERE season = 'Spring'), 0)   AS spring_supply,
    COALESCE(SUM(supply) FILTER (WHERE season = 'Fall'), 0)     AS fall_supply,
    COALESCE(SUM(supply) FILTER (WHERE season = 'All Year'), 0) AS all_year_supply,
    SUM(supply) AS total_supply
FROM fruits
GROUP BY name
ORDER BY total_supply DESC;


-- =================================================================================================
-- QUESTION 4: Regional Supply Distribution (State-Level Matrix)
-- =================================================================================================
/*
[QUESTION]:
Pivot total units supplied by State across top fruit types ('Apple', 'Orange', 'Pear', 'Mango', 'Others').

[MENTAL MODEL & RETENTION LOGIC]:
Use an `ELSE` bucket inside the `CASE` statement to roll up long-tail items into an 'Others' column.
*/

SELECT 
    state,
    SUM(CASE WHEN name = 'Apple'  THEN supply ELSE 0 END) AS apple_units,
    SUM(CASE WHEN name = 'Orange' THEN supply ELSE 0 END) AS orange_units,
    SUM(CASE WHEN name = 'Pear'   THEN supply ELSE 0 END) AS pear_units,
    SUM(CASE WHEN name = 'Mango'  THEN supply ELSE 0 END) AS mango_units,
    SUM(CASE WHEN name NOT IN ('Apple', 'Orange', 'Pear', 'Mango') THEN supply ELSE 0 END) AS other_fruits_units,
    SUM(supply) AS state_total_units
FROM fruits
GROUP BY state
ORDER BY state_total_units DESC;


-- =================================================================================================
-- QUESTION 5: Multi-Metric Transposition (Supply & Value Side-by-Side)
-- =================================================================================================
/*
[QUESTION]:
Display each season with its unit count, total cost, and percentage of overall annual import expenditure.

[MENTAL MODEL & RETENTION LOGIC]:
Combine `GROUP BY season` with a Window Function `SUM(SUM(...)) OVER()` to calculate the denominator
(total annual budget) without performing an expensive self-join.
*/

SELECT 
    season,
    SUM(supply) AS total_units,
    ROUND(SUM(supply * cost_per_unit), 2) AS season_total_cost,
    ROUND(
        100.0 * SUM(supply * cost_per_unit) / SUM(SUM(supply * cost_per_unit)) OVER (),
        2
    ) AS pct_of_annual_spend
FROM fruits
GROUP BY season
ORDER BY season_total_cost DESC;


-- =================================================================================================
-- QUESTION 6: ABC Inventory Value Stratification (Pareto Classification)
-- =================================================================================================
/*
[QUESTION]:
Classify each fruit shipment into Cost Tiers:
- 'Class A (High Value)'   : Total Batch Cost >= $10,000
- 'Class B (Medium Value)' : Total Batch Cost between $3,000 and $9,999.99
- 'Class C (Low Value)'    : Total Batch Cost < $3,000
*/

SELECT 
    id,
    name,
    season,
    state,
    supply,
    cost_per_unit,
    ROUND(supply * cost_per_unit, 2) AS batch_cost,
    CASE 
        WHEN (supply * cost_per_unit) >= 10000 THEN 'Class A (High Value)'
        WHEN (supply * cost_per_unit) >= 3000  THEN 'Class B (Medium Value)'
        ELSE 'Class C (Low Value)'
    END AS inventory_tier
FROM fruits
ORDER BY batch_cost DESC;


-- =================================================================================================
-- QUESTION 7: Safe Division & Anomaly Flagging
-- =================================================================================================
/*
[QUESTION]:
Calculate the average cost per unit safely, flagging records where supply is below 15,000 units
or cost exceeds $0.50 as 'REVIEW REQUIRED'.

[MENTAL MODEL & RETENTION LOGIC]:
Use `NULLIF(supply, 0)` to guarantee zero-division immunity in data pipelines.
*/

SELECT 
    name,
    state,
    supply,
    cost_per_unit,
    CASE 
        WHEN supply < 15000 OR cost_per_unit > 0.50 THEN 'FLAG: REVIEW REQUIRED'
        ELSE 'STANDARD'
    END AS audit_status
FROM fruits
ORDER BY audit_status DESC, cost_per_unit DESC;
