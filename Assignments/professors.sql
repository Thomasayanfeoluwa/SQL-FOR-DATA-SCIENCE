-- Use the course_data schema for the queries below.
SET search_path TO course_data, public;


-- Display all professor records.
SELECT *
FROM professors


"""Solution for Assignment: Format professor record into a descriptive sentence"""

-- Solution for Assignment: Chong works in Science
SELECT last_name || ' works in the ' || department || ' department '
    AS "Works in Science Department", (last_name = 'Chong')
FROM professors

SELECT last_name || ' works in the ' || department || ' department ' 
    AS "Works in Science Department"
FROM professors
WHERE last_name = 'Chong';

-- Solution for Assignment: Check if professors are highly paid (salary > 95000)
SELECT 'It is ' ||
    CASE WHEN salary > 95000 THEN 'true' ELSE 'false' END ||
    ' that professor ' || last_name || ' is highly paid'
    AS "Is Professor Highly Paid?"
FROM professors

-- Format the highly paid status as a sentence using a boolean expression.
SELECT 'It is ' ||
    (salary > 95000) ||
    ' that professor ' || last_name || ' is highly paid'
FROM professors



-- Display the first three uppercase letters of each department.
SELECT *,
    SUBSTRING(UPPER(department) FROM 1 FOR 3)
FROM professors

-- Display the first three uppercase letters of each department with an alias.
SELECT *,
    SUBSTRING(UPPER(department) FROM 1 FOR 3) AS "Department Prefix"
FROM professors


-- Find the highest and lowest salaries, excluding Wilson.
SELECT
    MAX(salary) AS "Highest Salary",
    MIN(salary) AS "Lowest Salary"
FROM professors
WHERE last_name <> 'Wilson';


-- Display each professor's salary alongside the overall highest and lowest salaries.
SELECT last_name,
       salary,
       MAX(salary) OVER () AS "Highest Salary",
       MIN(salary) OVER () AS "Lowest Salary"
FROM professors
WHERE last_name != 'Wilson';


-- Find the earliest hire date.
SELECT 
    MIN(hire_date) 
FROM professors



-- Return the longest-serving professor based on the earliest hire date.
SELECT 
    last_name,
    hire_date AS "Longest Hire Date"
FROM professors
ORDER BY hire_date 
LIMIT 1