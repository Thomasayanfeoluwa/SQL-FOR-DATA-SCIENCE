SELECT COUNT(*)
FROM (
    SELECT *
    FROM employees, departments
    )a

SELECT *
FROM departments

SELECT COUNT(*) 
FROM (
    SELECT *
    FROM employees a, employees b, departments
) sub

SELECT *
FROM employees, departments

SELECT *
FROM employees a CROSS JOIN departments b

