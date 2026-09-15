SELECT department
FROM employees
UNION
SELECT department
FROM departments
LIMIT 10

