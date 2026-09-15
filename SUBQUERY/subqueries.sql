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

SELECT *
FROM employees
WHERE region_id > ANY (
    SELECT region_id
    FROM regions
    WHERE country = 'West Africa'
    )


SELECT *
FROM regions