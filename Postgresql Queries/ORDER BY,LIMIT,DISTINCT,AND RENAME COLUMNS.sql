SELECT *
FROM employees
ORDER BY employee_id DESC

SELECT *
FROM employees
ORDER BY department 

SELECT *
FROM employees
ORDER BY salary DESC

-- Return the distinct departments of employees in the employees table, ordered alphabetically.
SELECT DISTINCT department
FROM employees
ORDER BY department

-- Return the distinct departments of employees in the employees table, ordered alphabetically, and limit the results to 5 rows.
SELECT DISTINCT department
FROM employees
ORDER BY department
LIMIT 5