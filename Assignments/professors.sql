SET search_path TO course_data, public;


SELECT *
FROM professors

SELECT last_name || 'works in the ' || department || AS "Works in Science Department", (last_name = 'Chong')
FROM professors

SELECT last_name || ' ' || department AS "Works in Science Department"
FROM professors
WHERE last_name = 'Chong'


-- Boolean expressions
SELECT first_name || ' ' || last_name AS "Full Name", department, (salary > 100000) AS "High Salary"
FROM employees
ORDER BY salary DESC

-- Boolean expressions USING IN
SELECT department, ('Clothing' IN (department)) AS "In Clothing Department"
FROM employees

SELECT department, (department IN ('Clothing', 'Sports')) AS "In Clothing or Sports"
FROM employees

