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


SELECT *
FROM employees
WHERE department
    IN ('Sport', 'Clothing', 'Movies', 'Outdoors', 'Toys', 'Tools')



SELECT *
FROM employees
WHERE salary BETWEEN 50000 AND 100000

