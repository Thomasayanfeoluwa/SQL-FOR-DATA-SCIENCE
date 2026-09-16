/*
================================================================================
 MODULE 03 — AGGREGATE FUNCTIONS, GROUP BY & HAVING
 As a Data Scientist / Analytics Engineer
================================================================================

 AGGREGATE FUNCTIONS:
   COUNT(*)   COUNT(col)   SUM()   AVG()   MIN()   MAX()   ROUND()

 EXECUTION ORDER REMINDER:
   FROM → WHERE (filter rows) → GROUP BY → HAVING (filter groups)
   → SELECT (compute aggregates) → ORDER BY → LIMIT

 KEY RULE: If SELECT contains an aggregate AND a non-aggregate column,
 that non-aggregate column MUST appear in GROUP BY. No exceptions.

 SCHEMA: public.employees, public.departments, public.regions

================================================================================
*/

SET search_path TO public;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q01  Global aggregates — company-wide metrics
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: As a People Analytics data scientist, build a single-row
 company-wide compensation summary showing:
   - total headcount
   - total headcount with email on file
   - minimum salary
   - maximum salary
   - average salary (rounded to 2 decimal places)
   - total payroll

 MENTAL MODEL:
   COUNT(*) counts ALL rows including NULLs.
   COUNT(col) counts only rows where col IS NOT NULL.
   This distinction matters — COUNT(*) = total employees,
   COUNT(email) = employees with email addresses. The difference = missing data.

 CHEAT SHEET:
   COUNT(*)        → all rows
   COUNT(col)      → non-null rows for that column
   SUM(col)        → total; returns NULL if all values are NULL
   AVG(col)        → ignores NULLs in calculation
   ROUND(n, d)     → round to d decimal places

 REAL-WORLD USE: Executive KPI dashboard first-row summary cards in Tableau
 or Looker (the big numbers at the top of a dashboard).
*/

SELECT
    COUNT(*)                        AS total_employees,
    COUNT(email)                    AS employees_with_email,
    COUNT(*) - COUNT(email)         AS employees_missing_email,
    MIN(salary)                     AS min_salary,
    MAX(salary)                     AS max_salary,
    ROUND(AVG(salary), 2)           AS avg_salary,
    SUM(salary)                     AS total_annual_payroll
FROM employees;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q02  GROUP BY single column — department salary profiling
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Build a department-level compensation profile. For each department,
 show: headcount, min salary, avg salary, max salary, total payroll.
 Sort by headcount descending.

 MENTAL MODEL:
   Think of GROUP BY as creating "buckets" — one bucket per unique department.
   The aggregation functions (SUM, AVG, etc.) operate INSIDE each bucket.

 ELEMENTARY vs PROFESSIONAL:
   ✗ SELECT SUM(salary) FROM employees GROUP BY department;
      → returns sum but without the department name (useless!)
   ✓ SELECT department, SUM(salary) → always include the GROUP BY key in SELECT

 REAL-WORLD USE: Department budget planning, compensation band analysis,
 org structure analytics — the bread and butter of People Analytics.
*/

SELECT
    department,
    COUNT(*)                        AS headcount,
    MIN(salary)                     AS min_salary,
    ROUND(AVG(salary), 0)           AS avg_salary,
    MAX(salary)                     AS max_salary,
    SUM(salary)                     AS total_payroll
FROM employees
GROUP BY department
ORDER BY headcount DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q03  Pre-filter with WHERE then GROUP — budget analysis for specific regions
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Finance only wants to see departments in regions 3, 5, and 7.
 For those, show total salary spend per department.

 MENTAL MODEL:
   WHERE filters BEFORE the GROUP BY buckets are formed.
   Only rows matching WHERE participate in the aggregation.
   This is fundamentally different from HAVING (which filters AFTER).

 CHEAT SHEET:
   WHERE = filter individual rows BEFORE grouping
   HAVING = filter groups AFTER grouping
   Use WHERE whenever you can — it's more efficient because it reduces the
   data fed into the GROUP BY engine.
*/

SELECT
    department,
    SUM(salary)          AS dept_payroll_for_selected_regions
FROM employees
WHERE region_id IN (3, 5, 7)
GROUP BY department
ORDER BY dept_payroll_for_selected_regions DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q04  GROUP BY multiple columns — gender/department breakdown
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: D&I (Diversity & Inclusion) analysis — for every combination of
 department and gender, show headcount, min salary, and avg salary.
 Order by department, then gender.

 MENTAL MODEL:
   GROUP BY department, gender creates one bucket for every UNIQUE PAIR.
   Sports+F is a separate bucket from Sports+M.
   Every column in SELECT that is NOT an aggregate must be in GROUP BY.

 REAL-WORLD USE: Glassdoor gender pay gap analysis, EEOC compliance reports,
 D&I dashboards at Fortune 500 companies.
*/

SELECT
    department,
    gender,
    COUNT(*)                        AS headcount,
    MIN(salary)                     AS min_salary,
    ROUND(AVG(salary), 0)           AS avg_salary,
    MAX(salary)                     AS max_salary
FROM employees
GROUP BY department, gender
ORDER BY department, gender;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q05  HAVING — filtering groups after aggregation
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find only departments with more than 35 employees.
 Show their headcount and average salary.

 MENTAL MODEL:
   HAVING is WHERE for groups. It runs AFTER GROUP BY.
   You cannot write WHERE COUNT(*) > 35 because COUNT doesn't exist yet
   when WHERE executes. HAVING is the only place for aggregate conditions.

 CHEAT SHEET:
   GROUP BY department
   HAVING COUNT(*) > 35           → keep only groups with 36+ members
   HAVING AVG(salary) > 100000    → keep groups with avg salary > 100k
   HAVING MAX(salary) = MIN(salary) → groups where everyone earns the same

 REAL-WORLD USE: Identifying significant product categories (only show
 categories with > 100 products), filtering small sample sizes out of
 statistical analyses.
*/

SELECT
    department,
    COUNT(*)                AS headcount,
    ROUND(AVG(salary), 0)  AS avg_salary,
    SUM(salary)             AS total_payroll
FROM employees
GROUP BY department
HAVING COUNT(*) > 35
ORDER BY headcount DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q06  WHERE + GROUP BY + HAVING — three-layer pipeline
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Among employees earning over $75,000, find departments that have
 more than 10 such employees. Show sorted by headcount.

 MENTAL MODEL — THE PIPELINE:
   Step 1 (WHERE)  : Filter rows to salary > 75000
   Step 2 (GROUP BY): Bucket filtered rows by department
   Step 3 (HAVING) : Keep buckets with COUNT > 10
   Step 4 (SELECT) : Project department and the aggregates

 REAL-WORLD USE: High-value customer segment sizing — among customers spending
 > $500/month, which product categories have > 1000 such customers?
*/

SELECT
    department,
    COUNT(*)                AS high_earner_count,
    ROUND(AVG(salary), 0)  AS avg_salary_among_high_earners,
    MIN(salary)             AS min_salary
FROM employees
WHERE salary > 75000
GROUP BY department
HAVING COUNT(*) > 10
ORDER BY high_earner_count DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q07  Email domain frequency — GROUP BY on computed expression
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Analyse what email providers our employees use.
 Extract the domain from email and count per domain, sorted by most common.

 MENTAL MODEL:
   You can GROUP BY any expression — not just raw column names.
   GROUP BY SUBSTRING(email, POSITION('@' IN email) + 1)
   You can also define it as an alias and GROUP BY the alias.

 ELEMENTARY vs PROFESSIONAL:
   ✗ GROUP BY "Email Domain"  → using alias (works in some DBs, fragile)
   ✓ GROUP BY SUBSTRING(email, POSITION('@' IN email) + 1)  → explicit and portable

 REAL-WORLD USE: Market intelligence — which companies' employees use your
 platform? (corporate email domain = company identifier for B2B SaaS).
*/

SELECT
    SUBSTRING(email FROM POSITION('@' IN email) + 1)   AS email_domain,
    COUNT(*)                                            AS employee_count
FROM employees
WHERE email IS NOT NULL
GROUP BY SUBSTRING(email FROM POSITION('@' IN email) + 1)
ORDER BY employee_count DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q08  Duplicate first names — GROUP BY + HAVING pattern
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find first names that are shared by more than 2 employees.
 Return the name and count, sorted by count descending.

 MENTAL MODEL: GROUP BY groups all rows with the same first_name.
 HAVING COUNT(*) > 2 keeps only groups with 3+ employees sharing that name.

 REAL-WORLD USE: Detecting merge conflicts in MDM (Master Data Management),
 identifying non-unique identifier fields before using them as join keys.
*/

SELECT
    first_name,
    COUNT(*)    AS name_count
FROM employees
GROUP BY first_name
HAVING COUNT(*) > 2
ORDER BY name_count DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q09  Gender × Region salary matrix
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Create a compensation matrix by gender and region showing:
 min, max, rounded avg salary. Sort by gender, then region.

 MENTAL MODEL: GROUP BY two dimensions = a matrix / pivot-ready table.
 This is the precursor to transposition (Module covered in CASE section).

 REAL-WORLD USE: Regional compensation benchmarking for HR strategy,
 location-based salary band setting, geographic pay equity analysis.
*/

SELECT
    gender,
    region_id,
    MIN(salary)            AS min_salary,
    ROUND(AVG(salary), 0)  AS avg_salary,
    MAX(salary)            AS max_salary
FROM employees
GROUP BY gender, region_id
ORDER BY gender, region_id;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q10  Conditional aggregation — counting cohorts within a single GROUP BY
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: For each department, show:
   - total headcount
   - count of female employees
   - count of male employees
   - count of employees earning > 100k
   - count of employees with no email

 MENTAL MODEL:
   SUM(CASE WHEN condition THEN 1 ELSE 0 END) → count rows matching condition
   Equivalent but cleaner in PostgreSQL:
   COUNT(*) FILTER (WHERE condition)          → same result, more readable

 CHEAT SHEET:
   COUNT(*) FILTER (WHERE gender = 'F')          → female count
   SUM(CASE WHEN salary > 100000 THEN 1 ELSE 0 END)  → high earner count

 ELEMENTARY vs PROFESSIONAL:
   ✗ Multiple separate queries for each cohort
   ✓ Single query with conditional aggregation

 REAL-WORLD USE: Any multi-dimensional KPI table — users active on mobile vs
 desktop, paid vs free tier, by region. Single query, one scan, zero joins.
*/

SELECT
    department,
    COUNT(*)                                            AS total_headcount,
    COUNT(*) FILTER (WHERE gender = 'F')                AS female_count,
    COUNT(*) FILTER (WHERE gender = 'M')                AS male_count,
    COUNT(*) FILTER (WHERE salary > 100000)             AS high_earner_count,
    COUNT(*) FILTER (WHERE email IS NULL)               AS missing_email_count,
    ROUND(100.0 * COUNT(*) FILTER (WHERE gender = 'F')
          / NULLIF(COUNT(*), 0), 1)                     AS pct_female
FROM employees
GROUP BY department
ORDER BY total_headcount DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q11  Most common salary — MODE equivalent
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find the salary value that appears most frequently in the company.

 MENTAL MODEL:
   There is no MODE() aggregate in standard SQL.
   Pattern: GROUP BY salary, ORDER BY COUNT(*) DESC, LIMIT 1.
   Or use: MODE() WITHIN GROUP (ORDER BY salary) — PostgreSQL ordered-set aggregate.

 ELEMENTARY vs PROFESSIONAL:
   ✗ GROUP BY + ORDER BY + LIMIT 1  → simple but breaks on ties
   ✓ MODE() WITHIN GROUP             → PostgreSQL built-in, handles correctly

 REAL-WORLD USE: Finding the most common transaction amount (fraud signal),
 most common session duration, modal delivery time.
*/

-- Elementary approach
SELECT salary, COUNT(*) AS frequency
FROM employees
GROUP BY salary
ORDER BY frequency DESC, salary DESC
LIMIT 3;

-- Professional PostgreSQL approach
SELECT MODE() WITHIN GROUP (ORDER BY salary) AS modal_salary
FROM employees;

-- Also with ALL subquery pattern (from your tutorial):
SELECT salary
FROM employees
GROUP BY salary
HAVING COUNT(*) >= ALL (
    SELECT COUNT(*)
    FROM employees
    GROUP BY salary
)
ORDER BY salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q12  Trimmed mean — excluding outliers from AVG
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Calculate the average salary excluding the single highest and
 single lowest earner (to remove outliers from the mean).

 MENTAL MODEL: This is a classic data science pattern — the trimmed mean.
 In SQL: filter WHERE salary NOT IN (MIN, MAX) before averaging.
 Use subqueries to compute the boundary values first.

 REAL-WORLD USE: Statistical analysis of housing prices, financial
 benchmarking, any metric where outliers distort the central tendency.
*/

SELECT
    ROUND(AVG(salary), 2)     AS trimmed_avg_salary,
    COUNT(*)                   AS included_employee_count
FROM employees
WHERE salary NOT IN (
    (SELECT MIN(salary) FROM employees),
    (SELECT MAX(salary) FROM employees)
);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q13  Department salary distribution with percentages
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Show each department's headcount AND its percentage share of
 total company headcount.

 MENTAL MODEL:
   To compute percentage, you need the GROUP BY total (numerator) and
   the GRAND TOTAL (denominator). The denominator requires a subquery
   OR a window function SUM() OVER().

 ELEMENTARY vs PROFESSIONAL:
   ✗ Subquery in denominator (evaluated for every row)
   ✓ Window function SUM(COUNT(*)) OVER() (computed once)

 REAL-WORLD USE: Market share by segment, revenue contribution by product,
 headcount distribution for org charts.
*/

-- Elementary (subquery denominator)
SELECT
    department,
    COUNT(*)                                AS headcount,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM employees), 2)
                                            AS pct_of_company
FROM employees
GROUP BY department
ORDER BY headcount DESC;

-- Professional (window function — runs in one pass)
SELECT
    department,
    COUNT(*)                                                AS headcount,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    )                                                       AS pct_of_company
FROM employees
GROUP BY department
ORDER BY headcount DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q14  Cohort retention using GROUP BY + EXTRACT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: How many employees were hired each year? Which year had the
 highest number of hires? Show year, count, and cumulative hires to date.

 MENTAL MODEL:
   EXTRACT(YEAR FROM hire_date) → group by hire year
   Cumulative: use window SUM(COUNT(*)) OVER (ORDER BY year) — see Module 05.
   Simpler here: just GROUP BY year and ORDER BY year.

 REAL-WORLD USE: Headcount growth trend, recruiting pipeline analysis,
 Org chart capacity planning.
*/

SELECT
    EXTRACT(YEAR FROM hire_date)           AS hire_year,
    COUNT(*)                               AS hires_that_year,
    ROUND(AVG(salary), 0)                  AS avg_starting_salary
FROM employees
GROUP BY EXTRACT(YEAR FROM hire_date)
ORDER BY hire_year ASC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q15  GROUPING SETS, ROLLUP, CUBE — multi-level aggregation
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION (using the sales table): Build a hierarchical sales summary that
 shows units sold at the continent level, country level, city level, and a
 grand total — all in one query.

 MENTAL MODEL:
   GROUPING SETS → explicit list of grouping combinations
   ROLLUP        → hierarchical subtotals (continent → country → city → total)
   CUBE          → ALL possible combinations of the listed columns

   ROLLUP(a, b, c) = GROUPING SETS((a,b,c),(a,b),(a),())
   CUBE(a, b, c)   = all 8 subsets

 CHEAT SHEET:
   GROUP BY ROLLUP(continent, country, city)

 REAL-WORLD USE: OLAP drill-down reports (think Excel PivotTable in SQL),
 financial P&L statements with subtotals, sales hierarchy reporting.
*/

-- Raw data
SELECT * FROM sales ORDER BY continent, country, city;

-- ROLLUP: Hierarchical subtotals
SELECT
    continent,
    country,
    city,
    SUM(units_sold)    AS total_units
FROM sales
GROUP BY ROLLUP(continent, country, city)
ORDER BY continent NULLS LAST, country NULLS LAST, city NULLS LAST;

-- CUBE: All combinations
SELECT
    continent,
    country,
    city,
    SUM(units_sold)    AS total_units
FROM sales
GROUP BY CUBE(continent, country, city)
ORDER BY continent NULLS LAST, country NULLS LAST, city NULLS LAST;

-- GROUPING SETS: Explicit selective groupings
SELECT
    continent,
    country,
    city,
    SUM(units_sold)    AS total_units
FROM sales
GROUP BY GROUPING SETS(continent, country, city, ())
ORDER BY continent NULLS LAST, country NULLS LAST;
