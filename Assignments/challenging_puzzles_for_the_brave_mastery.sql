/*
====================================================================================================
           SQL FOR DATA SCIENCE & DATA ENGINEERING: PROFESSIONAL MASTERY CURRICULUM
                   MODULE: CHALLENGING PUZZLES, RELATIONAL SET THEORY & LOGIC
====================================================================================================

----------------------------------------------------------------------------------------------------
### 1. FOUNDATIONAL CHEAT SHEET & ADVANCED SET THEORY MENTAL FRAMEWORKS
----------------------------------------------------------------------------------------------------

1. The Three-Valued Logic & NULL Trap with `NOT IN`:
   - `IN (1, 2, NULL)` -> Evaluates to TRUE if match found, else UNKNOWN.
   - `NOT IN (1, 2, NULL)` -> If ANY row in the subquery is `NULL`, the entire predicate evaluates
     to UNKNOWN (falsy), returning ZERO rows!
   - Golden Rule: NEVER use `NOT IN` on subqueries unless columns have `NOT NULL` constraints.
     ALWAYS prefer `NOT EXISTS` (Anti-Semi-Join) or `LEFT JOIN ... WHERE right.key IS NULL`.

2. Symmetric Difference (XOR Logic):
   - Logic: Condition A OR Condition B, but NOT BOTH.
   - Mathematical Representation: $(A \cup B) \setminus (A \cap B)$.
   - SQL Implementation Pattern: `GROUP BY entity HAVING COUNT(DISTINCT CASE WHEN ...) = 1`.

3. Relational Division ("Matches ALL" criteria):
   - Finding entities that possess EVERY item in a target set.
   - SQL Pattern: `GROUP BY entity HAVING COUNT(DISTINCT target_col) = (SELECT COUNT(*) FROM target_set)`.

4. Cardinality & Degree Constraints:
   - "At most N" : `HAVING COUNT(*) <= N`.
   - "Exactly 1"  : `HAVING COUNT(*) = 1 AND MAX(col) = 'target'`.
   - "Excluding 0": Use `INNER JOIN` rather than `LEFT JOIN`.

====================================================================================================
*/

SET search_path TO course_data, public;

-- =================================================================================================
-- PUZZLE 1: Students Who Do NOT Take CS180
-- =================================================================================================
/*
[QUESTION]:
Write a query that finds students who do not take course 'CS180'.

[MENTAL MODEL & RETENTION LOGIC]:
Think: "Filter out any student whose enrollment history contains CS180."
- Approach 1 (NOT EXISTS): Check that no record exists in `student_enrollment` for this student with 'CS180'.
- Approach 2 (Anti-Join): Left join specifically to CS180 enrollments and keep where the join missed (`IS NULL`).
- Approach 3 (Conditional Aggregation): Aggregate all enrollments and assert that the sum of CS180 is 0.

[ENTERPRISE USE CASE]:
Targeted Marketing / Exclusion Lists:
Finding registered users who have NEVER purchased a specific flagship product or activated a feature.
*/

-- -------------------------------------------------------------------------------------------------
-- [PRODUCTION-GRADE APPROACH 1]: NOT EXISTS (Anti-Semi-Join - Fastest & NULL-Safe)
-- -------------------------------------------------------------------------------------------------
SELECT 
    s.student_no,
    s.student_name,
    s.age
FROM students s
WHERE NOT EXISTS (
    SELECT 1 
    FROM student_enrollment se 
    WHERE se.student_no = s.student_no 
      AND se.course_no = 'CS180'
)
ORDER BY s.student_no;

-- -------------------------------------------------------------------------------------------------
-- [PRODUCTION-GRADE APPROACH 2]: Filtered LEFT JOIN (Anti-Join Pattern)
-- -------------------------------------------------------------------------------------------------
SELECT 
    s.student_no,
    s.student_name,
    s.age
FROM students s
LEFT JOIN student_enrollment se 
    ON s.student_no = se.student_no 
   AND se.course_no = 'CS180'
WHERE se.course_no IS NULL
ORDER BY s.student_no;


-- =================================================================================================
-- PUZZLE 2: Students Taking CS110 OR CS107 (Exclusive OR / XOR)
-- =================================================================================================
/*
[QUESTION]:
Write a query to find students who take 'CS110' or 'CS107', but NOT both.

[MENTAL MODEL & RETENTION LOGIC]:
Think: "Count matches within the target set. The count must equal exactly 1."
If a student takes CS110 (count=1) -> Included.
If a student takes CS107 (count=1) -> Included.
If a student takes BOTH CS110 and CS107 (count=2) -> Discarded.
If a student takes NEITHER (count=0) -> Discarded.

[ENTERPRISE USE CASE]:
A/B Testing Cohort Isolation:
Finding users enrolled in Test Variant A or Test Variant B, but strictly excluding users exposed to both.
*/

-- -------------------------------------------------------------------------------------------------
-- [PRODUCTION-GRADE APPROACH]: Conditional Aggregation with HAVING
-- -------------------------------------------------------------------------------------------------
SELECT 
    s.student_no,
    s.student_name
FROM students s
JOIN student_enrollment se ON s.student_no = se.student_no
WHERE se.course_no IN ('CS110', 'CS107')
GROUP BY s.student_no, s.student_name
HAVING COUNT(DISTINCT se.course_no) = 1
ORDER BY s.student_no;


-- =================================================================================================
-- PUZZLE 3: Students Taking CS220 AND NO OTHER COURSES (Exact Set Match)
-- =================================================================================================
/*
[QUESTION]:
Write a query to find students who take 'CS220' and NO other courses.

[MENTAL MODEL & RETENTION LOGIC]:
Two simultaneous conditions must hold:
1. Total course count for this student must equal exactly 1.
2. That single course must be 'CS220' (`MAX(course_no) = 'CS220'`).

[ENTERPRISE USE CASE]:
Single-Product Tier Analysis:
Identifying customers subscribed strictly to the Free tier and zero add-on modules.
*/

-- -------------------------------------------------------------------------------------------------
-- [PRODUCTION-GRADE APPROACH]: Single-Pass Aggregation
-- -------------------------------------------------------------------------------------------------
SELECT 
    s.student_no,
    s.student_name
FROM students s
JOIN student_enrollment se ON s.student_no = se.student_no
GROUP BY s.student_no, s.student_name
HAVING COUNT(se.course_no) = 1 
   AND MAX(se.course_no) = 'CS220'
ORDER BY s.student_no;


-- =================================================================================================
-- PUZZLE 4: Students Taking At Most 2 Courses (Excluding 0 and >2 Courses)
-- =================================================================================================
/*
[QUESTION]:
Write a query that finds students who take at most 2 courses. Your query should exclude students
that don't take any courses as well as those that take more than 2 courses. (Target: 1 or 2 courses).

[MENTAL MODEL & RETENTION LOGIC]:
1. To exclude students with 0 courses: Use `INNER JOIN` with `student_enrollment`.
2. To constrain to at most 2: Use `HAVING COUNT(se.course_no) <= 2` or `HAVING COUNT(se.course_no) IN (1, 2)`.

[ENTERPRISE USE CASE]:
Part-Time Workload / Usage Capping:
Filtering active accounts with manageable loads (1-2 active tickets) for capacity planning.
*/

SELECT 
    s.student_no,
    s.student_name,
    COUNT(se.course_no) AS total_courses_enrolled
FROM students s
JOIN student_enrollment se ON s.student_no = se.student_no
GROUP BY s.student_no, s.student_name
HAVING COUNT(se.course_no) <= 2
ORDER BY total_courses_enrolled DESC, s.student_no;


-- =================================================================================================
-- PUZZLE 5: Students Older Than At Most Two Other Students
-- =================================================================================================
/*
[QUESTION]:
Write a query to find students who are older than at most two other students.

[MENTAL MODEL & RETENTION LOGIC]:
Deconstruct the English phrase:
"Older than at most two other students" means:
If we count all strictly younger students (`s2.age < s1.age`), that count must be <= 2.
- The youngest students (no one is younger) have count = 0 (0 <= 2 -> TRUE).
- The next youngest students have count = 1 or 2 (<= 2 -> TRUE).
- Anyone with 3 or more people younger than them is excluded.

[ENTERPRISE USE CASE]:
Bottom Tier / Baseline Quantile Analysis:
Identifying lowest transaction amounts, bottom seniority tiers, or entry-level cohorts.
*/

-- -------------------------------------------------------------------------------------------------
-- [PRODUCTION-GRADE APPROACH 1]: Correlated Subquery (Explicit Definition)
-- -------------------------------------------------------------------------------------------------
SELECT 
    s1.student_no,
    s1.student_name,
    s1.age,
    (
        SELECT COUNT(*)
        FROM students s2
        WHERE s2.age < s1.age
    ) AS younger_students_count
FROM students s1
WHERE (
    SELECT COUNT(*) 
    FROM students s2 
    WHERE s2.age < s1.age
) <= 2
ORDER BY s1.age ASC, s1.student_no;

-- -------------------------------------------------------------------------------------------------
-- [PRODUCTION-GRADE APPROACH 2]: Window Function (Dense Ranking Approach)
-- -------------------------------------------------------------------------------------------------
WITH age_ranked_students AS (
    SELECT 
        student_no,
        student_name,
        age,
        DENSE_RANK() OVER (ORDER BY age ASC) AS age_tier
    FROM students
)
SELECT 
    student_no,
    student_name,
    age,
    age_tier
FROM age_ranked_students
WHERE age_tier <= 2
ORDER BY age ASC, student_no;


-- =================================================================================================
-- PUZZLE 6: Relational Division ("Students Who Take ALL Available Courses")
-- =================================================================================================
/*
[QUESTION]:
Find students who are enrolled in EVERY course offered in the `courses` catalog.

[MENTAL MODEL & RETENTION LOGIC]:
Compare the count of distinct courses enrolled by the student against the total count in the catalog.
*/

SELECT 
    s.student_no,
    s.student_name
FROM students s
JOIN student_enrollment se ON s.student_no = se.student_no
GROUP BY s.student_no, s.student_name
HAVING COUNT(DISTINCT se.course_no) = (SELECT COUNT(*) FROM courses);


-- =================================================================================================
-- PUZZLE 7: Mutual / Reciprocal Relationships
-- =================================================================================================
/*
[QUESTION]:
Find all pairs of students who share the exact same age. Avoid duplicate flipped pairs (e.g., (A, B) and (B, A))
and self-matches (A, A).

[MENTAL MODEL & RETENTION LOGIC]:
Join condition `s1.student_no < s2.student_no` simultaneously eliminates self-matches and mirrors.
*/

SELECT 
    s1.student_name AS student_1,
    s2.student_name AS student_2,
    s1.age
FROM students s1
JOIN students s2 
    ON s1.age = s2.age 
   AND s1.student_no < s2.student_no
ORDER BY s1.age, s1.student_name;
