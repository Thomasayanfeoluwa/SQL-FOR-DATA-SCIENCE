SELECT department, COUNT(*)
FROM employees
GROUP BY department
HAVING COUNT(*) > 35
ORDER BY department


SELECT department, salary, gender
FROM employees
GROUP BY department
HAVING 