SELECT department
FROM employees
UNION
SELECT department
FROM departments
LIMIT 10

SELECT row_number() OVER (ORDER BY department) AS row_no, department
FROM (
    SELECT department
    FROM employees
    UNION
    SELECT department
    FROM departments
) AS combined
LIMIT 10;

