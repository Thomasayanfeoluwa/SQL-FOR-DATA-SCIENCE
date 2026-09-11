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
SELECT first_name || ' ' || last_name AS "Full Name", department, LENGTH(salary > 100000) AS "High Salary"
FROM employees
