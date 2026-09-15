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
FROM employees
WHERE region_id > ALL (
    SELECT region_id
    FROM regions
    WHERE country = 'West Africa'
    )

SELECT *
FROM employees
WHERE region_id <> ALL (
    SELECT region_id
    FROM regions
    WHERE country = 'West Africa'
    )



SELECT *
FROM employees
WHERE department = ANY (
    SELECT department
    FROM departments
    WHERE division = 'Kids'
    )
    AND hire_date > ALL (
        SELECT hire_date
        FROM employees
        WHERE department = 'Maintenance')