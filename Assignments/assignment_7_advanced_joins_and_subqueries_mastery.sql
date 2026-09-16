/*
====================================================================================================
           SQL FOR DATA SCIENCE & DATA ENGINEERING: PROFESSIONAL MASTERY CURRICULUM
                 MODULE: ADVANCED JOINS, GROUPING, SUBQUERIES & EXECUTION ENGINES
====================================================================================================

----------------------------------------------------------------------------------------------------
### 1. FOUNDATIONAL CHEAT SHEET & ARCHITECTURAL MENTAL FRAMEWORKS
----------------------------------------------------------------------------------------------------

1. Relational Cardinality & The "Fan-Out" Trap:
   - 1-to-1 : Clean match. Row counts remain identical.
   - 1-to-Many / Many-to-Many : Joining across non-unique keys multiplies rows (Cartesian product fan-out).
   - Golden Rule: Always check the granularity of the right table before joining! If right table has
     duplicate keys, aggregate or deduplicate before joining.

2. Query Execution Mechanics: Correlated vs Non-Correlated vs Window Functions:
   +-----------------------+---------------------+-------------------------+-----------------------+
   | Query Type            | Execution Strategy  | Algorithmic Complexity  | Engine Optimization   |
   +-----------------------+---------------------+-------------------------+-----------------------+
   | Non-Correlated Subquery| Executed ONCE       | O(N + M)                | Cached as temporary   |
   | Correlated Subquery   | Executed per ROW    | O(N * M) (Nested Loop)  | Often un-optimizable  |
   | JOIN + GROUP BY       | Hash / Merge Join   | O(N log N) or O(N + M)  | Vectorized, parallel  |
   | Window Function       | Single Scan + Sort  | O(N log N)              | Single table pass     |
   +-----------------------+---------------------+-------------------------+-----------------------+

3. PostgreSQL Deduplication Hierarchy:
   - Level 1 (Elementary) : `SELECT DISTINCT` (Expensive global sort).
   - Level 2 (Intermediate): `GROUP BY key, MIN(val)` (Good for simple scalar rollups).
   - Level 3 (Professional): `ROW_NUMBER() OVER (PARTITION BY key ORDER BY priority)` (Deterministic filtering).
   - Level 4 (Postgres-Native): `DISTINCT ON (key) ... ORDER BY key, priority` (Ultra-fast single-pass scan).

====================================================================================================
*/

SET search_path TO course_data, public;

-- =================================================================================================
-- QUESTION 1: Relational Schema Analysis (student_enrollment vs professors)
-- =================================================================================================
/*
[QUESTION]:
Are the tables `student_enrollment` and `professors` directly related to each other? Why or why not?

[ARCHITECTURAL ANSWER & SYSTEM DESIGN]:
NO, they are NOT directly related.
1. `student_enrollment` has grain: `(student_no, course_no)` -> Connects Students to Courses.
2. `professors` has grain: `(last_name, department, salary, hire_date)` -> Defines Faculty by Department.
3. Why no direct relation:
   - There is no Foreign Key linking `student_enrollment` directly to `professors` (e.g., no `professor_id`
     in `student_enrollment`, and no `student_no` in `professors`).
   - To connect a student to a professor, you must traverse a bridge or hierarchical path:
     `students` -> `student_enrollment` -> `courses` -> (Bridge: `teach` table or department mapping) -> `professors`.
   - In relational modeling, linking them directly without a course/offering relationship produces an
     invalid many-to-many Cartesian explosion.
*/


-- =================================================================================================
-- QUESTION 2: Multi-Table Traversal (Students, Courses & Teaching Faculty)
-- =================================================================================================
/*
[QUESTION]:
Write a query that shows the student's name, the courses the student is taking, and the professors
that teach that course (or professors in the corresponding department / bridge).

[MENTAL MODEL & RETENTION LOGIC]:
Think of the traversal chain:
Start with the subject of interest (`students`), inner join with bridge table (`student_enrollment`),
join with catalog (`courses`), and join with faculty (`professors` via `department` or `teach`).
*/

SELECT 
    s.student_name,
    se.course_no,
    c.course_title,
    p.last_name AS professor_name,
    p.department
FROM students s
JOIN student_enrollment se ON s.student_no = se.student_no
JOIN courses c            ON se.course_no = c.course_no
JOIN professors p         ON 1=1 -- Representing the academic relationship / department link
ORDER BY s.student_name, se.course_no;


-- =================================================================================================
-- QUESTION 3: Root-Cause Analysis of Repeating Data (The Fan-Out Effect)
-- =================================================================================================
/*
[QUESTION]:
If you execute the query from Question 2, why are `student_name` and `course_no` being repeated?

[ENGINEERING EXPLANATION]:
1. The Mathematical Cause: Fan-out caused by 1-to-Many cardinality.
2. If Student 1 takes 'CS110', that represents 1 enrollment record.
3. If 4 professors exist in the target matching table, SQL creates a tuple for EVERY combination:
   `1 enrollment row * 4 professors = 4 output rows`.
4. The database engine does not know which single professor you want unless you provide an explicit
   deterministic tie-breaking condition.
*/


-- =================================================================================================
-- QUESTION 4: Eliminating Redundancy Without `DISTINCT` (Deterministic Single-Entity Selection)
-- =================================================================================================
/*
[QUESTION]:
How can we eliminate this redundancy to display only a SINGLE professor teaching a course so every
student-course record is distinct? (HINT: Do NOT use the `DISTINCT` keyword).

[MENTAL MODEL & RETENTION LOGIC]:
When you want "exactly one record per partition", use an Aggregate Function (`MIN()` / `MAX()`)
inside a subquery / CTE, OR use `ROW_NUMBER() OVER (PARTITION BY ...)`:
*/

-- -------------------------------------------------------------------------------------------------
-- [PRODUCTION-GRADE APPROACH 1]: Window Function Partitioning (Industry Standard)
-- -------------------------------------------------------------------------------------------------
WITH ranked_professors AS (
    SELECT 
        last_name AS professor_name,
        department,
        ROW_NUMBER() OVER (ORDER BY hire_date ASC, last_name ASC) AS rank_order
    FROM professors
),
primary_professor AS (
    SELECT professor_name, department
    FROM ranked_professors
    WHERE rank_order = 1
)
SELECT 
    s.student_name,
    se.course_no,
    c.course_title,
    pp.professor_name
FROM students s
JOIN student_enrollment se ON s.student_no = se.student_no
JOIN courses c            ON se.course_no = c.course_no
CROSS JOIN primary_professor pp
ORDER BY s.student_name, se.course_no;

-- -------------------------------------------------------------------------------------------------
-- [PRODUCTION-GRADE APPROACH 2]: Scalar Correlated Subquery
-- -------------------------------------------------------------------------------------------------
SELECT 
    s.student_name,
    se.course_no,
    c.course_title,
    (SELECT MIN(p.last_name) FROM professors p) AS professor_name
FROM students s
JOIN student_enrollment se ON s.student_no = se.student_no
JOIN courses c            ON se.course_no = c.course_no
ORDER BY s.student_name, se.course_no;


-- =================================================================================================
-- QUESTION 5: Execution Engine Deep-Dive (Why Correlated Subqueries Are Slower)
-- =================================================================================================
/*
[QUESTION]:
Why are correlated subqueries slower than non-correlated subqueries and joins?

[TECHNICAL BREAKDOWN]:
1. Non-Correlated Subqueries:
   - Self-contained. The query optimizer evaluates it EXACTLY ONCE before the outer query runs.
   - Result is placed in a hashed in-memory table or temporary spool.
   - Outer rows do a fast O(1) hash lookup.

2. Correlated Subqueries:
   - Dependent on values from the outer query row: `WHERE inner.col = outer.col`.
   - Forces the engine to perform a NESTED LOOP: For each of the N rows in the outer table, it must
     spin up and execute the subquery scan of M rows in the inner table ($O(N \times M)$ total operations).
   - On a table with 1,000,000 rows, a correlated subquery executes 1,000,000 separate queries!

3. Joins & Modern Window Functions:
   - Can leverage Hash Joins, Sort-Merge Joins, and parallel B-Tree index scans ($O(N + M)$ or $O(N \log N)$),
     streaming rows in bulk through CPU SIMD registers.
*/


-- =================================================================================================
-- QUESTION 6: Above-Average Salary by Department (Correlated vs CTE vs Window)
-- =================================================================================================
/*
[QUESTION]:
Write a query that returns employees whose salary is above average for their given department.

[MENTAL MODEL & RETENTION LOGIC]:
Think: "I need to compare an individual's salary against their group's benchmark."
- Elementary: Correlated subquery in `WHERE`.
- Professional: Window function `AVG(salary) OVER (PARTITION BY department)` in a CTE.
*/

-- -------------------------------------------------------------------------------------------------
-- [ELEMENTARY APPROACH]: Correlated Subquery (O(N * M))
-- -------------------------------------------------------------------------------------------------
SELECT 
    e1.employee_id,
    e1.first_name,
    e1.last_name,
    e1.department,
    e1.salary
FROM employees e1
WHERE e1.salary > (
    SELECT AVG(e2.salary)
    FROM employees e2
    WHERE e2.department = e1.department
)
ORDER BY e1.department, e1.salary DESC;

-- -------------------------------------------------------------------------------------------------
-- [PROFESSIONAL / PRODUCTION-GRADE APPROACH]: Window Function in CTE (Single Table Scan, O(N log N))
-- -------------------------------------------------------------------------------------------------
WITH department_salary_benchmarks AS (
    SELECT 
        employee_id,
        first_name,
        last_name,
        department,
        salary,
        ROUND(AVG(salary) OVER (PARTITION BY department), 2) AS dept_avg_salary
    FROM employees
)
SELECT 
    employee_id,
    first_name,
    last_name,
    department,
    salary,
    dept_avg_salary,
    (salary - dept_avg_salary) AS salary_above_dept_avg
FROM department_salary_benchmarks
WHERE salary > dept_avg_salary
ORDER BY department, salary DESC;


-- =================================================================================================
-- QUESTION 7: Outer Joins for Complete Data Coverage (All Students With or Without Courses)
-- =================================================================================================
/*
[QUESTION]:
Write a query that returns ALL of the students as well as any courses they may or may not be taking.

[MENTAL MODEL & RETENTION LOGIC]:
Think: "Preserve the left table at all costs."
An `INNER JOIN` drops students who haven't enrolled yet (orphan records).
A `LEFT JOIN` retains all students, filling course details with `NULL` where no enrollment exists.
Use `COALESCE()` to provide clean default values for production reporting.
*/

SELECT 
    s.student_no,
    s.student_name,
    s.age,
    COALESCE(se.course_no, 'NOT ENROLLED')   AS course_no,
    COALESCE(c.course_title, 'NO COURSE')    AS course_title,
    COALESCE(c.credits, 0)                   AS credits
FROM students s
LEFT JOIN student_enrollment se ON s.student_no = se.student_no
LEFT JOIN courses c            ON se.course_no = c.course_no
ORDER BY s.student_no, se.course_no;


-- =================================================================================================
-- QUESTION 8: Departmental Top Earners (Dense Ranking Pattern)
-- =================================================================================================
/*
[QUESTION]:
Find the top 2 highest-paid employees in EVERY department, handling ties cleanly.

[ENTERPRISE USE CASE]:
Executive compensation benchmarking and promotion candidate identification.
*/

WITH ranked_department_salaries AS (
    SELECT 
        employee_id,
        first_name,
        last_name,
        department,
        salary,
        DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank
    FROM employees
)
SELECT 
    department,
    salary_rank,
    employee_id,
    first_name,
    last_name,
    salary
FROM ranked_department_salaries
WHERE salary_rank <= 2
ORDER BY department, salary_rank, salary DESC;


-- =================================================================================================
-- QUESTION 9: Anti-Join Pattern (Find Unassigned / Inactive Entities)
-- =================================================================================================
/*
[QUESTION]:
Find all departments that currently have ZERO employees assigned.

[MENTAL MODEL & RETENTION LOGIC]:
`LEFT JOIN ... WHERE right.key IS NULL` (Anti-Join) is faster and NULL-safe compared to `NOT IN`.
*/

SELECT 
    d.department,
    d.division
FROM departments d
LEFT JOIN employees e ON d.department = e.department
WHERE e.employee_id IS NULL;


-- =================================================================================================
-- QUESTION 10: Running Totals & Cumulative Distribution
-- =================================================================================================
/*
[QUESTION]:
Calculate the cumulative salary spend within each department ordered chronologically by hire date.
*/

SELECT 
    employee_id,
    first_name,
    last_name,
    department,
    hire_date,
    salary,
    SUM(salary) OVER (
        PARTITION BY department 
        ORDER BY hire_date ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_dept_payroll
FROM employees
ORDER BY department, hire_date ASC;
