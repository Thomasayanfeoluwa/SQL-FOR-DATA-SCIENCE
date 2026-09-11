-- QUERY 1: Get the maximun salary
SELECT MAX(salary)
FROM employees

-- QUERY 2: Get the minimun salary
SELECT MIN(salary)
FROM employees

-- QUERY 3: Get the average salary
SELECT AVG(salary)
FROM employees

-- QUERY 4: Get the average salary as a whole number
SELECT ROUND(AVG(salary))
FROM employees

-- QUERY 5: Get the average salary as in 2 decimal number
SELECT ROUND(AVG(salary), 2)
FROM employees

-- QUERY 6: Get the total count of employee_id
SELECT COUNT(employee_id)
FROM employees

-- QUERY 7: Get the total count of email
SELECT COUNT(email)
FROM employees

-- QUERY 8: Get the total count of the rows in the employees' table
SELECT COUNT(*)
FROM employees

-- QUERY 9: Get the total salary paid to all the employees
SELECT SUM(salary)
FROM employees

SELECT SUM(salary)
FROM employees
WHERE department = 'Tools'

SELECT SUM(salary)
FROM employees
WHERE department = 'Children Clothing'