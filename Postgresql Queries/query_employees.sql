SELECT *
FROM employees
WHERE 
    department = 'Tools'
    AND region_id = 3
    -- AND salary > 50000
    OR salary > 100000
    

SELECT * 
FROM employees
WHERE
    department = 'Beauty'
    AND(region_id = 3
    OR salary > 50000)


SELECT *
FROM employees
WHERE
    department IN ('Sports', 'Clothing')


SELECT *
FROM employees
WHERE
    department NOT IN ('Sports', 'Clothing')



SELECT *
FROM employees
WHERE
    department <> 'Movies'



SELECT *
FROM employees
WHERE email IS NULL


SELECT *
FROM employees
WHERE email IS NOT NULL