-- Active: 1788967706440@@127.0.0.1@5432@SQL FOR DATA SCIENCE
SELECT department
FROM employees
UNION
SELECT department
FROM departments
LIMIT 15;

SELECT department
FROM employees
UNION ALL
SELECT department
FROM departments
LIMIT 15;

SELECT department, first_name
FROM employees
UNION
SELECT department, division
FROM departments
ORDER BY department;

SELECT department
FROM employees
UNION ALL
SELECT department
FROM departments
UNION
SELECT country
FROM regions
ORDER BY department;

SELECT DISTINCT department
FROM employees
EXCEPT
SELECT department
FROM departments;

SELECT department
FROM departments
EXCEPT
SELECT DISTINCT department
FROM employees

SELECT department, COUNT(*)
FROM employees
GROUP BY department
UNION ALL
SELECT 'TOTAL', COUNT(*)
FROM employees
ORDER BY department

