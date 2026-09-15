SELECT department
FROM employees
UNION
SELECT department
FROM departments
LIMIT 15

SELECT department
FROM employees
UNION ALL
SELECT department
FROM departments
LIMIT 15

