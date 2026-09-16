SELECT *
FROM employees

-- This is too expensive on a large dataset, therfore; a WINDOW FUNCTION is prefferred
SELECT first_name, department,
    (SELECT COUNT(*)
    FROM employees e1
    WHERE e1.department = e.department)
FROM employees e
GROUP BY department, first_name

SELECT first_name, department,
COUNT(*) OVER(PARTITION BY department)
FROM employees

SELECT first_name, department,
SUM(salary) OVER(PARTITION BY department)
FROM employees

SELECT first_name, department,
SUM(salary) OVER()
FROM employees

SELECT first_name, department,
COUNT(*) OVER(PARTITION BY department) dept_count,
COUNT(*) OVER(PARTITION BY region_id) reg_count
FROM employees

