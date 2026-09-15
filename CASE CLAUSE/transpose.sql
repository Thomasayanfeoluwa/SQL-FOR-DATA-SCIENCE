SELECT SUM( CASE WHEN salary < 100000 THEN 1 ELSE 0 END) AS "UNDER PAID",
    SUM( CASE WHEN salary > 100000 AND salary < 150000 THEN 1 ELSE 0 END) AS "PAID WELL",
    SUM( CASE WHEN salary > 150000 THEN 1 ELSE 0 END) AS "EXECUTIVE"
FROM employees



SELECT department, COUNT(*)
FROM employees
WHERE department IN ('Sport', 'Tools', 'Clothing', 'Computers')
GROUP BY department


SELECT SUM( CASE WHEN salary)