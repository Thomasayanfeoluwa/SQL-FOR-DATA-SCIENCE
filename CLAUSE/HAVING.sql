SELECT department, COUNT(*)
FROM employees
GROUP BY department
HAVING COUNT(*) > 35
ORDER BY department;


SELECT department, gender, salary
FROM employees
GROUP BY department, gender
HAVING salary > 90000
ORDER BY salary;