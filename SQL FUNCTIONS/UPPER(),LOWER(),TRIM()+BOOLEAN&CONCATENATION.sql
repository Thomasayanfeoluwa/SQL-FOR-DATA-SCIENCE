SELECT UPPER(first_name), LOWER(last_name)
FROM employees

SELECT LENGTH(first_name), LOWER(last_name)
FROM employees

SELECT ('  HELLO THERE  ')

SELECT TRIM('  HELLO THERE  ')

SELECT LENGTH(TRIM('  HELLO THERE  '))



-- Concatenating strings
SELECT 
    first_name || last_name
FROM employees


SELECT first_name || ' ' || last_name AS "Full Name", department, salary
FROM employees

-- Boolean expressions
SELECT first_name || ' ' || last_name AS "Full Name", department, (salary > 100000) AS "High Salary"
FROM employees
ORDER BY salary DESC

-- Boolean expressions USING IN
SELECT department, ('Clothing' IN (department)) AS "In Clothing Department"
FROM employees

SELECT department, (department IN ('Clothing', 'Sports')) AS "In Clothing or Sports"
FROM employees

-- Boolean expressions USING LIKE
SELECT department, (department LIKE '%oth%') AS "Contains oth"
FROM employees

