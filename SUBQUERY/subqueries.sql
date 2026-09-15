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

SELECT salary, COUNT(*)
    FROM employees
    GROUP BY salary
    ORDER BY COUNT(*) DESC, salary DESC


SELECT salary
FROM (
    SELECT salary, COUNT(*)
    FROM employees
    GROUP BY salary
    ORDER BY COUNT(*) DESC, salary DESC
) a

SELECT salary
FROM employees
GROUP BY salary
HAVING COUNT(*) >= ALL (
    SELECT COUNT(*)
    FROM employees
    GROUP BY salary
)
ORDER BY salary DESC;


SELECT ROUND(AVG(salary)) AS "Average Salary"
FROM employees
WHERE salary NOT IN(
    (SELECT MIN(salary)
    FROM employees),
    (SELECT MAX(salary)
    FROM employees)
);



