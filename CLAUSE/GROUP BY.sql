SELECT SUM(salary)
FROM employees
GROUP BY department;

SELECT department,
    SUM(salary)
FROM employees
GROUP BY department;

SELECT department,
    SUM(salary)
FROM employees
WHERE region_id IN (3, 5, 7)
GROUP BY department;

SELECT department,
    COUNT(employee_id)
FROM employees
GROUP BY department;

SELECT department,
    COUNT(*) AS "Employee Count"
FROM employees
GROUP BY department
ORDER BY department;


SELECT department,
    COUNT(*) AS total_number_of_employees,
    MIN(salary) AS min_salary,
    AVG(salary) AS avg_salary,
    MAX(salary) AS max_salary
FROM employees
WHERE salary > 75000
GROUP BY department
ORDER BY total_number_of_employees DESC;


SELECT department, gender, COUNT(*)
FROM employees
GROUP BY department, gender
ORDER BY department;


SELECT first_name, count(*)
FROM employees
GROUP BY first_name
HAVING COUNT(*) > 2


SELECT department
FROM employees
GROUP BY department



SELECT DISTINCT department
FROM employees


SELECT SUBSTRING(email, POSITION ('@' IN email) + 1) AS "Email Domain", COUNT(*)
FROM employees
WHERE email IS NOT NULL
GROUP BY "Email Domain"
ORDER BY COUNT(*) DESC


SELECT gender, region_id, 