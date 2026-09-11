SELECT department, COUNT(*)
FROM employees
GROUP BY department
HAVING COUNT(*) > 35
ORDER BY department;


SELECT department, gender,
    AVG(salary) AS "Average Salary"
FROM employees 
GROUP BY department, gender, salary
HAVING department = 'Clothing'
ORDER BY salary;


