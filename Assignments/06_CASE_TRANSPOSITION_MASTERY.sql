/*
================================================================================
 MODULE 06 — CASE STATEMENTS, DATA TRANSPOSITION & CONDITIONAL AGGREGATION
 As a Data Scientist / Analytics Engineer
================================================================================

 TOPICS COVERED:
   CASE WHEN / THEN / ELSE / END
   Salary classification and banding
   Conditional COUNT using CASE
   Pivot (rows to columns) using SUM(CASE ...)
   FILTER (WHERE ...) — modern PostgreSQL alternative
   Nested CASE in subqueries
   Regional transposition using correlated CASE + subqueries

 SCHEMA: public.employees, public.regions, public.departments
         public.fruits (for seasonal pivoting)

================================================================================
*/

SET search_path TO public;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q01  Basic CASE — salary classification (from your tutorial)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Classify every employee's salary into one of three categories:
   'UNDER PAID'   : salary < 100,000
   'PAID WELL'    : salary between 100,000 and 160,000 (exclusive)
   'EXECUTIVE'    : salary > 160,000
 Include a fourth catch-all 'UNPAID' for any edge case.
 Return employee name, salary, and category. Sort by salary DESC.

 MENTAL MODEL:
   CASE is evaluated top-down and short-circuits at the FIRST true condition.
   Always put the most specific condition FIRST.
   The ELSE clause acts as a safety net — always include it.

 CHEAT SHEET:
   CASE
     WHEN condition_1 THEN 'result_1'
     WHEN condition_2 THEN 'result_2'
     ELSE 'default'
   END AS alias_name

 ELEMENTARY vs PROFESSIONAL:
   ✗ Multiple queries, one per category
   ✓ Single CASE expression — one scan, full classification

 REAL-WORLD USE: Customer segmentation (Free/Starter/Pro/Enterprise),
 risk tier assignment (Low/Medium/High/Critical) in fraud detection,
 employee performance bands in HR systems.
*/

-- From your tutorial — exact three-tier salary banding
SELECT
    first_name,
    salary,
    CASE
        WHEN salary < 100000                    THEN 'UNDER PAID'
        WHEN salary BETWEEN 100000 AND 160000   THEN 'PAID WELL'
        WHEN salary > 160000                    THEN 'EXECUTIVE'
        ELSE 'UNPAID'
    END AS pay_category
FROM employees
ORDER BY salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q02  CASE in aggregate — counting categories in one query
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Show a single-row summary of how many employees fall into each
 salary category (UNDER PAID, PAID WELL, EXECUTIVE).

 MENTAL MODEL:
   SUM(CASE WHEN condition THEN 1 ELSE 0 END)
   → count of rows where condition is true
   This is conditional aggregation — every row contributes 1 to exactly one column.

 ELEMENTARY vs PROFESSIONAL:
   ✗ Three separate queries, one per category → three round-trips to DB
   ✓ One query with conditional aggregation → single scan

 REAL-WORLD USE: Dashboard KPI summary cards — how many users are in each tier,
 how many orders are in each status (pending/fulfilled/cancelled).
*/

-- Elementary: COUNT from a subquery (two-pass)
SELECT category, COUNT(*) FROM (
    SELECT
        first_name, salary,
        CASE
            WHEN salary < 100000                    THEN 'UNDER PAID'
            WHEN salary BETWEEN 100000 AND 160000   THEN 'PAID WELL'
            WHEN salary > 160000                    THEN 'EXECUTIVE'
            ELSE 'UNPAID'
        END AS category
    FROM employees
) categorised
GROUP BY category;

-- Professional: Conditional SUM (one-pass, faster)
SELECT
    SUM(CASE WHEN salary < 100000                  THEN 1 ELSE 0 END)  AS under_paid_count,
    SUM(CASE WHEN salary BETWEEN 100000 AND 160000 THEN 1 ELSE 0 END)  AS paid_well_count,
    SUM(CASE WHEN salary > 160000                  THEN 1 ELSE 0 END)  AS executive_count
FROM employees;

-- Modern PostgreSQL: FILTER clause (same result, cleaner syntax)
SELECT
    COUNT(*) FILTER (WHERE salary < 100000)                  AS under_paid_count,
    COUNT(*) FILTER (WHERE salary BETWEEN 100000 AND 160000) AS paid_well_count,
    COUNT(*) FILTER (WHERE salary > 160000)                  AS executive_count
FROM employees;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q03  Transposing department headcounts from rows to columns
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Pivot the headcount of 4 departments (Sports, Tools, Clothing,
 Computers) so each department becomes a column in a single summary row.

 MENTAL MODEL — THE PIVOT PATTERN:
   Input:
     department  | count
     Sports      | 20
     Tools       | 24
   Output:
     sports_count | tools_count
         20       |     24

   STEP 1 (Scatter): SUM(CASE WHEN dept = 'X' THEN 1 ELSE 0 END) AS x_count
   STEP 2 (Gather): No GROUP BY → everything collapses into one row

 REAL-WORLD USE: Executive summary dashboards, financial P&L by division as
 columns, A/B test variant counts side by side.
*/

-- From your tutorial — pivot headcount
SELECT
    SUM(CASE WHEN department = 'Sports'    THEN 1 ELSE 0 END)  AS sports_employees,
    SUM(CASE WHEN department = 'Tools'     THEN 1 ELSE 0 END)  AS tools_employees,
    SUM(CASE WHEN department = 'Clothing'  THEN 1 ELSE 0 END)  AS clothing_employees,
    SUM(CASE WHEN department = 'Computers' THEN 1 ELSE 0 END)  AS computers_employees
FROM employees;

-- Modern FILTER equivalent (cleaner, faster on large datasets)
SELECT
    COUNT(*) FILTER (WHERE department = 'Sports')    AS sports_employees,
    COUNT(*) FILTER (WHERE department = 'Tools')     AS tools_employees,
    COUNT(*) FILTER (WHERE department = 'Clothing')  AS clothing_employees,
    COUNT(*) FILTER (WHERE department = 'Computers') AS computers_employees
FROM employees;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q04  Regional employee distribution — CASE with correlated subquery
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: For each employee, show which country (America or West Africa)
 they work in based on their region_id, using CASE with a correlated subquery
 to fetch the country name.

 MENTAL MODEL:
   CASE WHEN region_id = 1 THEN (SELECT country FROM regions WHERE region_id = 1) END
   → When region_id matches, fire the subquery to get the country name.
   → This produces a sparse matrix: only one column per row is non-null.

 NOTE: This is from your tutorial exactly. The professional alternative is a
 simple JOIN — the correlated subquery per column is expensive.

 PROFESSIONAL ALTERNATIVE: JOIN regions, then use CASE on r.country directly.
*/

-- From your tutorial (educational, but not production-efficient)
SELECT
    first_name,
    CASE WHEN region_id = 1 THEN (SELECT country FROM regions WHERE region_id = 1) END AS "Region 1",
    CASE WHEN region_id = 2 THEN (SELECT country FROM regions WHERE region_id = 2) END AS "Region 2",
    CASE WHEN region_id = 3 THEN (SELECT country FROM regions WHERE region_id = 3) END AS "Region 3",
    CASE WHEN region_id = 4 THEN (SELECT country FROM regions WHERE region_id = 4) END AS "Region 4",
    CASE WHEN region_id = 5 THEN (SELECT country FROM regions WHERE region_id = 5) END AS "Region 5",
    CASE WHEN region_id = 6 THEN (SELECT country FROM regions WHERE region_id = 6) END AS "Region 6",
    CASE WHEN region_id = 7 THEN (SELECT country FROM regions WHERE region_id = 7) END AS "Region 7"
FROM employees;

-- Professional replacement (JOIN + CASE — no correlated subqueries)
SELECT
    e.first_name,
    r.region_id,
    r.country,
    r.region,
    CASE
        WHEN r.country = 'America'     THEN 'North America Headcount'
        WHEN r.country = 'West Africa' THEN 'West Africa Headcount'
        ELSE 'Other'
    END AS continent_label
FROM employees e
INNER JOIN regions r ON e.region_id = r.region_id
ORDER BY r.country, e.first_name;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q05  Country-level headcount matrix — total per continent
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Show the total number of employees in America vs West Africa
 in a single-row summary — using the sparse region matrix approach from your
 tutorial, but also the cleaner professional version.

 MENTAL MODEL:
   Step 1: Build the sparse region-country matrix (Q04 above)
   Step 2: Wrap in an outer query and COUNT the non-null columns per country

 PROFESSIONAL ALTERNATIVE: JOIN + conditional aggregation (much cleaner).
*/

-- From your tutorial (two-level subquery + COUNT)
SELECT
    COUNT(a."Region 1") + COUNT(a."Region 2") + COUNT(a."Region 3")
        + COUNT(a."Region 6") + COUNT(a."Region 7")   AS united_states_headcount,
    COUNT(a."Region 4") + COUNT(a."Region 5")          AS west_africa_headcount
FROM (
    SELECT
        first_name,
        CASE WHEN region_id = 1 THEN (SELECT country FROM regions WHERE region_id = 1) END AS "Region 1",
        CASE WHEN region_id = 2 THEN (SELECT country FROM regions WHERE region_id = 2) END AS "Region 2",
        CASE WHEN region_id = 3 THEN (SELECT country FROM regions WHERE region_id = 3) END AS "Region 3",
        CASE WHEN region_id = 4 THEN (SELECT country FROM regions WHERE region_id = 4) END AS "Region 4",
        CASE WHEN region_id = 5 THEN (SELECT country FROM regions WHERE region_id = 5) END AS "Region 5",
        CASE WHEN region_id = 6 THEN (SELECT country FROM regions WHERE region_id = 6) END AS "Region 6",
        CASE WHEN region_id = 7 THEN (SELECT country FROM regions WHERE region_id = 7) END AS "Region 7"
    FROM employees
) a;

-- Professional replacement (JOIN + FILTER — readable, fast, scalable)
SELECT
    COUNT(*) FILTER (WHERE r.country = 'America')     AS america_headcount,
    COUNT(*) FILTER (WHERE r.country = 'West Africa') AS west_africa_headcount
FROM employees e
INNER JOIN regions r ON e.region_id = r.region_id;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q06  Fruit supply categorisation (from assignment)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Display fruit name, total supply, and category:
   LOW    : total supply < 20,000
   ENOUGH : total supply 20,000–50,000
   FULL   : total supply > 50,000

 MENTAL MODEL:
   Step 1: GROUP BY fruit to get SUM(supply) per fruit.
   Step 2: Apply CASE on the aggregated SUM — NOT the raw row value.
   CASE short-circuits: < 20000 first, then <= 50000 catches the middle band,
   ELSE catches everything above 50000.
*/

WITH fruit_supply AS (
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
        WHEN total_supply < 20000  THEN 'LOW'
        WHEN total_supply <= 50000 THEN 'ENOUGH'
        ELSE 'FULL'
    END AS supply_category
FROM fruit_supply
ORDER BY total_supply DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q07  Seasonal import cost — rows to columns (assignment)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Transpose seasonal import cost data so each season becomes a column.
 Each cell = SUM(supply * cost_per_unit) for that season.

 MENTAL MODEL — THE SCATTER/GATHER PIVOT:
   Scatter: For each row, pass its cost to the relevant season column (all others = 0)
   Gather:  SUM() across all rows collapses everything into one row

 REAL-WORLD USE: Finance: quarterly revenue pivot tables, data journalism
 tables (year in columns, country in rows), AB test metric by variant.
*/

-- Elementary (CASE)
SELECT
    SUM(CASE WHEN season = 'Winter'   THEN supply * cost_per_unit ELSE 0 END) AS winter_total,
    SUM(CASE WHEN season = 'Summer'   THEN supply * cost_per_unit ELSE 0 END) AS summer_total,
    SUM(CASE WHEN season = 'All Year' THEN supply * cost_per_unit ELSE 0 END) AS all_year_total,
    SUM(CASE WHEN season = 'Spring'   THEN supply * cost_per_unit ELSE 0 END) AS spring_total,
    SUM(CASE WHEN season = 'Fall'     THEN supply * cost_per_unit ELSE 0 END) AS fall_total
FROM fruits;

-- Professional (FILTER — cleaner, faster in PostgreSQL)
SELECT
    ROUND(SUM(supply * cost_per_unit) FILTER (WHERE season = 'Winter'),   2)  AS winter_cost,
    ROUND(SUM(supply * cost_per_unit) FILTER (WHERE season = 'Summer'),   2)  AS summer_cost,
    ROUND(SUM(supply * cost_per_unit) FILTER (WHERE season = 'All Year'), 2)  AS all_year_cost,
    ROUND(SUM(supply * cost_per_unit) FILTER (WHERE season = 'Spring'),   2)  AS spring_cost,
    ROUND(SUM(supply * cost_per_unit) FILTER (WHERE season = 'Fall'),     2)  AS fall_cost,
    ROUND(SUM(supply * cost_per_unit),                                    2)  AS grand_total
FROM fruits;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q08  Seasonal cost as a VERTICAL (row-based) table first
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: First compute total import cost by season (vertical/row format),
 then use that result to build the transposed single-row view in Q07.
*/

SELECT
    season,
    ROUND(SUM(supply * cost_per_unit), 2)  AS total_import_cost
FROM fruits
GROUP BY season
ORDER BY total_import_cost DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q09  CASE in ORDER BY — custom sort order
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Sort employees by a CUSTOM priority order:
   First: Executives (salary > 160k)
   Second: Paid Well (100k – 160k)
   Third: Under Paid (< 100k)
 Within each tier, sort by salary DESC.

 MENTAL MODEL:
   ORDER BY CASE WHEN ... THEN 1 WHEN ... THEN 2 ELSE 3 END
   → assigns a numeric sort key per row, then sorts by that key

 REAL-WORLD USE: Customer priority queues (VIP first), support ticket triage,
 recommendation ordering (sponsored results before organic).
*/

SELECT
    first_name,
    department,
    salary,
    CASE
        WHEN salary > 160000                  THEN 'EXECUTIVE'
        WHEN salary BETWEEN 100000 AND 160000 THEN 'PAID WELL'
        ELSE 'UNDER PAID'
    END AS pay_tier
FROM employees
ORDER BY
    CASE
        WHEN salary > 160000                  THEN 1
        WHEN salary BETWEEN 100000 AND 160000 THEN 2
        ELSE 3
    END,
    salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q10  Multi-dimension CASE — gender + department matrix
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Show the headcount of male and female employees in 4 target
 departments (Sports, Clothing, Tools, Computers) as a matrix:
 Rows = departments, Columns = gender counts.

 MENTAL MODEL:
   This combines GROUP BY (for rows) with SUM(CASE) (for columns).
   GROUP BY department → one row per department
   SUM(CASE WHEN gender = 'F') → count females in that department's group

 REAL-WORLD USE: Diversity reporting, cross-tab frequency tables,
 pivot tables in BI tools.
*/

SELECT
    department,
    COUNT(*) FILTER (WHERE gender = 'F')  AS female_count,
    COUNT(*) FILTER (WHERE gender = 'M')  AS male_count,
    COUNT(*)                              AS total
FROM employees
WHERE department IN ('Sports', 'Clothing', 'Tools', 'Computers')
GROUP BY department
ORDER BY department;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q11  Nested CASE — multi-condition tiering
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Build a 4-tier risk label based on salary AND hire date:
   'HIGH RISK'    : salary < 60,000 AND hired before 2010
   'MEDIUM RISK'  : salary < 60,000 but hired 2010 or after
   'LOW RISK'     : salary 60,000–100,000
   'SECURE'       : salary > 100,000

 MENTAL MODEL: CASE evaluates top to bottom. Place the most specific / most
 restrictive condition first. The salary + date compound condition must be
 before the simpler salary-only conditions.
*/

SELECT
    first_name,
    department,
    salary,
    hire_date,
    CASE
        WHEN salary < 60000 AND hire_date < '2010-01-01'  THEN 'HIGH RISK'
        WHEN salary < 60000                                THEN 'MEDIUM RISK'
        WHEN salary <= 100000                              THEN 'LOW RISK'
        ELSE 'SECURE'
    END AS retention_risk
FROM employees
ORDER BY retention_risk, salary ASC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q12  Dynamic column naming using CASE — hire year brackets
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Show the number of employees hired in each era:
   'Early Era'   : hired before 2006
   'Mid Era'     : hired 2006–2011
   'Recent Era'  : hired 2012 and after

 MENTAL MODEL: Use EXTRACT(YEAR) inside CASE, then aggregate.
*/

SELECT
    COUNT(*) FILTER (WHERE hire_date < '2006-01-01')                           AS early_era_hires,
    COUNT(*) FILTER (WHERE hire_date BETWEEN '2006-01-01' AND '2011-12-31')    AS mid_era_hires,
    COUNT(*) FILTER (WHERE hire_date >= '2012-01-01')                          AS recent_era_hires,
    COUNT(*)                                                                    AS total_employees
FROM employees;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q13  Fruit × season 2D pivot matrix
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Build a 2D matrix where rows = fruit name, columns = seasons,
 and cells = total supply for that fruit in that season.
 Add a total_supply column for row-level reconciliation.
*/

SELECT
    name,
    SUM(supply) FILTER (WHERE season = 'Winter')    AS winter_supply,
    SUM(supply) FILTER (WHERE season = 'Summer')    AS summer_supply,
    SUM(supply) FILTER (WHERE season = 'Spring')    AS spring_supply,
    SUM(supply) FILTER (WHERE season = 'Fall')      AS fall_supply,
    SUM(supply) FILTER (WHERE season = 'All Year')  AS all_year_supply,
    SUM(supply)                                     AS total_supply
FROM fruits
GROUP BY name
ORDER BY total_supply DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q14  CASE inside WHERE — conditional filter logic
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Filter employees based on a dynamic business rule:
   If the employee is female: salary must be > 80,000
   If the employee is male: salary must be > 100,000
   (Simulating a parameterised filter that changes based on a row attribute)

 MENTAL MODEL:
   WHERE CASE WHEN gender = 'F' THEN salary > 80000
              WHEN gender = 'M' THEN salary > 100000
         END  — this returns TRUE or FALSE which drives the filter.

 REAL-WORLD USE: Role-based data access rules, tiered eligibility criteria
 that differ by customer segment.
*/

SELECT
    first_name,
    gender,
    department,
    salary
FROM employees
WHERE CASE
    WHEN gender = 'F' THEN salary > 80000
    WHEN gender = 'M' THEN salary > 100000
    ELSE FALSE
END
ORDER BY gender, salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q15  Full scorecard — CASE + GROUP BY + WINDOW
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Build a comprehensive compensation scorecard per department showing:
   - total headcount
   - under paid count, paid well count, executive count
   - % of executives in each department
   - department average salary
   - highest salary in department

 MENTAL MODEL: Combine GROUP BY (for departments), FILTER-based conditional
 aggregation (for tier counts), window functions (for dept-level metrics).
 This is a professional analytics report query.
*/

SELECT
    department,
    COUNT(*)                                                   AS total_headcount,
    COUNT(*) FILTER (WHERE salary < 100000)                    AS under_paid_count,
    COUNT(*) FILTER (WHERE salary BETWEEN 100000 AND 160000)   AS paid_well_count,
    COUNT(*) FILTER (WHERE salary > 160000)                    AS executive_count,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE salary > 160000)
               / NULLIF(COUNT(*), 0), 1
    )                                                          AS exec_pct,
    ROUND(AVG(salary), 0)                                      AS avg_salary,
    MAX(salary)                                                AS max_salary
FROM employees
GROUP BY department
ORDER BY exec_pct DESC, total_headcount DESC;
