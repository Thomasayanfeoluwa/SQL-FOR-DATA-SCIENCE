/*
================================================================================
 MODULE 07 — ADVANCED SET THEORY, RELATIONAL PUZZLES & EXPERT-LEVEL SQL
 As a Data Scientist (challenging puzzle section of the course)
================================================================================

 TOPICS COVERED:
   NOT EXISTS / Anti-semi-join
   Symmetric Difference (XOR set logic)
   Relational Division (ALL-of-a-set matching)
   Cardinality constraints (at most N, exactly N)
   Reciprocal / mutual relationships
   Quantified comparisons: > ANY, > ALL
   Three-valued logic and NULL safety
   Complete student–course–professor traversal

 SCHEMA: course_data.students, course_data.student_enrollment,
         course_data.courses, course_data.professors, course_data.teach
         public.employees, public.departments

================================================================================
*/

SET search_path TO course_data, public;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q01  Are student_enrollment and professors directly related?
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Analyse the schema to determine whether student_enrollment and
 professors are directly related. Prove your answer by examining the tables.

 ANSWER (write this from memory as a data scientist):
   NO — they are NOT directly related.

   student_enrollment: (student_no, course_no) — bridges students ↔ courses
   professors: (last_name, department, salary, hire_date) — describes faculty

   There is NO foreign key between them. No column in student_enrollment
   references professors, and no column in professors references
   student_enrollment.

   To connect a student to a professor, you must traverse:
   students → student_enrollment → courses → teach → professors

   The intermediate 'teach' table is the bridge between courses and professors.

 PROOF QUERY — inspect what columns are shared:
*/

-- Inspect both tables
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'student_enrollment' AND table_schema = 'course_data'
ORDER BY ordinal_position;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'professors' AND table_schema = 'course_data'
ORDER BY ordinal_position;

-- No common key exists — a JOIN would require going through teach and courses


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q02  Full traversal — students + courses + professors
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Show each student's name, the courses they are taking, and
 ALL professors who teach those courses.

 MENTAL MODEL — 5-table traversal chain:
   students → [on student_no] → student_enrollment
             → [on course_no] → courses
             → [on course_no] → teach
             → [on last_name] → professors

 This query will DELIBERATELY show duplicates (fan-out):
 Student 1 in CS180 → Chong, Brown, Wilson all teach CS180 → 3 rows for that enrollment.
 Q03 explains why. Q04 fixes it.
*/

SELECT
    s.student_name,
    se.course_no,
    c.course_title,
    t.last_name    AS professor_name,
    p.department   AS professor_department
FROM students s
INNER JOIN student_enrollment se ON s.student_no  = se.student_no
INNER JOIN courses c             ON se.course_no   = c.course_no
INNER JOIN teach t               ON c.course_no    = t.course_no
INNER JOIN professors p          ON t.last_name    = p.last_name
ORDER BY s.student_name, se.course_no, t.last_name;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q03  Why does the previous query repeat data?
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Explain why student_name and course_no repeat in Q02's output.

 ANSWER — The Fan-Out (Cardinality Explosion):
   The teach table has a many-to-many relationship between courses and professors.
   CS180 is taught by: Chong, Brown, AND Wilson (3 professors).

   When we JOIN:
     1 enrollment row (student_1, CS180)
   × 3 teach rows   (CS180, Chong), (CS180, Brown), (CS180, Wilson)
   = 3 result rows for student_1 in CS180

   The JOIN multiplies rows because the cardinality on the right side of teach
   is greater than 1 per course_no. This is the "fan-out" problem.

 PROOF — show the teach table's many-to-one structure:
*/

SELECT course_no, COUNT(*) AS professor_count
FROM teach
GROUP BY course_no
ORDER BY professor_count DESC;

-- CS180 has 3 professors: Chong, Brown, Wilson — that's why it creates 3 rows


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q04  Eliminate redundancy — one professor per course (no DISTINCT!)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Show each student-course pair exactly ONCE with the alphabetically
 first professor for that course. DO NOT use SELECT DISTINCT.

 MENTAL MODEL:
   The fix is not at the outer query (DISTINCT doesn't let you choose WHICH professor)
   The fix is at the teach table level:
   → Deduplicate teach BEFORE the JOIN by picking MIN(last_name) per course_no.
   → Join the already-deduplicated teach result.

 ELEMENTARY vs PROFESSIONAL:
   ✗ DISTINCT → can't control which professor is selected, non-deterministic
   ✓ GROUP BY course_no, MIN(last_name) in a CTE → deterministic, controlled
   ✓ ROW_NUMBER() OVER (PARTITION BY course_no ORDER BY last_name) → best

 REAL-WORLD USE: Deduplication before a JOIN is a core data engineering
 skill. At Stripe, deduplicating payment events before joining to customer
 records prevents revenue double-counting.
*/

-- Professional: Pre-aggregate teach table to one professor per course
WITH lead_teacher AS (
    SELECT
        course_no,
        MIN(last_name)  AS primary_professor
    FROM teach
    GROUP BY course_no
)
SELECT
    s.student_name,
    se.course_no,
    c.course_title,
    lt.primary_professor
FROM students s
INNER JOIN student_enrollment se ON s.student_no  = se.student_no
INNER JOIN courses c             ON se.course_no   = c.course_no
INNER JOIN lead_teacher lt       ON c.course_no    = lt.course_no
ORDER BY s.student_name, se.course_no;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q05  Why are correlated subqueries slower than non-correlated?
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Explain the performance difference. Then demonstrate it by
 rewriting a correlated subquery as a JOIN/window function.

 ANSWER — Execution Mechanics:

 NON-CORRELATED (independent) subquery:
   The inner query runs ONCE. Its result is cached in memory.
   The outer query does a fast hash lookup for each row.
   Complexity: O(N + M) — one pass each.

 CORRELATED subquery:
   The inner query runs ONCE PER ROW of the outer query.
   For a table with 1 million rows, the inner query fires 1 million times!
   Complexity: O(N × M) — the nested loop problem.
   Modern query optimisers can sometimes unnest them — but not always.

 JOIN / WINDOW FUNCTION:
   Hash Join: Build hash table from smaller table, probe with larger → O(N+M).
   Window Function: Single sequential scan + buffer → O(N log N).
   Both scale far better than correlated subqueries.

 BENCHMARK MENTAL MODEL for 356-row employees table:
   Correlated: up to 356 × 356 = 126,736 operations
   Window AVG: 356 operations (one scan)
*/

-- Correlated subquery (O(N × M)) — from your tutorial
SELECT employee_id, first_name, department, salary
FROM employees e1
WHERE salary > (
    SELECT AVG(salary) FROM employees e2 WHERE e2.department = e1.department
);

-- Professional window function (O(N log N) — single scan)
WITH benchmarks AS (
    SELECT *,
        ROUND(AVG(salary) OVER (PARTITION BY department), 0) AS dept_avg
    FROM employees
)
SELECT employee_id, first_name, department, salary, dept_avg,
       salary - dept_avg AS premium
FROM benchmarks
WHERE salary > dept_avg
ORDER BY department, salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q06  Students NOT taking CS180 (the NULL-safe anti-join)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find students who do NOT take course CS180.

 MENTAL MODEL — THREE APPROACHES (understand when to use each):

 1. NOT IN (subquery):
    DANGER: If the subquery returns ANY NULL, the WHERE clause returns UNKNOWN
    for ALL rows — meaning 0 results. Silent data bug!
    Only safe when the column has a NOT NULL constraint.

 2. NOT EXISTS (anti-semi-join):
    The safest approach. For each student, check IF no enrollment row exists
    for CS180. NULL-safe because EXISTS checks for row existence, not values.

 3. LEFT JOIN anti-join:
    Also safe. Left join specifically on CS180 enrollments. Keep rows where
    the right side didn't match (IS NULL on the joined key).

 REAL-WORLD USE: Exclusion lists (email opt-outs), churned users (no activity
 in 30 days), gap analysis (products with no orders this quarter).
*/

-- Approach 1: NOT IN (risky on nullable columns — avoid in production)
SELECT student_no, student_name
FROM students
WHERE student_no NOT IN (
    SELECT student_no FROM student_enrollment WHERE course_no = 'CS180'
);

-- Approach 2: NOT EXISTS (RECOMMENDED — NULL-safe)
SELECT s.student_no, s.student_name, s.age
FROM students s
WHERE NOT EXISTS (
    SELECT 1
    FROM student_enrollment se
    WHERE se.student_no = s.student_no
      AND se.course_no  = 'CS180'
)
ORDER BY s.student_no;

-- Approach 3: LEFT JOIN Anti-join (also RECOMMENDED)
SELECT s.student_no, s.student_name, s.age
FROM students s
LEFT JOIN student_enrollment se
    ON s.student_no = se.student_no
   AND se.course_no = 'CS180'
WHERE se.student_no IS NULL
ORDER BY s.student_no;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q07  XOR — students taking CS110 OR CS107, but NOT both
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find students who are enrolled in CS110 OR CS107, but NOT both.

 MENTAL MODEL — SYMMETRIC DIFFERENCE (XOR):
   Takes two sets A = {CS110 students} and B = {CS107 students}.
   XOR = (A ∪ B) minus (A ∩ B)
       = Students in at least one, but not both.

 SQL PATTERN:
   Filter rows to the two target courses with WHERE IN.
   GROUP BY student.
   HAVING COUNT(DISTINCT course_no) = 1
   → If count = 1: in exactly one of the two (correct).
   → If count = 2: in both (exclude).
   → If count = 0: in neither (already filtered by IN clause).

 REAL-WORLD USE: A/B test variant isolation — users exposed to variant A
 or B but NOT both (preventing test contamination). Data deduplication in
 marketing lists where a contact appears in exactly one segment.
*/

SELECT
    s.student_no,
    s.student_name
FROM students s
INNER JOIN student_enrollment se ON s.student_no = se.student_no
WHERE se.course_no IN ('CS110', 'CS107')
GROUP BY s.student_no, s.student_name
HAVING COUNT(DISTINCT se.course_no) = 1
ORDER BY s.student_no;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q08  Exact set match — students taking ONLY CS220 and no other courses
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find students enrolled in CS220 and ZERO other courses.

 MENTAL MODEL — TWO SIMULTANEOUS CONDITIONS:
   Condition 1: COUNT(course_no) = 1   → only enrolled in 1 course total
   Condition 2: MAX(course_no) = 'CS220' → that 1 course must be CS220

   Together: exactly one enrollment, and it's CS220. Deterministic.

   Why MAX works: When there's only 1 course, MIN and MAX return that course.
   If COUNT = 1, then MAX = MIN = the only course.

 ALTERNATIVE:
   HAVING COUNT(*) = 1 AND SUM(CASE WHEN course_no = 'CS220' THEN 1 END) = 1

 REAL-WORLD USE: Single-product subscribers (customers using ONLY the basic
 plan, zero add-ons) — prime upsell targets.
*/

SELECT
    s.student_no,
    s.student_name
FROM students s
INNER JOIN student_enrollment se ON s.student_no = se.student_no
GROUP BY s.student_no, s.student_name
HAVING COUNT(se.course_no) = 1
   AND MAX(se.course_no) = 'CS220'
ORDER BY s.student_no;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q09  Cardinality constraint — at most 2 courses (exclude 0 and 3+)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find students taking 1 or 2 courses. Exclude students with
 no courses and those with 3 or more.

 MENTAL MODEL — CARDINALITY WINDOW:
   To exclude 0 enrollments → use INNER JOIN (students with NO enrollment disappear)
   To cap at 2 → HAVING COUNT(course_no) <= 2

   Two filter layers:
   Layer 1 (structural): INNER JOIN eliminates students without enrollments
   Layer 2 (aggregate): HAVING restricts to groups with ≤ 2 courses

 CHEAT SHEET:
   At least N:   HAVING COUNT(*) >= N
   At most N:    HAVING COUNT(*) <= N
   Exactly N:    HAVING COUNT(*) = N
   Between N-M:  HAVING COUNT(*) BETWEEN N AND M

 REAL-WORLD USE: Part-time user detection (active but light users —
 between 1 and 2 active projects), customer engagement scoring.
*/

SELECT
    s.student_no,
    s.student_name,
    COUNT(se.course_no)  AS enrolled_courses
FROM students s
INNER JOIN student_enrollment se ON s.student_no = se.student_no
GROUP BY s.student_no, s.student_name
HAVING COUNT(se.course_no) <= 2
ORDER BY enrolled_courses DESC, s.student_no;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q10  Quantified comparison — older than at most 2 other students
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find students who are older than at most 2 other students.

 MENTAL MODEL — PARSING THE ENGLISH CAREFULLY:
   "older than at most 2 other students" means:
   Count of students who are STRICTLY YOUNGER than this student ≤ 2.

   If Alice is 21 and only Pete (20) and Ralph (19) are younger → count = 2 ≤ 2 → include.
   If Bob is 22 and Arnold (21), Sylvia (20), Pete (20), Ralph (19) are younger → count = 4 > 2 → exclude.
   If Michael is 19 and nobody is younger → count = 0 ≤ 2 → include.

   CORRELATED SUBQUERY APPROACH:
   For each student s1, count students s2 where s2.age < s1.age.
   Keep s1 where that count ≤ 2.

 PROFESSIONAL WINDOW APPROACH:
   DENSE_RANK() OVER (ORDER BY age ASC) ≤ 3
   → The bottom 3 distinct age values (youngest to oldest).
*/

-- Correlated subquery approach (explicit, educational)
SELECT
    s1.student_no,
    s1.student_name,
    s1.age,
    (SELECT COUNT(*) FROM students s2 WHERE s2.age < s1.age)  AS younger_count
FROM students s1
WHERE (
    SELECT COUNT(*) FROM students s2 WHERE s2.age < s1.age
) <= 2
ORDER BY s1.age ASC, s1.student_no;

-- Professional window function approach (efficient)
WITH age_ranked AS (
    SELECT
        student_no,
        student_name,
        age,
        DENSE_RANK() OVER (ORDER BY age ASC)  AS age_rank
    FROM students
)
SELECT student_no, student_name, age, age_rank
FROM age_ranked
WHERE age_rank <= 3
ORDER BY age ASC, student_no;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q11  Relational division — students enrolled in ALL courses
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find students who are enrolled in EVERY course in the course catalog.

 MENTAL MODEL — RELATIONAL DIVISION:
   "Student has every course" means:
   COUNT(DISTINCT enrolled courses) = COUNT(all courses in catalog)

   Both sides of the comparison must count UNIQUE values.
   Subquery: (SELECT COUNT(*) FROM courses) → total distinct courses = 5.
   HAVING COUNT(DISTINCT se.course_no) = 5 → student has all 5.

 REAL-WORLD USE: Users who have completed ALL onboarding steps, customers
 who purchased from EVERY product category, A/B test completers who went
 through ALL funnel stages.
*/

SELECT
    s.student_no,
    s.student_name
FROM students s
INNER JOIN student_enrollment se ON s.student_no = se.student_no
GROUP BY s.student_no, s.student_name
HAVING COUNT(DISTINCT se.course_no) = (SELECT COUNT(*) FROM courses);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q12  Mutual pairs — students who share the same age
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find all pairs of students who share the same age. Each pair
 should appear only once (not as (A,B) AND (B,A)), and no self-pairs.

 MENTAL MODEL — SELF-JOIN WITH ASYMMETRIC FILTER:
   Join students to itself on the same age.
   Eliminate self-match: s1.student_no <> s2.student_no.
   Eliminate mirror: s1.student_no < s2.student_no
   → This condition ensures only (A,B) appears, never (B,A).

 REAL-WORLD USE: Finding similar users for a recommendation engine,
 detecting potential duplicate accounts (same name + age + city),
 social network friend suggestions.
*/

SELECT
    s1.student_name  AS student_1,
    s2.student_name  AS student_2,
    s1.age           AS shared_age
FROM students s1
INNER JOIN students s2
    ON s1.age = s2.age
   AND s1.student_no < s2.student_no
ORDER BY s1.age, s1.student_name;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q13  Students enrolled in EXACTLY 3 courses
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find students enrolled in exactly 3 courses. Show the student
 name and their specific course list as a comma-separated string.

 MENTAL MODEL:
   HAVING COUNT = 3 for the exact cardinality.
   STRING_AGG(course_no, ', ' ORDER BY course_no) → PostgreSQL aggregate
   that concatenates all values in a group with a separator.

 REAL-WORLD USE: Users with a specific engagement score (exactly 3 actions),
 detecting accounts hitting a plan limit, SLA-compliance checks.
*/

SELECT
    s.student_no,
    s.student_name,
    COUNT(se.course_no)                                         AS course_count,
    STRING_AGG(se.course_no, ', ' ORDER BY se.course_no)       AS enrolled_courses
FROM students s
INNER JOIN student_enrollment se ON s.student_no = se.student_no
GROUP BY s.student_no, s.student_name
HAVING COUNT(se.course_no) = 3
ORDER BY s.student_no;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q14  Students enrolled in CS110 AND CS180 (intersection requirement)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Find students who are enrolled in BOTH CS110 AND CS180.

 MENTAL MODEL — SET INTERSECTION:
   Filter to both target courses (WHERE IN).
   Group by student.
   HAVING COUNT(DISTINCT course_no) = 2 → means they have BOTH.

 REAL-WORLD USE: Multi-condition feature adoption (users who have used
 Feature A AND Feature B), customers who purchased from both Category X
 and Category Y (cross-sell analysis).
*/

SELECT
    s.student_no,
    s.student_name
FROM students s
INNER JOIN student_enrollment se ON s.student_no = se.student_no
WHERE se.course_no IN ('CS110', 'CS180')
GROUP BY s.student_no, s.student_name
HAVING COUNT(DISTINCT se.course_no) = 2
ORDER BY s.student_no;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q15  Expert challenge — salary above average for department (employees table)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: In the employees table, find employees earning more than the
 average salary for their department. Show name, department, salary, dept avg,
 and how much above average they are.

 MENTAL MODEL — Three equivalent approaches from least to most professional:

 1. Correlated subquery: Works. Executes N × scan for each row. Avoid at scale.
 2. Self-join + GROUP BY: Avoids correlated subquery but requires explicit join.
 3. Window function in CTE: Best — single table scan, readable, scalable.

 For production use, always reach for the window function when available.
*/

SET search_path TO public;

-- Correlated subquery (from your tutorial — educational reference)
SELECT first_name, department, salary
FROM employees e1
WHERE salary > (SELECT AVG(salary) FROM employees e2 WHERE e2.department = e1.department)
ORDER BY department, salary DESC;

-- Professional CTE + window function (production standard)
WITH enriched AS (
    SELECT
        employee_id,
        first_name,
        last_name,
        department,
        salary,
        ROUND(AVG(salary) OVER (PARTITION BY department), 0)  AS dept_avg_salary
    FROM employees
)
SELECT
    employee_id,
    first_name,
    last_name,
    department,
    salary,
    dept_avg_salary,
    salary - dept_avg_salary                    AS above_dept_avg_by,
    ROUND(
        100.0 * salary / dept_avg_salary - 100,
        1
    )                                           AS pct_above_avg
FROM enriched
WHERE salary > dept_avg_salary
ORDER BY department, salary DESC;
