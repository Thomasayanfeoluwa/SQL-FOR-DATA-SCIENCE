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

