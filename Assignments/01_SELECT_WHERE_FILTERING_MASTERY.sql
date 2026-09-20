-- ================================================================================
 -- MODULE 01 — SELECT, WHERE, FILTERING, ORDERING & PROFESSIONAL QUERY DESIGN
 -- As a Data Scientist at a technology company
-- ================================================================================
/*
 SCHEMA CONTEXT
 ─────────────────────────────────────────────────────────────────────────────
Table: employees
   employee_id | first_name | last_name | email | hire_date
   department  | gender     | salary    | region_id
Table: departments     → department (PK), division
Table: regions         → region_id (PK), region, country


 HOW SQL ACTUALLY EXECUTES (Logical Order — memorize this)
 ─────────────────────────────────────────────────────────────────────────────
   1. FROM   — identify and load source tables
   2. WHERE  — filter individual rows
   3. GROUP BY
   4. HAVING — filter groups
   5. SELECT — compute & project columns
   6. DISTINCT
   7. ORDER BY
   8. LIMIT / OFFSET


WHY THIS MATTERS: You write SELECT first, but it runs almost last.
This is why you CANNOT reference a SELECT alias inside a WHERE clause — the alias doesn't exist yet when WHERE executes.

================================================================================
*/

SET search_path TO public;

/*markdown
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q01  Basic projection — select specific columns, not SELECT *
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
MENTAL MODEL: Always be explicit with columns. SELECT * is a debugging tool,
 never a production query. It pulls all columns even if downstream only uses 3,
 wasting I/O and network bandwidth across millions of rows.

CHEAT SHEET:
   SELECT col1, col2 || ' ' || col3 AS alias  -- concatenation
   FROM table_name;

ELEMENTARY vs PROFESSIONAL:
   ✗ Elementary : SELECT * FROM employees
   ✓ Professional: SELECT explicit columns with aliases

REAL-WORLD USE: Every BI tool query (Tableau, Looker, Power BI) that feeds
 a dashboard selects only the columns the chart needs. At Google, a 1%
 improvement in query cost across 10M daily queries = massive infra savings.
*/
*/

 -- QUESTION: As a data scientist building a People Analytics dashboard,
 -- retrieve the employee ID, full name (first + last), department and salary of all employees.
 -- Alias the concatenated name as "full_name".

-- Elementary
SELECT employee_id,
    first_name || ' ' || last_name AS "Full Name",
    department,
    salary
FROM employees
ORDER BY salary DESC;

-- Professional
SELECT
    employee_id,
    first_name || ' ' || last_name  AS full_name,
    department,
    salary,
    gender,
    hire_date
FROM employees
ORDER BY department, salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q02  WHERE with AND/OR operator precedence — the silent bug
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
  MENTAL MODEL — THE AND/OR PRECEDENCE TRAP:
   AND binds tighter than OR, just like * binds tighter than + in arithmetic.
   Without parentheses:
     WHERE department = 'Beauty' AND region_id = 3 OR salary > 50000
   reads as:
     WHERE (department = 'Beauty' AND region_id = 3) OR (salary > 50000)
   — which returns ALL employees earning > 50k from ANY department. Bug!

       Always use parentheses to make intent explicit.
 
 CHEAT SHEET:
   WHERE condition_A AND (condition_B OR condition_C)
 
 REAL-WORLD USE: At Airbnb, a mis-parenthesised WHERE clause in a revenue
 report once caused a 40% revenue overcount for a full quarter. Precision
 here is non-negotiable.
*/

--QUESTION: Retrieve all employees in the Beauty department who are in region 3
--OR earn more than $50,000. Return their name, department, region_id, salary.

-- Buggy (missing parentheses — wrong intent)
SELECT first_name || ' ' || last_name AS "Full Name",
    department,
    region_id,
    salary
FROM employees
WHERE (department = 'Beauty' 
    AND region_id = 3 OR salary > 50000)

ORDER BY salary DESC;


-- Buggy (missing parentheses — wrong intent)
SELECT first_name, department, region_id, salary
FROM employees
WHERE department = 'Beauty'
    AND region_id = 3
    OR salary > 50000;

-- Correct (parentheses enforce intent)
SELECT first_name || ' ' || last_name AS "Full Name",
    department,
    region_id,
    salary
FROM employees
WHERE department = 'Beauty'
    AND  (region_id = 3 OR salary > 50000)
ORDER BY salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q03  Multi-condition gender & department filter
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
  MENTAL MODEL: Stack AND conditions from most-selective to least-selective.
 The query planner often evaluates them left to right — filtering on gender
 (50% of rows) first, then department (1/28th), then salary keeps the scan
 narrow at each step.
  REAL-WORLD USE: HR compliance reports, Diversity & Inclusion audits,
 EEOC government filings.
*/

-- QUESTION: HR needs a list of female employees in the Tools department who earn
 -- more than $100,000. Return their first name and email.

SELECT first_name, email
FROM employees
WHERE gender = 'F' 
    AND department = 'Tools'
    AND salary > 100000;
 


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q04  Combining OR groups — union of two business cases
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
  MENTAL MODEL: Two independent business cohorts joined with OR.
 Wrap each cohort in parentheses to keep them logically isolated.
*/

 --QUESTION: Finance wants employees earning more than $150,000 OR all male
 -- employees in Sports. Return first name, hire date, salary.
SELECT first_name,
    hire_date, salary
FROM employees
WHERE (salary > 150000)
    OR (gender = 'M'
    AND department = 'Sports'
    )
-- ORDER BY salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q05  Date range filtering with BETWEEN
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 MENTAL MODEL: BETWEEN is inclusive on both ends.
   BETWEEN '2002-01-01' AND '2004-01-01'
   is equivalent to:
   >= '2002-01-01' AND <= '2004-01-01'
  PROFESSIONAL NOTE: For timestamps, prefer:
   hire_date >= '2002-01-01' AND hire_date < '2004-01-02'
 to avoid edge cases with time components (e.g. 2004-01-01 23:59:59).
 REAL-WORLD USE: Cohort analysis — who joined during a specific growth phase?
 Uber uses hire-date cohorts to analyse which engineering hires correlate with
 highest retention at the 2-year mark.
*/

-- QUESTION: Find all employees hired between Jan 1 2003 and Jan 1 2004.
 -- Return first name and hire date, sorted by hire date ascending.
SELECT first_name,
    hire_date
FROM employees
WHERE hire_date BETWEEN '2002-01-01' AND '2004-01-01'
ORDER BY hire_date;

SELECT first_name, hire_date
FROM employees
WHERE hire_date >= '2002-01-01' AND hire_date <= '2004-01-01'
ORDER BY hire_date ASC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q06  IN vs multiple OR — readability and index usage
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*


   MENTAL MODEL:
   IN ('a','b','c') compiles to a hash set lookup — O(1) per row.
   Multiple ORs can disable certain index optimisations.
   Rule: Use IN when checking the SAME column against multiple values.
 ELEMENTARY vs PROFESSIONAL:
   ✗ WHERE dept = 'Sports' OR dept = 'Clothing' OR dept = 'Movies' ...
   ✓ WHERE dept IN ('Sports', 'Clothing', 'Movies', ...)
   REAL-WORLD USE: Product category filtering in e-commerce analytics, market
 basket analysis, customer segment filters in CRM reporting.
*/

--  QUESTION: Retrieve all employees who work in Sports, Clothing, Movies,
 -- Outdoors, Toys, or Tools departments.

 SELECT employee_id, first_name, department, salary
 FROM employees
 WHERE department IN ('Sports', 
    'Clothing',
    'Movies',
    'Outdoors',
    'Toys',
    'Tools'
    )
ORDER BY department, salary;

-- Elementary
SELECT * FROM employees
WHERE department = 'Sports' OR department = 'Clothing' OR department = 'Movies';


SELECT employee_id, first_name, department, salary
FROM employees
WHERE department IN ('Sports', 'Clothing', 'Movies', 'Outdoors', 'Toys', 'Tools')
ORDER BY department, salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q07  NOT IN — the NULL danger zone
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*

 MENTAL MODEL — THE NOT IN NULL TRAP:
   If the subquery or list passed to NOT IN contains even ONE NULL, the entire
   result is 0 rows. This is SQL three-valued logic (TRUE/FALSE/UNKNOWN).
   NULL IN any comparison returns UNKNOWN, and NOT UNKNOWN is still UNKNOWN.
 SAFE ALTERNATIVES:
   ✓ department <> 'Movies'            -- for single values
   ✓ NOT EXISTS (SELECT 1 ...)         -- for subqueries (NULL-safe)
   ✓ LEFT JOIN ... WHERE right IS NULL -- anti-join pattern
   REAL-WORLD USE: Exclusion lists in email marketing, suppressing users who
 opted out of a specific product tier.
*/

 -- QUESTION: Find employees whose department is NOT 'Movies'. Two approaches.
SELECT employee_id,
    first_name, department
FROM employees
WHERE department <> 'Movies'
ORDER BY department
LIMIT 1000 OFFSET 650;

SELECT employee_id,
    first_name, department
FROM employees
WHERE department NOT IN ('Movies') 


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q08  NULL handling — IS NULL vs IS NOT NULL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 MENTAL MODEL:
   NULL = NULL → FALSE (because NULL means "unknown", not a value).
   Always use IS NULL / IS NOT NULL, never = NULL or != NULL.

 REAL-WORLD USE: Data pipeline quality gates — before loading to a data
 warehouse (Snowflake, BigQuery), engineers run IS NULL checks on primary
 contact fields to flag incomplete records.
*/

-- QUESTION: As a data quality analyst, identify employees missing an email
-- address. Then find the count. The data team wants both lists.
SELECT department, COUNT(*) AS "Department with missing Email"
FROM employees
WHERE email IS NULL
GROUP BY department
ORDER BY "Department with missing Email" DESC

-- QUESTION: As a data quality analyst, identify employees missing an email
-- address. Then find the count. The data team wants both lists.
SELECT department, COUNT(*) AS "Department with Email"
FROM employees
WHERE email IS NOT NULL
GROUP BY department
ORDER BY "Department with Email" DESC

-- Employees with no email (data quality issue)
SELECT employee_id, first_name,
    last_name, department
FROM employees
WHERE email IS NULL
ORDER BY department;

-- Employees with no email (data quality issue)
SELECT employee_id, first_name,
    last_name, department
FROM employees
WHERE email IS NULL
ORDER BY department


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q09  Salary range with BETWEEN + salary bands
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
  MENTAL MODEL: Combine a salary BETWEEN range (quantitative filter) with a
 categorical AND condition. Always wrap compound OR blocks in parentheses.
*/

--  QUESTION: Finance needs all employees earning between $50,000 and $100,000
 -- AND male employees in the Automotive department. Return full profile.
 SELECT employee_id,
    first_name,
    last_name,
    email,
    hire_date,
    department,
    gender,
    salary,
    region_id
FROM employees
WHERE (salary BETWEEN 50000 AND 100000 
    AND gender = 'M'
    AND department = 'Automotive')
ORDER BY salary DESC;

SELECT
    employee_id,
    first_name,
    last_name,
    email,
    hire_date,
    department,
    gender,
    salary,
    region_id
FROM employees
WHERE salary BETWEEN 50000 AND 100000
  AND gender = 'M'
  AND department = 'Automotive'
ORDER BY salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q10  ORDER BY — single, multi-column, expression-based
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Produce a sorted employee roster:
   - Primary sort: department A→Z
   - Secondary sort: salary highest to lowest within each department
   - Tertiary sort: last name A→Z for salary ties

 MENTAL MODEL: ORDER BY accepts multiple comma-separated columns. Each column
 can have its own ASC (default) or DESC modifier independently.

 PROFESSIONAL NOTE: ORDER BY without LIMIT on billion-row tables forces a full
 sort — very expensive. In production pipelines, only sort when the consumer
 needs it (report, API pagination), never in intermediate CTEs.
*/

SELECT
    employee_id,
    first_name,
    last_name,
    department,
    salary
FROM employees
ORDER BY
    department   ASC,
    salary       DESC,
    last_name    ASC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q11  LIMIT + OFFSET — pagination pattern
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Build an API endpoint returning the top 5 highest-paid employees.
 Then show how to implement pagination (page 2, 5 rows per page).

 MENTAL MODEL:
   LIMIT N           → return first N rows
   LIMIT N OFFSET M  → skip M rows, return next N rows
   Page 1: OFFSET 0, Page 2: OFFSET 5, Page 3: OFFSET 10 → OFFSET = (page-1)*size

 PROFESSIONAL NOTE: OFFSET-based pagination degrades on large tables because
 the engine scans and discards OFFSET rows every time. Prefer keyset/cursor
 pagination in production:
   WHERE employee_id > :last_seen_id ORDER BY employee_id LIMIT N

 REAL-WORLD USE: REST API pagination for employee directories, product
 catalogues, transaction histories.
*/

-- Top 5 earners
SELECT employee_id, first_name, department, salary
FROM employees
ORDER BY salary DESC
LIMIT 5;

-- Page 2 (records 6-10)
SELECT employee_id, first_name, department, salary
FROM employees
ORDER BY salary DESC
LIMIT 5 OFFSET 5;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q12  DISTINCT — deduplication and when NOT to use it
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Get a sorted list of all unique departments. Then explain when
 DISTINCT is an anti-pattern.

 MENTAL MODEL:
   DISTINCT forces a full sort of the output — O(N log N).
   If you are using DISTINCT to "fix" duplicate rows caused by a JOIN, that is
   a design smell — fix the JOIN, don't paper over it with DISTINCT.
   Legitimate use: quick enumeration of unique categories.

 ELEMENTARY vs PROFESSIONAL:
   ✗ SELECT DISTINCT department FROM employees  -- full sort, can be slow
   ✓ SELECT department FROM employees GROUP BY department  -- same result,
       planner may use hash aggregation which is often faster
*/

-- Distinct departments (correct usage)
SELECT DISTINCT department AS unique_department
FROM employees
ORDER BY department;

-- Professional equivalent (GROUP BY — same result, often faster plan)
SELECT department
FROM employees
GROUP BY department
ORDER BY department;

-- Distinct departments with count (why GROUP BY wins — you can add aggregates)
SELECT department, COUNT(*) AS headcount
FROM employees
GROUP BY department
ORDER BY headcount DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q13  Column aliasing and computed columns
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Build an employee summary report with:
   - full_name = first_name + ' ' + last_name (proper casing)
   - department
   - annual_salary = salary (column rename for clarity)
   - is_high_earner = boolean flag: salary > 100000
   - days_since_hired = today minus hire_date

 MENTAL MODEL: Computed columns in SELECT project new derived values without
 touching the underlying table. These are extremely common in analytics layers
 (dbt, views, CTEs).
*/

SELECT
    INITCAP(first_name) || ' ' || INITCAP(last_name)   AS full_name,
    department,
    salary                                              AS annual_salary,
    (salary > 100000)                                   AS is_high_earner,
    (CURRENT_DATE - hire_date)                          AS days_since_hired,
    EXTRACT(YEAR FROM AGE(hire_date))                   AS years_of_service
FROM employees
ORDER BY years_of_service DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q14  LIKE pattern matching — text search without full-text index
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find all departments that contain the letters "oth" anywhere in the
 name. Then find departments that are exactly 4 characters long with "ol" in
 positions 2-3 (e.g. "Tools").

 MENTAL MODEL:
   %  → zero or more characters (wildcard)
   _  → exactly one character (positional wildcard)
   LIKE is case-sensitive in PostgreSQL by default.
   Use ILIKE for case-insensitive matching.

 CHEAT SHEET:
   LIKE '%oth%'   → contains "oth"
   LIKE 'T%'      → starts with T
   LIKE '%g'      → ends with g
   LIKE '__ol_'   → exactly 5 chars, positions 3-4 are "ol"

 REAL-WORLD USE: Search autocomplete, product name fuzzy matching, log
 pattern mining, email domain extraction.
*/

SELECT DISTINCT department
FROM employees
WHERE department LIKE '%oth%';

-- Positional wildcard
SELECT DISTINCT department
FROM employees
WHERE department LIKE '__ol_';

-- Case-insensitive with ILIKE
SELECT DISTINCT department
FROM employees
WHERE department ILIKE '%computer%';


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q15  Salary cohort filter — combining BETWEEN, AND, OR, parentheses
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Compensation team needs employees who are either:
   (a) Under age 25 with student_no between 3 and 5, or have student_no = 7,
       AND age <= 20
   OR
   (b) Over age 20 and student_no >= 5

 Translate this into the employees table context:
   (a) salary < 60000 with department in (region 3-5) OR region_id = 7
       AND salary <= 60000
   OR
   (b) salary > 80000 AND region_id >= 5

 MENTAL MODEL: Treat each OR branch as a separate business rule.
 Write each rule inside parentheses before combining with OR.
*/

SELECT
    employee_id,
    first_name,
    department,
    region_id,
    salary
FROM employees
WHERE (salary <= 60000
       AND (region_id BETWEEN 3 AND 5 OR region_id = 7))
   OR (salary > 80000 AND region_id >= 5)
ORDER BY region_id, salary;
