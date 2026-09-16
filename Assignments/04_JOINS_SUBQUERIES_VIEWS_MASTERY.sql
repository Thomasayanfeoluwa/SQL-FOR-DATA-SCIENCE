/*
================================================================================
 MODULE 04 — JOINS, SET OPERATIONS, SUBQUERIES & VIEWS
 As a Data Scientist / Analytics Engineer
================================================================================

 JOIN TYPES:
   INNER JOIN      → only matching rows from both tables
   LEFT JOIN       → all left rows + matching right; NULL where no match
   RIGHT JOIN      → all right rows + matching left; NULL where no match
   FULL OUTER JOIN → all rows from both; NULL where no match on either side
   CROSS JOIN      → Cartesian product (every row × every row)
   SELF JOIN       → table joined to itself

 SET OPERATIONS:
   UNION     → combines results, removes duplicates
   UNION ALL → combines results, keeps duplicates (faster)
   EXCEPT    → rows in first query NOT in second (set difference)
   INTERSECT → rows in BOTH queries

 ANTI-JOIN PATTERNS:
   LEFT JOIN ... WHERE right_key IS NULL
   NOT EXISTS (subquery)
   NOT IN (subquery) — AVOID on nullable columns

================================================================================
*/

SET search_path TO public;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q01  INNER JOIN — the default join, only matching rows
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: As a data scientist building a regional analytics dashboard,
 join employees to regions to show each employee's name, department,
 hire date, and their country.

 MENTAL MODEL:
   INNER JOIN = "only show rows where the condition is satisfied in BOTH tables"
   It's a FILTER — rows without a match in either table are silently dropped.
   Always verify: do all employees have a valid region_id? Use LEFT JOIN if unsure.

 CHEAT SHEET:
   SELECT a.col, b.col
   FROM tableA a
   INNER JOIN tableB b ON a.key = b.key;

 ELEMENTARY vs PROFESSIONAL:
   ✗ Old-style implicit join: FROM employees e, regions r WHERE e.region_id = r.region_id
   ✓ Explicit INNER JOIN syntax — readable, maintainable, industry standard

 REAL-WORLD USE: Virtually every analytics query joins at least two tables.
 At Uber, the core trip analytics joins trips→drivers→vehicles→locations.
*/

-- Old style (implicit) — from your tutorial, recognise and avoid
SELECT e.department
FROM employees AS e, departments AS d;   -- WARNING: CROSS JOIN without WHERE = bug!

-- Professional explicit INNER JOIN
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.department,
    e.hire_date,
    r.region,
    r.country
FROM employees e
INNER JOIN regions r ON e.region_id = r.region_id
ORDER BY r.country, e.department;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q02  Three-table JOIN — employees + regions + departments
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Build a complete employee profile joining all three core tables.
 Show: employee name, department, division (from departments), region, country.

 MENTAL MODEL: Chain joins left to right. Each new JOIN adds columns from
 another table. Think of it as SQL building one wide row step by step.

   employees → JOIN regions → JOIN departments

 Always alias tables (e, r, d) to avoid ambiguity when column names repeat
 across tables (like 'department' in both employees and departments).
*/

SELECT
    e.first_name,
    e.last_name,
    e.department,
    d.division,
    r.region,
    r.country,
    e.salary
FROM employees e
INNER JOIN departments d ON e.department  = d.department
INNER JOIN regions     r ON e.region_id   = r.region_id
ORDER BY r.country, d.division, e.department;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q03  JOIN + subquery in WHERE — earliest hire date by country
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find the first employee ever hired (globally). Show their name,
 department, hire date, and country.

 MENTAL MODEL:
   The subquery computes MIN(hire_date) once across the whole table.
   The outer JOIN + WHERE then filters to just that date.
   This is a non-correlated scalar subquery — very efficient.

 PROFESSIONAL VERSION: Use MIN() as a window function or CTE to avoid
 re-scanning the table inside a scalar subquery.
*/

-- From your tutorial — elegant approach
SELECT e.first_name, e.department, e.hire_date, r.country
FROM employees e
INNER JOIN regions r ON e.region_id = r.region_id
WHERE e.hire_date = (SELECT MIN(hire_date) FROM employees);

-- Bonus: First AND last hire in one query using UNION
SELECT e.first_name, e.department, e.hire_date, r.country, 'FIRST HIRE' AS label
FROM employees e
INNER JOIN regions r ON e.region_id = r.region_id
WHERE e.hire_date = (SELECT MIN(hire_date) FROM employees)

UNION

SELECT e.first_name, e.department, e.hire_date, r.country, 'LATEST HIRE' AS label
FROM employees e
INNER JOIN regions r ON e.region_id = r.region_id
WHERE e.hire_date = (SELECT MAX(hire_date) FROM employees)

ORDER BY hire_date;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q04  LEFT JOIN — preserving all left rows (the full roster)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Show ALL students and any courses they may or may not be taking.
 Students with no enrollment should appear with NULL course info.

 MENTAL MODEL:
   INNER JOIN: student with no enrollment → DISAPPEARS (silently lost!)
   LEFT JOIN:  student with no enrollment → STAYS, course columns = NULL

   Think LEFT JOIN as: "show me everything from the left, fill in right if matched"

 CHEAT SHEET:
   FROM left_table
   LEFT JOIN right_table ON left.key = right.key
   -- If right has no match, right columns return NULL

 REAL-WORLD USE: Customer activity reports (show ALL customers, including
 those who haven't purchased yet — churned customers).
*/

SET search_path TO course_data, public;

SELECT
    s.student_no,
    s.student_name,
    s.age,
    COALESCE(se.course_no,    'NOT ENROLLED')   AS course_no,
    COALESCE(c.course_title,  'N/A')             AS course_title,
    COALESCE(c.credits::text, '0')               AS credits
FROM students s
LEFT JOIN student_enrollment se ON s.student_no = se.student_no
LEFT JOIN courses c             ON se.course_no  = c.course_no
ORDER BY s.student_no, se.course_no;

SET search_path TO public;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q05  Anti-join pattern — departments with ZERO employees
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find departments that exist in the departments table but have
 NO employees assigned to them.

 MENTAL MODEL — THE THREE ANTI-JOIN PATTERNS:
   Pattern 1: LEFT JOIN ... WHERE right.key IS NULL
   Pattern 2: NOT EXISTS (SELECT 1 FROM right WHERE right.key = left.key)
   Pattern 3: NOT IN (SELECT key FROM right) — AVOID if right can have NULLs!

 ELEMENTARY vs PROFESSIONAL:
   ✗ NOT IN — breaks silently when subquery returns a NULL
   ✓ NOT EXISTS or LEFT JOIN anti-join — NULL-safe and optimizer-friendly

 REAL-WORLD USE: Finding orphaned records, detecting unused product
 categories, identifying empty customer segments.
*/

-- Pattern 1: LEFT JOIN Anti-join (recommended)
SELECT d.department, d.division
FROM departments d
LEFT JOIN employees e ON d.department = e.department
WHERE e.employee_id IS NULL;

-- Pattern 2: NOT EXISTS (also recommended — often fastest)
SELECT d.department, d.division
FROM departments d
WHERE NOT EXISTS (
    SELECT 1
    FROM employees e
    WHERE e.department = d.department
);

-- Proof of what employees table has that departments doesn't (EXCEPT)
SELECT DISTINCT department FROM employees
EXCEPT
SELECT department FROM departments;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q06  CROSS JOIN — Cartesian product (understand and avoid accidentally)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Demonstrate what a Cartesian product produces, verify the row
 count, and show the ONE legitimate use case (combination matrix).

 MENTAL MODEL:
   CROSS JOIN produces (rows in A) × (rows in B) = total rows.
   employees has ~356 rows, departments has ~28 rows:
   → 356 × 28 = 9,968 rows output
   This is almost never what you want in production!

   Legitimate use: combination matrix (e.g., all date × product combinations
   for a "fill-in-zeros" time series).

 REAL-WORLD USE: Generating all possible date-product or city-product
 combinations for time series with zero-filling before a LEFT JOIN.
*/

-- Verify count (do NOT use this output blindly)
SELECT COUNT(*)
FROM (
    SELECT * FROM employees CROSS JOIN departments
) AS cartesian_result;

-- Explicit CROSS JOIN syntax
SELECT e.first_name, d.department AS dept_from_dept_table
FROM employees e
CROSS JOIN departments d
LIMIT 20;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q07  UNION vs UNION ALL — combining result sets
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Build a master list of all unique department names from BOTH the
 employees table and the departments table. Then show what UNION ALL returns.

 MENTAL MODEL:
   UNION     → stacks results + deduplicates (sorts first, expensive)
   UNION ALL → stacks results WITHOUT deduplication (faster, preserves dupes)

   Rules:
   1. Both queries must return the SAME number of columns
   2. Corresponding columns must have compatible data types
   3. Column names come from the FIRST query

 CHEAT SHEET:
   query1 UNION     query2  → deduplicated rows
   query1 UNION ALL query2  → all rows including duplicates
   query1 EXCEPT    query2  → rows in query1 not in query2
   query1 INTERSECT query2  → rows in both

 REAL-WORLD USE:
   UNION: Building master lookup tables from multiple source systems.
   UNION ALL: Combining partitioned tables (monthly shards) into one result.
   EXCEPT: Finding new records since last sync (delta detection).
*/

-- UNION — unique departments from both sources
SELECT department FROM employees
UNION
SELECT department FROM departments
ORDER BY department;

-- UNION ALL — includes duplicates (larger result set)
SELECT department FROM employees
UNION ALL
SELECT department FROM departments
ORDER BY department
LIMIT 20;

-- EXCEPT — departments in employees NOT in department master table
SELECT DISTINCT department FROM employees
EXCEPT
SELECT department FROM departments;

-- Bonus: Headcount per department + grand total row using UNION ALL
SELECT department, COUNT(*) AS headcount
FROM employees
GROUP BY department
UNION ALL
SELECT 'COMPANY TOTAL', COUNT(*)
FROM employees
ORDER BY headcount DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q08  Subquery in WHERE — IN and NOT IN with subqueries
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find all employees who work in departments that belong to the
 'Kids' division.

 MENTAL MODEL:
   Step 1: Find department names where division = 'Kids' (inner query)
   Step 2: Find employees where department IN (that list) (outer query)
   The inner query runs ONCE and its result is used as a filter.

 ELEMENTARY vs PROFESSIONAL:
   ✗ Hardcode department names IN ('Children Clothing', 'Toys')
      → breaks when divisions change
   ✓ IN (subquery) → dynamic, adapts to data changes

 REAL-WORLD USE: Dynamic segment filters that pull their criteria from
 a configuration table — no hardcoding required.
*/

SELECT employee_id, first_name, department, salary
FROM employees
WHERE department IN (
    SELECT department
    FROM departments
    WHERE division = 'Kids'
)
ORDER BY department;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q09  ANY and ALL — quantified subqueries
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find employees in the Kids division departments who were hired
 AFTER every single employee in the Maintenance department (i.e., newer
 than the most recent Maintenance hire).

 MENTAL MODEL:
   > ANY (subquery)   → greater than at least ONE value in set (= > MIN)
   > ALL (subquery)   → greater than EVERY value in set (= > MAX)
   = ANY (subquery)   → equivalent to IN (subquery)
   <> ALL (subquery)  → equivalent to NOT IN (subquery)

 CHEAT SHEET:
   col > ANY(...)  → col > MIN(subquery)
   col > ALL(...)  → col > MAX(subquery)
   col = ANY(...)  → same as IN(...)

 REAL-WORLD USE: "Find users who rated more highly than ANY competitor
 user" or "customers who spent more than ALL of last month's top buyers".
*/

-- Employees in Kids division hired after ALL Maintenance employees
SELECT employee_id, first_name, department, hire_date
FROM employees
WHERE department = ANY (
    SELECT department FROM departments WHERE division = 'Kids'
)
AND hire_date > ALL (
    SELECT hire_date FROM employees WHERE department = 'Maintenance'
)
ORDER BY hire_date;

-- Region filter: employees in regions > ANY West Africa region_id
SELECT first_name, department, region_id
FROM employees
WHERE region_id > ANY (
    SELECT region_id FROM regions WHERE country = 'West Africa'
)
ORDER BY region_id;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q10  FROM subquery — derived table (inline view)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: From the category breakdown (UNDER PAID / PAID WELL / EXECUTIVE),
 count how many employees fall in each category.

 MENTAL MODEL:
   A FROM subquery treats the inner query's result as a temporary table.
   Step 1: Inner query labels each row with a category
   Step 2: Outer query groups and counts those labels

 ELEMENTARY vs PROFESSIONAL:
   ✗ FROM subquery (readable but may not be reusable)
   ✓ CTE (WITH clause) — same plan, but reusable and named

 REAL-WORLD USE: Multi-step transformations — first classify, then aggregate.
 Used in every analytics pipeline: assign cohort → count cohort → report.
*/

-- From subquery pattern (from your tutorial)
SELECT
    category,
    COUNT(*)    AS employee_count
FROM (
    SELECT
        first_name,
        salary,
        CASE
            WHEN salary < 100000                        THEN 'UNDER PAID'
            WHEN salary BETWEEN 100000 AND 160000       THEN 'PAID WELL'
            WHEN salary > 160000                        THEN 'EXECUTIVE'
            ELSE 'UNPAID'
        END AS category
    FROM employees
) AS salary_categorised
GROUP BY category
ORDER BY employee_count DESC;

-- Professional CTE version (same plan, more readable)
WITH salary_categorised AS (
    SELECT
        first_name,
        salary,
        CASE
            WHEN salary < 100000                        THEN 'UNDER PAID'
            WHEN salary BETWEEN 100000 AND 160000       THEN 'PAID WELL'
            WHEN salary > 160000                        THEN 'EXECUTIVE'
            ELSE 'UNPAID'
        END AS category
    FROM employees
)
SELECT category, COUNT(*) AS employee_count
FROM salary_categorised
GROUP BY category
ORDER BY employee_count DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q11  Correlated subquery — above-average salary per department
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find employees whose salary is above the average salary for
 THEIR OWN department.

 MENTAL MODEL:
   Correlated subquery: the inner query references a column from the outer query.
   For each row in employees (e1), the inner query computes AVG(e2.salary)
   WHERE e2.department = e1.department.
   This executes N times (once per row in outer table) — O(N × M).

 PROFESSIONAL ALTERNATIVE: Window function (runs once).
   AVG(salary) OVER (PARTITION BY department)

 WHY MENTION BOTH: The correlated version reads like natural language and
 is excellent for learning. The window version is production-grade.
*/

-- Correlated subquery version (from your tutorial)
SELECT employee_id, first_name, department, salary
FROM employees e1
WHERE salary > (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.department = e1.department
)
ORDER BY department, salary DESC;

-- Professional window function version (preferred in production)
WITH dept_benchmarks AS (
    SELECT
        *,
        ROUND(AVG(salary) OVER (PARTITION BY department), 0) AS dept_avg
    FROM employees
)
SELECT
    employee_id, first_name, department, salary, dept_avg,
    salary - dept_avg   AS above_avg_by
FROM dept_benchmarks
WHERE salary > dept_avg
ORDER BY department, salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q12  Duplicate detection and deletion
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: The dupes table has duplicate name entries. Show the duplicates,
 then safely delete them keeping only the lowest id per name.

 MENTAL MODEL:
   Step 1: Find MIN(id) per name (the "keeper" row for each name)
   Step 2: DELETE WHERE id NOT IN (those keeper IDs)

   PROFESSIONAL ALTERNATIVE:
   Use ROW_NUMBER() OVER (PARTITION BY name ORDER BY id) — delete WHERE rn > 1.
   This is safer for complex deduplication keys.

 REAL-WORLD USE: Every data ingestion pipeline must handle duplicates.
 At Stripe, deduplication of payment events prevents double-charging customers.
*/

-- View duplicates
SELECT * FROM dupes ORDER BY name, id;

-- Show unique names (keep lowest id per name)
SELECT *
FROM dupes
WHERE id IN (
    SELECT MIN(id)
    FROM dupes
    GROUP BY name
);

-- Professional: using ROW_NUMBER (preview before delete)
SELECT id, name, rn
FROM (
    SELECT id, name, ROW_NUMBER() OVER (PARTITION BY name ORDER BY id) AS rn
    FROM dupes
) ranked
WHERE rn > 1;

-- Delete duplicates (keep lowest id)
DELETE FROM dupes
WHERE id NOT IN (
    SELECT MIN(id)
    FROM dupes
    GROUP BY name
);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q13  VIEWS — encapsulating complex logic
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Create a view called v_employee_information that joins employees,
 departments, and regions. Then query it like a table.

 MENTAL MODEL:
   A VIEW is a saved query — not a copy of data.
   Every time you SELECT from a view, the underlying query executes.
   Advantages: encapsulation, reusability, column-level security.

   MATERIALIZED VIEW = actually stores the result (updates via REFRESH).
   Use materialized views when the join is expensive and data freshness
   requirements allow it (e.g., refresh nightly).

 CHEAT SHEET:
   CREATE VIEW view_name AS SELECT ... FROM ... JOIN ...;
   CREATE OR REPLACE VIEW view_name AS ... -- update without dropping
   DROP VIEW view_name;

 REAL-WORLD USE: dbt (data build tool) heavily uses views and materialized
 views to build analytics layers in warehouses like Snowflake and BigQuery.
*/

CREATE OR REPLACE VIEW v_employee_information AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    COALESCE(e.email, 'no-email@company.com')  AS email,
    e.department,
    e.salary,
    d.division,
    r.region,
    r.country
FROM employees e
INNER JOIN departments d ON e.department  = d.department
INNER JOIN regions     r ON e.region_id   = r.region_id;

-- Query the view
SELECT * FROM v_employee_information ORDER BY country, department;

-- Aggregate from view (treating it like a table)
SELECT country, COUNT(*) AS headcount, ROUND(AVG(salary), 0) AS avg_salary
FROM v_employee_information
GROUP BY country
ORDER BY headcount DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q14  Multi-table join in the students schema — traversal chain
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Show each student's name, their enrolled courses, and the professor
 who teaches that course. Use the teach table as the bridge.

 TRAVERSAL CHAIN:
   students → student_enrollment → courses → teach → professors

 MENTAL MODEL:
   Draw the chain before writing code:
   students.student_no → student_enrollment.student_no  [1:M]
   student_enrollment.course_no → courses.course_no     [M:1]
   courses.course_no → teach.course_no                  [1:M]
   teach.last_name → professors.last_name               [M:1]

 The M:M between courses and professors via teach causes fan-out — one
 student/course pair becomes multiple rows (one per professor). See Q15.
*/

SET search_path TO course_data, public;

SELECT
    s.student_name,
    se.course_no,
    c.course_title,
    t.last_name    AS professor_teaching
FROM students s
INNER JOIN student_enrollment se ON s.student_no   = se.student_no
INNER JOIN courses c             ON se.course_no    = c.course_no
INNER JOIN teach t               ON c.course_no     = t.course_no
INNER JOIN professors p          ON t.last_name     = p.last_name
ORDER BY s.student_name, se.course_no, t.last_name;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q15  Eliminating fan-out — deduplicate without DISTINCT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: From Q14, you see student+course rows duplicating because multiple
 professors teach the same course. Show each student-course pair exactly ONCE,
 displaying the alphabetically first professor per course.

 HINT: Do NOT use DISTINCT — it cannot select "which" professor to keep.

 MENTAL MODEL:
   Problem: For course CS180, both Chong, Brown, and Wilson teach it.
   Joining produces 3 rows per student enrollment in CS180.
   Solution: Deduplicate in the teach table FIRST (pick MIN per course),
   then join to that deduplicated result.

 ELEMENTARY vs PROFESSIONAL:
   ✗ SELECT DISTINCT → picks arbitrarily, non-deterministic
   ✓ Subquery with MIN per course key → deterministic, controlled
   ✓ ROW_NUMBER() OVER (PARTITION BY course_no ORDER BY last_name) → best
*/

-- Professional: aggregate to pick one professor per course first
WITH primary_teacher AS (
    SELECT course_no, MIN(last_name) AS professor_name
    FROM teach
    GROUP BY course_no
)
SELECT
    s.student_name,
    se.course_no,
    c.course_title,
    pt.professor_name   AS lead_professor
FROM students s
INNER JOIN student_enrollment se ON s.student_no  = se.student_no
INNER JOIN courses c             ON se.course_no   = c.course_no
INNER JOIN primary_teacher pt    ON c.course_no    = pt.course_no
ORDER BY s.student_name, se.course_no;

SET search_path TO public;
