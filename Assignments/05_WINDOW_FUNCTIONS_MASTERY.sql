/*
================================================================================
 MODULE 05 — WINDOW FUNCTIONS: OVER, PARTITION, RANK, LEAD/LAG, FRAMES
 As a Data Scientist / Senior Analytics Engineer
================================================================================

 WINDOW FUNCTION SYNTAX:
   function() OVER (
       PARTITION BY col     -- define groups (like GROUP BY but rows stay separate)
       ORDER BY col         -- define order within partition
       ROWS/RANGE BETWEEN   -- define the frame (sliding window)
   )

 KEY DISTINCTION:
   GROUP BY  → collapses rows into one row per group (aggregation destroys detail)
   OVER()    → computes aggregate while KEEPING all rows (best of both worlds)

 WINDOW FUNCTIONS AVAILABLE:
   ROW_NUMBER()    RANK()    DENSE_RANK()    NTILE(n)
   SUM()           AVG()     MIN()           MAX()     COUNT()
   FIRST_VALUE()   LAST_VALUE()   NTH_VALUE(col, n)
   LEAD()          LAG()

 FRAME CLAUSES:
   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW  → running total
   ROWS BETWEEN 3 PRECEDING AND CURRENT ROW          → rolling 4-row window
   RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW → same but by VALUE range

================================================================================
*/

SET search_path TO public;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q01  OVER() — global aggregate alongside detail rows
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: For each employee, show their name, department, salary, AND the
 total company headcount and total company payroll in every row.
 (Without a window function, this requires a self-join or subquery for each row.)

 MENTAL MODEL:
   COUNT(*) OVER()  → counts all rows in the entire table (empty OVER = entire result set)
   SUM(salary) OVER() → sums all salaries globally
   Each row keeps its OWN data PLUS sees the global aggregate.

 ELEMENTARY vs PROFESSIONAL:
   ✗ SELECT *, (SELECT COUNT(*) FROM employees) AS total  → scalar correlated subquery, O(N)
   ✓ COUNT(*) OVER()                                       → single pass, O(N log N) at most

 REAL-WORLD USE: Percentage-of-total calculations (each employee's salary as % of payroll),
 anomaly detection (how far is this value from the global mean?).
*/

SELECT
    first_name,
    department,
    salary,
    COUNT(*) OVER ()                    AS total_company_headcount,
    SUM(salary) OVER ()                 AS total_company_payroll,
    ROUND(
        100.0 * salary / SUM(salary) OVER (),
        2
    )                                   AS pct_of_total_payroll
FROM employees
ORDER BY department, salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q02  PARTITION BY — group-level aggregates alongside detail rows
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: For each employee, show their name, department, salary AND:
   - how many people are in their department (dept_headcount)
   - how many people are in their region (region_headcount)
   - the department's total payroll

 MENTAL MODEL:
   PARTITION BY department  → restart the window per department (just like GROUP BY)
   But rows are NOT collapsed — each row still appears individually.

 This replaces a correlated subquery from your tutorial:
   SELECT COUNT(*) FROM employees e1 WHERE e1.department = e.department
   → This executes once per row in the outer query. Very slow at scale.

 REAL-WORLD USE: Ratio analysis (my salary vs my department total),
 headcount benchmarking by team, workload distribution analytics.
*/

-- The correlated subquery version you learned (slow)
SELECT first_name, department,
    (SELECT COUNT(*) FROM employees e1 WHERE e1.department = e.department)
FROM employees e
GROUP BY department, first_name;

-- Professional window function version (fast, single scan)
SELECT
    first_name,
    department,
    region_id,
    salary,
    COUNT(*) OVER (PARTITION BY department)         AS dept_headcount,
    COUNT(*) OVER (PARTITION BY region_id)          AS region_headcount,
    SUM(salary) OVER (PARTITION BY department)      AS dept_payroll,
    ROUND(
        100.0 * salary / SUM(salary) OVER (PARTITION BY department),
        2
    )                                               AS pct_of_dept_payroll
FROM employees
ORDER BY department, salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q03  ROW_NUMBER() — assigning unique sequential IDs
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Assign a row number to every employee in region 3, ordered by
 department. Also show the total count per department partition.

 MENTAL MODEL:
   ROW_NUMBER() OVER ()                       → sequential from 1 across full result
   ROW_NUMBER() OVER (ORDER BY col)           → sequential by that order
   ROW_NUMBER() OVER (PARTITION BY X ORDER BY Y)  → resets to 1 per partition

 KEY USE: Pagination, deduplication (pick row 1 per partition = keep first),
 building synthetic IDs for tables missing a primary key.

 REAL-WORLD USE: Extracting the most recent record per customer (dedup),
 building paginated API responses, creating unique keys for merge operations.
*/

SELECT
    ROW_NUMBER() OVER ()                                        AS global_row_no,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS row_within_dept,
    first_name,
    department,
    region_id,
    salary,
    COUNT(*) OVER (PARTITION BY department)                     AS dept_total_rows
FROM employees
WHERE region_id = 3
ORDER BY department, salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q04  RANK() vs DENSE_RANK() — understanding tie behaviour
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Rank employees within each department by salary (highest first).
 Show both RANK and DENSE_RANK to illustrate the difference with ties.

 MENTAL MODEL:
   Scores: 100, 100, 90, 80
   RANK():       1, 1, 3, 4   → gaps appear after ties (rank 2 skipped)
   DENSE_RANK(): 1, 1, 2, 3   → no gaps, next rank immediately follows

   Use DENSE_RANK when you want to ask "who is in the top 3 tiers?"
   Use RANK when you need true positional rank (sports leaderboards).

 CHEAT SHEET:
   RANK()       OVER (PARTITION BY dept ORDER BY salary DESC)
   DENSE_RANK() OVER (PARTITION BY dept ORDER BY salary DESC)
   ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) -- no tie handling

 REAL-WORLD USE: Sales leaderboards, student grade rankings, fantasy sports,
 employee performance tiers, product popularity rankings on e-commerce.
*/

SELECT
    first_name,
    email,
    department,
    salary,
    RANK()       OVER (PARTITION BY department ORDER BY salary DESC)  AS salary_rank,
    DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC)  AS salary_dense_rank,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC)  AS row_number
FROM employees
ORDER BY department, salary DESC;

-- Filter to show only rank 8 in each department (from your tutorial)
SELECT *
FROM (
    SELECT
        first_name, email, department, salary,
        RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
    FROM employees
) ranked
WHERE rank = 8
ORDER BY department;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q05  NTILE() — bucketing into equal-size quantile groups
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Divide each department's employees into 5 salary brackets (quintiles)
 where bracket 1 = lowest paid 20%, bracket 5 = highest paid 20%.

 MENTAL MODEL:
   NTILE(n) divides the partition into n as-equal-as-possible buckets.
   With 11 rows and NTILE(5): first bucket gets 3 rows, rest get 2.
   Bucket 1 = bottom (lowest salary), Bucket 5 = top (highest salary) when
   ordered by salary ASC. Flip ORDER BY DESC to make 1 = highest.

 REAL-WORLD USE:
   Marketing: quartile customers by spend → target top 25% with VIP offers.
   Finance: decile income brackets for tax modelling.
   HR: salary bands, performance quartiles for compensation reviews.
*/

SELECT
    first_name,
    email,
    department,
    salary,
    NTILE(5) OVER (PARTITION BY department ORDER BY salary ASC)  AS salary_quintile
FROM employees
ORDER BY department, salary_quintile;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q06  FIRST_VALUE() and LAST_VALUE() — reference points within partition
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: For each employee, show the highest salary in their department
 (using FIRST_VALUE ordered DESC) alongside their own salary and the gap.

 MENTAL MODEL:
   FIRST_VALUE(col) OVER (PARTITION BY dept ORDER BY salary DESC)
   → returns the FIRST value encountered in the ordered window = max salary

   WARNING: LAST_VALUE without frame clause behaves oddly because the default
   frame is RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW.
   To get true last value: use ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

 CHEAT SHEET:
   FIRST_VALUE(col) OVER (PARTITION BY x ORDER BY y DESC)  → max in partition
   LAST_VALUE(col)  OVER (PARTITION BY x ORDER BY y DESC
     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) → min in partition

 REAL-WORLD USE: Gap-to-leader analysis in sales, price gap to best offer
 on e-commerce, performance gap to department top performer.
*/

SELECT
    first_name,
    department,
    salary,
    FIRST_VALUE(salary) OVER (
        PARTITION BY department ORDER BY salary DESC
    )                                                    AS dept_max_salary,
    salary - FIRST_VALUE(salary) OVER (
        PARTITION BY department ORDER BY salary DESC
    )                                                    AS gap_from_top_earner
FROM employees
ORDER BY department, salary DESC;

-- NTH_VALUE: Find the 6th salary value within each department
SELECT
    first_name,
    department,
    salary,
    NTH_VALUE(salary, 6) OVER (
        PARTITION BY department
        ORDER BY first_name
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )   AS sixth_salary_in_dept
FROM employees
ORDER BY department, first_name;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q07  Running totals — RANGE vs ROWS frames
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Show each employee's hire date and salary. Add:
   - running_total_global   : cumulative salary spend ordered by hire date
   - running_total_by_dept  : cumulative salary per department by hire date

 MENTAL MODEL:
   SUM() OVER (ORDER BY hire_date) → running total (default frame = RANGE UNBOUNDED PRECEDING)
   RANGE uses value-based boundaries; ROWS uses physical row count boundaries.

   For running totals: ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW is the safe,
   explicit, unambiguous form. Use it always.

   RANGE BETWEEN: if two rows have same hire_date, RANGE includes all tied rows
   simultaneously (so running total jumps by all tied salaries at once).
   ROWS BETWEEN: strictly physical — one row at a time regardless of ties.

 REAL-WORLD USE: Monthly cumulative revenue (MRR), budget burn tracking,
 cumulative active user counts, financial statement YTD totals.
*/

SELECT
    ROW_NUMBER() OVER () AS row_no,
    first_name,
    hire_date,
    salary,
    SUM(salary) OVER (
        ORDER BY hire_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                    AS running_total_global,

    SUM(salary) OVER (
        PARTITION BY department
        ORDER BY hire_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                    AS running_total_by_dept
FROM employees
ORDER BY hire_date;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q08  Rolling window — N-row moving average
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Calculate a 4-row rolling sum of salaries ordered by hire date
 (current row + 3 preceding rows). This simulates a moving average window.

 MENTAL MODEL:
   ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
   → window always contains at most 4 rows (current + 3 before it)
   → at the start of the dataset, fewer rows exist, so sum is smaller

 REAL-WORLD USE: 7-day rolling revenue (sum of last 7 days of sales),
 moving average stock prices, smoothing noisy time series data.
*/

SELECT
    first_name,
    hire_date,
    salary,
    SUM(salary) OVER (
        ORDER BY hire_date
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    )   AS rolling_4row_salary_sum,

    ROUND(AVG(salary) OVER (
        ORDER BY hire_date
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ), 0)   AS rolling_4row_salary_avg
FROM employees
ORDER BY hire_date;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q09  LEAD() and LAG() — time-series comparison
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: For each employee ordered by salary DESC:
   - Show the salary of the NEXT lower-paid person (LEAD)
   - Show the salary of the NEXT higher-paid person (LAG)
   - Calculate the gap between adjacent salaries

 Then, within each department, show each person's salary and the next
 lower salary in the same department.

 MENTAL MODEL:
   LAG(col, n, default)  → look n rows BACK (previous rows)
   LEAD(col, n, default) → look n rows AHEAD (next rows)

   With ORDER BY salary DESC:
   LAG(salary)  → next higher salary (previous row has higher salary)
   LEAD(salary) → next lower salary (next row has lower salary)

 CHEAT SHEET:
   LAG(salary) OVER (ORDER BY salary DESC)  → the salary above this row
   LEAD(salary) OVER (ORDER BY salary DESC) → the salary below this row
   LAG(salary, 2) → 2 rows back
   LAG(salary, 1, 0) → 1 row back, default 0 if no prior row exists

 REAL-WORLD USE: Month-over-month revenue change, day-over-day active users,
 comparing current vs previous period metrics — the foundation of growth analytics.
*/

-- Global order by salary
SELECT
    first_name,
    last_name,
    salary,
    LAG(salary)  OVER (ORDER BY salary DESC)  AS next_higher_salary,
    LEAD(salary) OVER (ORDER BY salary DESC)  AS next_lower_salary,
    salary - LEAD(salary) OVER (ORDER BY salary DESC)  AS gap_to_next_lower
FROM employees
ORDER BY salary DESC;

-- Within-department order
SELECT
    first_name,
    last_name,
    department,
    salary,
    LEAD(salary) OVER (
        PARTITION BY department
        ORDER BY salary DESC
    )   AS next_lower_in_dept
FROM employees
ORDER BY department, salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q10  FIRST_VALUE / EXCEPT verification — professional technique
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Verify that FIRST_VALUE(salary) OVER (PARTITION BY dept ORDER BY salary DESC)
 returns exactly the same result as MAX(salary) OVER (PARTITION BY dept).
 Use EXCEPT to prove they differ for any row (should return 0 rows if identical).

 MENTAL MODEL:
   EXCEPT returns rows in the first query that are NOT in the second.
   If they are mathematically equivalent, no rows are returned.
   This is a professional data quality verification technique.
*/

SELECT first_name, email, department, salary,
    FIRST_VALUE(salary) OVER (PARTITION BY department ORDER BY salary DESC) AS first_val
FROM employees

EXCEPT

SELECT first_name, email, department, salary,
    MAX(salary) OVER (PARTITION BY department ORDER BY salary DESC) AS first_val
FROM employees;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q11  Top-N per group — filtering inside window functions
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find the top 3 highest-paid employees in EACH department.
 Handle ties with DENSE_RANK so no employee is unfairly excluded.

 MENTAL MODEL:
   You CANNOT use WHERE on a window function directly — it doesn't exist yet
   at the WHERE phase. You must wrap in a subquery or CTE first:
   Step 1: Compute DENSE_RANK() inside CTE.
   Step 2: Filter WHERE dense_rank <= 3 in the outer query.

 PROFESSIONAL PATTERN (memorise this):
   WITH ranked AS (
       SELECT *, DENSE_RANK() OVER (PARTITION BY x ORDER BY y DESC) AS rk
       FROM table
   )
   SELECT * FROM ranked WHERE rk <= 3;

 REAL-WORLD USE: Top 3 products per category (Amazon recommendations),
 top 5 customers per region (sales territory planning),
 top performers per team (quarterly review automation).
*/

WITH salary_ranked AS (
    SELECT
        employee_id,
        first_name,
        last_name,
        department,
        salary,
        DENSE_RANK() OVER (
            PARTITION BY department
            ORDER BY salary DESC
        )   AS salary_rank
    FROM employees
)
SELECT
    department,
    salary_rank,
    first_name,
    last_name,
    salary
FROM salary_ranked
WHERE salary_rank <= 3
ORDER BY department, salary_rank;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q12  Percent rank and cumulative distribution
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: For each employee, calculate where their salary stands within the
 company using PERCENT_RANK and CUME_DIST. Identify those in the top 10%.

 MENTAL MODEL:
   PERCENT_RANK() = (rank - 1) / (total_rows - 1)  → 0.0 to 1.0
   CUME_DIST()    = rows_with_value_le / total_rows → fraction of rows at or below

   An employee with PERCENT_RANK = 0.9 is in the 90th percentile (top 10%).

 REAL-WORLD USE: Statistical salary benchmarking, performance percentile
 scoring, risk quantile assignment in finance.
*/

SELECT
    first_name,
    department,
    salary,
    ROUND(PERCENT_RANK() OVER (ORDER BY salary), 4)     AS company_percentile,
    ROUND(CUME_DIST()    OVER (ORDER BY salary), 4)     AS cumulative_distribution,
    ROUND(PERCENT_RANK() OVER (
        PARTITION BY department ORDER BY salary
    ), 4)                                               AS dept_percentile
FROM employees
ORDER BY salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q13  Salary gap to department average using window + CTE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: For each employee, show their salary, their department average
 salary, and their gap (above or below average). Flag above-average employees.

 MENTAL MODEL: This replaces the correlated subquery from your tutorial.
 The window function AVG(salary) OVER (PARTITION BY department) computes the
 department average once per partition, not once per row.

 REAL-WORLD USE: Compensation equity analysis, market benchmarking, identifying
 outliers in a department for budget reallocation.
*/

WITH dept_avg AS (
    SELECT
        employee_id,
        first_name,
        department,
        salary,
        ROUND(AVG(salary) OVER (PARTITION BY department), 0) AS dept_avg_salary
    FROM employees
)
SELECT
    employee_id,
    first_name,
    department,
    salary,
    dept_avg_salary,
    salary - dept_avg_salary                     AS gap_from_dept_avg,
    CASE
        WHEN salary > dept_avg_salary THEN 'ABOVE AVG'
        WHEN salary < dept_avg_salary THEN 'BELOW AVG'
        ELSE 'AT AVG'
    END                                          AS vs_dept_avg
FROM dept_avg
ORDER BY department, salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q14  Period-over-period comparison using LAG (MoM / YoY)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Build a hiring trend report showing hires per year and the
 change vs prior year (year-over-year growth).

 MENTAL MODEL:
   Step 1: GROUP BY year to get annual hire count.
   Step 2: Apply LAG(count, 1) in a CTE to get prior year count.
   Step 3: Compute YoY change and percentage.

 REAL-WORLD USE: YoY revenue growth (every financial report in existence),
 MoM active user growth (product dashboards), WoW conversion rate change.
*/

WITH annual_hires AS (
    SELECT
        EXTRACT(YEAR FROM hire_date)   AS hire_year,
        COUNT(*)                       AS total_hires
    FROM employees
    GROUP BY EXTRACT(YEAR FROM hire_date)
),
yoy_growth AS (
    SELECT
        hire_year,
        total_hires,
        LAG(total_hires) OVER (ORDER BY hire_year)   AS prev_year_hires
    FROM annual_hires
)
SELECT
    hire_year,
    total_hires,
    prev_year_hires,
    total_hires - prev_year_hires                    AS yoy_change,
    ROUND(
        100.0 * (total_hires - prev_year_hires)
             / NULLIF(prev_year_hires, 0),
        1
    )                                                AS yoy_pct_change
FROM yoy_growth
ORDER BY hire_year;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q15  Full window function showcase — executive scorecard
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Build a comprehensive employee scorecard combining all key window
 functions in a single query — this is a real analytics engineering output.

 Columns:
   - employee_id, full_name, department, hire_date, salary
   - dept_salary_rank      : rank within department by salary
   - dept_salary_quintile  : which 20% bracket in department
   - dept_avg_salary       : department average
   - salary_vs_dept_avg    : gap
   - company_percentile    : salary percentile in whole company
   - running_payroll       : cumulative payroll by hire date
   - prior_hire_salary     : salary of the employee hired just before (LAG)

 REAL-WORLD USE: This is the kind of query a senior analytics engineer builds
 for a CEO compensation dashboard. It replaces 6 separate queries.
*/

SELECT
    employee_id,
    first_name || ' ' || last_name                               AS full_name,
    department,
    hire_date,
    salary,

    DENSE_RANK() OVER (
        PARTITION BY department ORDER BY salary DESC
    )                                                            AS dept_salary_rank,

    NTILE(5) OVER (
        PARTITION BY department ORDER BY salary ASC
    )                                                            AS dept_salary_quintile,

    ROUND(AVG(salary) OVER (PARTITION BY department), 0)        AS dept_avg_salary,

    salary - ROUND(AVG(salary) OVER (PARTITION BY department), 0)
                                                                 AS salary_vs_dept_avg,

    ROUND(PERCENT_RANK() OVER (ORDER BY salary), 4)             AS company_percentile,

    SUM(salary) OVER (
        ORDER BY hire_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                            AS cumulative_payroll,

    LAG(salary) OVER (ORDER BY hire_date)                       AS prior_hire_salary
FROM employees
ORDER BY department, salary DESC;
