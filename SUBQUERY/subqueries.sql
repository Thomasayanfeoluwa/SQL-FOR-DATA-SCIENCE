SELECT *
FROM employees
WHERE department NOT IN 
    (SELECT department
    FROM departments);





