-- SQLBook: Code
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




SELECT first_name,
    CASE WHEN region_id = 1 THEN (SELECT country
        FROM regions WHERE region_id = 1) END AS "Region 1",
    CASE WHEN region_id = 2 THEN (SELECT country
        FROM regions WHERE region_id = 2) END AS "Region 2",
    CASE WHEN region_id = 3 THEN (SELECT country
        FROM regions WHERE region_id = 3) END AS "Region 3",
    CASE WHEN region_id = 4 THEN (SELECT country
        FROM regions WHERE region_id = 4) END AS "Region 4",
    CASE WHEN region_id = 5 THEN (SELECT country
        FROM regions WHERE region_id = 5) END AS "Region 5",
    CASE WHEN region_id = 6 THEN (SELECT country
        FROM regions WHERE region_id = 6) END AS "Region 6",
    CASE WHEN region_id = 7 THEN (SELECT country
        FROM regions WHERE region_id = 7) END AS "Region 7"
FROM employees;



SELECT COUNT(a."Region 1") + COUNT(a."Region 2") +
    COUNT(a."Region 3") + COUNT(a."Region 6") +
    COUNT(a."Region 7") AS "United States",
    COUNT(a."Region 4") + COUNT(a."Region 5") AS "West Africa"
FROM (
    SELECT first_name,
    CASE WHEN region_id = 1 THEN (SELECT country FROM regions WHERE region_id = 1) END AS "Region 1",
    CASE WHEN region_id = 2 THEN (SELECT country FROM regions WHERE region_id = 2) END AS "Region 2",
    CASE WHEN region_id = 3 THEN (SELECT country FROM regions WHERE region_id = 3) END AS "Region 3",
    CASE WHEN region_id = 4 THEN (SELECT country FROM regions WHERE region_id = 4) END AS "Region 4",
    CASE WHEN region_id = 5 THEN (SELECT country FROM regions WHERE region_id = 5) END AS "Region 5",
    CASE WHEN region_id = 6 THEN (SELECT country FROM regions WHERE region_id = 6) END AS "Region 6",
    CASE WHEN region_id = 7 THEN (SELECT country FROM regions WHERE region_id = 7) END AS "Region 7"
    FROM employees
) a;





-- SQLBook: Code
SELECT COUNT(a."Region 1") + COUNT(a."Region 2") +
    COUNT(a."Region 3") + COUNT(a."Region 6") +
    COUNT(a."Region 7") AS "United States",
    COUNT(a."Region 4") + COUNT(a."Region 5") AS "West Africa"
FROM (
    SELECT first_name,
    CASE WHEN region_id = 1 THEN (SELECT country FROM regions WHERE region_id = 1) END AS "Region 1",
    CASE WHEN region_id = 2 THEN (SELECT country FROM regions WHERE region_id = 2) END AS "Region 2",
    CASE WHEN region_id = 3 THEN (SELECT country FROM regions WHERE region_id = 3) END AS "Region 3",
    CASE WHEN region_id = 4 THEN (SELECT country FROM regions WHERE region_id = 4) END AS "Region 4",
    CASE WHEN region_id = 5 THEN (SELECT country FROM regions WHERE region_id = 5) END AS "Region 5",
    CASE WHEN region_id = 6 THEN (SELECT country FROM regions WHERE region_id = 6) END AS "Region 6",
    CASE WHEN region_id = 7 THEN (SELECT country FROM regions WHERE region_id = 7) END AS "Region 7"
    FROM employees
) a;

-- SQLBook: Code