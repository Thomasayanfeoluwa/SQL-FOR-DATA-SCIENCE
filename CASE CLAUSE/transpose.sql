SELECT SUM(CASE WHEN salary < 100000 THEN 1 ELSE 0 END) AS "UNDER PAID",
    SUM(CASE WHEN salary > 100000 AND salary < 150000 THEN 1 ELSE 0 END) AS "PAID WELL",
    SUM(CASE WHEN salary > 150000 THEN 1 ELSE 0 END) AS "EXECUTIVE"
FROM employees;



SELECT department, COUNT(*)
FROM employees
WHERE department IN ('Sports', 'Tools', 'Clothing', 'Computers')
GROUP BY department;


SELECT SUM(CASE WHEN department = 'Sports' THEN 1 ELSE 0 END) AS "Sports Employees",
    SUM(CASE WHEN department = 'Tools' THEN 1 ELSE 0 END) AS "Tools Employees",
    SUM(CASE WHEN department = 'Clothing' THEN 1 ELSE 0 END) AS "Clothing Employees",
    SUM(CASE WHEN department = 'Computers' THEN 1 ELSE 0 END) AS "Computers Employees"
FROM employees;



