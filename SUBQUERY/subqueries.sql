SELECT *
FROM employees
WHERE department NOT IN 
    (SELECT department
    FROM departments);


SELECT *
FROM employees
WHERE region_id IN (
    SELECT region_id
    FROM regions
    WHERE country = 'America'
    );

