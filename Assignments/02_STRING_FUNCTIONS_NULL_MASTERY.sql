/*
================================================================================
 MODULE 02 — STRING FUNCTIONS, BOOLEAN EXPRESSIONS & NULL HANDLING
 As a Data Scientist / Data Engineer
================================================================================

 FUNCTIONS COVERED:
   UPPER()  LOWER()  INITCAP()  LENGTH()  TRIM()  LTRIM()  RTRIM()
   CONCAT() || (concatenation operator)
   SUBSTRING()  POSITION()  REPLACE()  REGEXP_REPLACE()
   COALESCE()   NULLIF()
   Boolean columns (salary > 100000)  LIKE / ILIKE

 SCHEMA CONTEXT: public.employees, public.departments

================================================================================
*/

SET search_path TO public;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q01  Case normalisation — UPPER, LOWER, INITCAP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: You are cleaning a raw data export where names were typed
 inconsistently (all-caps, all-lowercase, mixed). Standardise:
   - first_name → Title Case  (INITCAP)
   - last_name  → UPPERCASE   (UPPER)
   - department → lowercase   (LOWER)

 MENTAL MODEL:
   UPPER('hello')    → 'HELLO'
   LOWER('HELLO')    → 'hello'
   INITCAP('john')   → 'John'      ← best for display names

 CHEAT SHEET:
   SELECT UPPER(col), LOWER(col), INITCAP(col) FROM t;

 REAL-WORLD USE: Every data pipeline that sources from CRM systems (Salesforce,
 HubSpot) must normalise customer names before loading to a warehouse. 
 Inconsistent casing causes duplicate rows in GROUP BY.
*/

SELECT
    INITCAP(first_name)  AS first_name_clean,
    UPPER(last_name)     AS last_name_clean,
    LOWER(department)    AS department_clean,
    salary
FROM employees
ORDER BY first_name_clean;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q02  String length — detecting and filtering anomalies
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Data quality task — find employees whose first_name is unusually
 short (< 4 characters) or unusually long (> 12 characters). These are
 potential data entry errors. Return name, name length, and department.

 MENTAL MODEL:
   LENGTH(col) returns character count (NULL for NULL values).
   Use it in WHERE, SELECT, and ORDER BY.

 REAL-WORLD USE: Detecting truncated imports, enforcing business rules on
 form inputs, audit trails for data cleaning pipelines.
*/

SELECT
    first_name,
    LENGTH(first_name)  AS name_length,
    department
FROM employees
WHERE LENGTH(first_name) < 4
   OR LENGTH(first_name) > 12
ORDER BY name_length ASC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q03  TRIM — whitespace removal (the invisible bug)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: A data feed is sending department names with leading/trailing
 spaces ('  Clothing  '). Prove that LENGTH differs before and after TRIM,
 then write a query that would use TRIM in a comparison.

 MENTAL MODEL:
   TRIM(str)          → removes leading AND trailing spaces
   LTRIM(str)         → removes leading spaces only
   RTRIM(str)         → removes trailing spaces only
   TRIM('xy' FROM str) → removes specific characters

   '  Clothing  ' = 'Clothing'  → FALSE (spaces matter in string comparison)
   TRIM('  Clothing  ') = 'Clothing'  → TRUE

 REAL-WORLD USE: Source system data from SAP, Oracle ERP, or CSV exports
 routinely contain padding spaces that break JOINs. Always TRIM before joining
 on string keys.
*/

-- Demonstrate the problem
SELECT
    '  HELLO THERE  '                           AS raw_value,
    LENGTH('  HELLO THERE  ')                   AS raw_length,
    TRIM('  HELLO THERE  ')                     AS trimmed_value,
    LENGTH(TRIM('  HELLO THERE  '))             AS trimmed_length;

-- Applied to table — safe JOIN pattern
SELECT
    TRIM(first_name)  AS first_name,
    TRIM(department)  AS department
FROM employees
WHERE TRIM(department) = 'Clothing'
ORDER BY first_name;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q04  Concatenation — building display strings and composite keys
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Build an employee badge display. Requirements:
   - Display: "Berrie Manueau — Sports | $154,864"
   - The separator is ' — ', columns separated by ' | ', salary prefixed with '$'

 MENTAL MODEL:
   || in PostgreSQL is the string concatenation operator.
   NULL || anything = NULL. So if either side is NULL, the whole expression is NULL.
   COALESCE to protect against NULL propagation.

 ELEMENTARY vs PROFESSIONAL:
   ✗ first_name || last_name                  → 'BerrieManeau' (no space)
   ✓ first_name || ' ' || last_name           → 'Berrie Maneau'
   ✓ CONCAT(first_name, ' ', last_name)       → NULL-safe alternative to ||

 REAL-WORLD USE: Generating human-readable row labels for BI reports,
 building composite natural keys, creating email templates with SQL.
*/

SELECT
    first_name || ' ' || last_name
        || ' — '
        || department
        || ' | $'
        || salary                            AS employee_badge,
    department,
    salary
FROM employees
ORDER BY department;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q05  SUBSTRING — extracting parts of strings
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Extract the email domain from the email column.
 A domain is everything after the '@' symbol.
 Then count how many employees use each email domain.

 MENTAL MODEL:
   POSITION('@' IN email)              → index of '@' character (1-based)
   SUBSTRING(email FROM n)             → extract from position n to end
   SUBSTRING(email FROM n FOR m)       → extract m chars starting at n
   Combined: SUBSTRING(email FROM POSITION('@' IN email) + 1)

 CHEAT SHEET:
   SUBSTRING(string FROM start_pos)
   SUBSTRING(string FROM start_pos FOR length)
   SUBSTRING(string, start_pos, length)  -- same, alternative syntax

 ELEMENTARY vs PROFESSIONAL:
   ✗ Manually splitting in Python after extraction — wastes a round-trip
   ✓ Extract directly in SQL and aggregate — single query, no app code

 REAL-WORLD USE: Email domain analysis for B2B lead scoring (how many
 employees use corporate vs personal emails?), phishing detection.
*/

-- Extract domain
SELECT
    first_name,
    email,
    SUBSTRING(email FROM POSITION('@' IN email) + 1)  AS email_domain
FROM employees
WHERE email IS NOT NULL
ORDER BY email_domain;

-- Domain frequency analysis
SELECT
    SUBSTRING(email FROM POSITION('@' IN email) + 1)  AS email_domain,
    COUNT(*)                                           AS employee_count
FROM employees
WHERE email IS NOT NULL
GROUP BY email_domain
ORDER BY employee_count DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q06  POSITION — locating characters within strings
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: For each department name, find the position of the first
 lowercase 'o' character. Return 0 if not found.
 Then find the character at position 3 in every department name.

 MENTAL MODEL:
   POSITION('x' IN string)    → 1-based index; returns 0 if not found
   SUBSTRING(string, n, 1)    → single character at position n

 REAL-WORLD USE: Parsing structured strings like log lines, URLs, or
 product codes where a delimiter's position defines a segment.
*/

SELECT
    department,
    POSITION('o' IN department)              AS pos_of_o,
    SUBSTRING(department, 1, 3)             AS first_3_chars,
    POSITION('@' IN COALESCE(email, ''))    AS pos_of_at
FROM employees
ORDER BY department;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q07  REPLACE — data cleansing and standardisation
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Business rebranding scenario — the 'Clothing' department has been
 renamed to 'Apparel'. Without modifying the table, produce a view/query
 that displays the new branding everywhere.

 MENTAL MODEL:
   REPLACE(source_string, find_string, replace_string)
   Replaces ALL occurrences (not just the first).
   Case-sensitive. Use REPLACE(LOWER(col), ...) for case-insensitive replace.

 ELEMENTARY vs PROFESSIONAL:
   ✗ UPDATE table SET department = 'Apparel' — modifies source data
   ✓ REPLACE() in SELECT — non-destructive, queryable, reversible

 REAL-WORLD USE: A/B testing display labels, staging brand migrations,
 masking PII in development environments (REPLACE(email, domain, 'test.com')).
*/

SELECT
    department                                          AS original_department,
    REPLACE(department, 'Clothing', 'Apparel')          AS rebrand_department,
    first_name,
    salary
FROM employees
ORDER BY department;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q08  COALESCE — NULL replacement and default values
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Build an employee contact sheet. For employees with no email,
 display 'no-email@company.com' as a placeholder. Also use COALESCE to
 safely calculate a "display salary" where NULL salaries show 0.

 MENTAL MODEL:
   COALESCE(val1, val2, val3, ...)  → returns first non-NULL value
   COALESCE(email, 'fallback')      → email if not null, else 'fallback'
   COALESCE(salary, 0)              → salary if not null, else 0

 vs NULLIF:
   NULLIF(a, b)    → returns NULL if a = b, otherwise returns a
   Use NULLIF to prevent division by zero:
   salary / NULLIF(hours_worked, 0)   ← safe division

 CHEAT SHEET:
   COALESCE = "give me the first non-null value"
   NULLIF   = "return null if these two are equal"

 REAL-WORLD USE: Every production dashboard uses COALESCE to prevent NULL
 values from breaking aggregations (SUM of NULLs = NULL, not 0).
*/

-- Contact sheet with fallback email
SELECT
    employee_id,
    first_name || ' ' || last_name             AS full_name,
    COALESCE(email, 'no-email@company.com')    AS contact_email,
    department,
    COALESCE(salary, 0)                        AS salary
FROM employees
ORDER BY department;

-- Safe division with NULLIF (prevent divide-by-zero)
SELECT
    department,
    SUM(salary)                                           AS total_salary,
    COUNT(*)                                              AS headcount,
    SUM(salary) / NULLIF(COUNT(*), 0)                    AS avg_salary_safe
FROM employees
GROUP BY department
ORDER BY avg_salary_safe DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q09  Boolean columns — computed flags in SELECT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Create a compensation analysis table with two boolean flags:
   - is_high_earner    : salary > 100,000
   - is_senior         : hired before 2006-01-01

 MENTAL MODEL:
   (salary > 100000)             → evaluates to TRUE or FALSE
   (hire_date < '2006-01-01')    → same — boolean expression as a column

   This is extremely useful for CASE statements and conditional counting.
   In reporting: COUNT(*) FILTER (WHERE is_high_earner) can use these flags.

 REAL-WORLD USE: Feature engineering for ML models in Python/Spark — you
 first compute boolean flags in SQL, then read into a DataFrame.
*/

SELECT
    employee_id,
    first_name,
    department,
    salary,
    hire_date,
    (salary > 100000)                       AS is_high_earner,
    (hire_date < '2006-01-01')              AS is_senior,
    (department IN ('Clothing', 'Sports'))  AS is_in_target_dept
FROM employees
ORDER BY salary DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q10  LIKE / ILIKE — pattern matching in WHERE and SELECT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Marketing wants employees from 'tech' email domains (any email
 containing 'tech' anywhere). Also find departments that start with 'C'
 and are exactly 8 characters long.

 MENTAL MODEL:
   LIKE   → case-SENSITIVE match
   ILIKE  → case-INSENSITIVE match (PostgreSQL-specific)
   %      → zero or more any characters
   _      → exactly one any character

 PROFESSIONAL NOTE: LIKE with a leading wildcard ('%tech') cannot use a
 B-Tree index — it forces a full table scan. For production full-text search
 use pg_trgm indexes or a search engine (Elasticsearch).
*/

-- ILIKE for case-insensitive domain search
SELECT first_name, email, department
FROM employees
WHERE email ILIKE '%tech%'
ORDER BY first_name;

-- Positional: departments starting with 'C', exactly 8 chars
SELECT DISTINCT department
FROM employees
WHERE department LIKE 'C_______'
ORDER BY department;

-- Boolean LIKE in SELECT column
SELECT
    department,
    (department LIKE '%oth%')  AS contains_oth
FROM employees
ORDER BY department;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q11  Multi-function combination — real analytics use case
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: Build a professional employee directory export combining ALL
 string functions:
   - full_name         : INITCAP(first_name) + INITCAP(last_name)
   - email_display     : COALESCE(email, 'N/A')
   - dept_code         : First 3 chars of department, UPPER
   - has_domain        : Boolean — email contains 'google' or 'yahoo'
   - salary_label      : '$' || salary

 MENTAL MODEL: Chain functions left to right. Read outer function first,
 then work inward:
   UPPER(SUBSTRING(department, 1, 3))
   → first take substring (dept, 1, 3), THEN uppercase it.

 REAL-WORLD USE: Generating employee exports for HR systems, building
 master data management (MDM) golden records.
*/

SELECT
    INITCAP(first_name) || ' ' || INITCAP(last_name)       AS full_name,
    COALESCE(email, 'N/A')                                  AS email_display,
    UPPER(SUBSTRING(department, 1, 3))                      AS dept_code,
    (email ILIKE '%google%' OR email ILIKE '%yahoo%')       AS is_consumer_email,
    '$' || salary                                           AS salary_label,
    department,
    hire_date
FROM employees
ORDER BY dept_code, full_name;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q12  REGEXP_REPLACE — advanced string manipulation
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: You receive email addresses where the domain must be anonymised
 for GDPR compliance. Replace everything after '@' with '@redacted.com'.

 MENTAL MODEL:
   REGEXP_REPLACE(string, pattern, replacement, flags)
   flags: 'g' = global (all occurrences), 'i' = case-insensitive

   @[^ ]+ → matches @ followed by one or more non-space characters
   Replace with '@redacted.com'

 ELEMENTARY vs PROFESSIONAL:
   ✗ REPLACE(email, 'google.es', 'redacted.com')  → only works for known domain
   ✓ REGEXP_REPLACE(email, '@.+$', '@redacted.com') → works for ANY domain

 REAL-WORLD USE: GDPR/CCPA data masking pipelines, anonymising PII in
 development databases, sanitising logs before exporting to third parties.
*/

SELECT
    employee_id,
    first_name,
    email                                                   AS original_email,
    REGEXP_REPLACE(
        COALESCE(email, ''),
        '@.+$',
        '@redacted.com'
    )                                                       AS masked_email
FROM employees
WHERE email IS NOT NULL
ORDER BY first_name;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q13  Date functions — hire date analysis
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: For each employee calculate:
   - hire_year         : year they were hired
   - hire_month        : month number (1-12)
   - years_of_service  : full years from hire date to today
   - review_date       : 90 days before hire anniversary this year

 MENTAL MODEL:
   EXTRACT(YEAR FROM date)    → integer year
   EXTRACT(MONTH FROM date)   → integer month
   AGE(date)                  → interval between date and today
   EXTRACT(YEAR FROM AGE(...)) → full years of service
   date + INTERVAL '90 days'  → date arithmetic

 REAL-WORLD USE: HR anniversary notifications, contract renewal tracking,
 benefits eligibility calculation, churn risk by tenure cohort.
*/

SELECT
    employee_id,
    first_name,
    hire_date,
    EXTRACT(YEAR  FROM hire_date)                           AS hire_year,
    EXTRACT(MONTH FROM hire_date)                           AS hire_month,
    EXTRACT(YEAR  FROM AGE(hire_date))                      AS years_of_service,
    hire_date + INTERVAL '90 days'                          AS first_review_date
FROM employees
ORDER BY years_of_service DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q14  Spending pattern analysis — rolling 90-day salary window
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION: For each employee, compute the total salary of all employees
 hired in the 90 days BEFORE their own hire date. This is a "rolling
 hiring spend" pattern.

 MENTAL MODEL:
   This requires a correlated subquery:
   For each row e in the outer query, the inner query looks at e2 rows
   where e2.hire_date falls within a 90-day window ending at e.hire_date.

 NOTE: This is where correlated subqueries are actually useful — range-based
 lookback logic. The professional alternative is a window function with
 RANGE BETWEEN (see Module 05).

 REAL-WORLD USE: Rolling budget burn, customer revenue within 90 days of
 acquisition, monthly recurring revenue (MRR) lookback.
*/

SELECT
    hire_date,
    salary,
    (
        SELECT SUM(e2.salary)
        FROM employees e2
        WHERE e2.hire_date BETWEEN e.hire_date - 90 AND e.hire_date
    )  AS rolling_90day_salary_spend
FROM employees e
ORDER BY hire_date;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q15  Full string function mastery — end-to-end professor query
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/*
 QUESTION (from your professors table in course_data):
 Generate a professional faculty report:
   a) "Prof. Jones works in the History department"
   b) Salary tier flag: 'HIGHLY PAID' if > 95000, else 'STANDARD'
   c) Dept prefix (first 3 chars, uppercase)
   d) Years since hired

 MENTAL MODEL: Combine INITCAP, ||, COALESCE, CASE, SUBSTRING, UPPER,
 EXTRACT, and AGE in a single SELECT. Think of it as building a data pipeline
 transformation in a single query layer.

 REAL-WORLD USE: Faculty directory exports, university ERP integrations,
 academic compliance reporting.
*/

SET search_path TO course_data, public;

SELECT
    'Prof. ' || INITCAP(last_name) || ' works in the '
        || INITCAP(department) || ' department'            AS profile_sentence,

    UPPER(SUBSTRING(department, 1, 3))                     AS dept_code,

    salary,

    CASE
        WHEN salary > 95000 THEN 'HIGHLY PAID'
        ELSE 'STANDARD'
    END                                                    AS salary_tier,

    hire_date,
    EXTRACT(YEAR FROM AGE(hire_date))                      AS years_at_faculty
FROM professors
ORDER BY salary DESC;

SET search_path TO public;
