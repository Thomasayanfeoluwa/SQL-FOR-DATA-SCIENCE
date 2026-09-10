SELECT * 
FROM employees
WHERE
    department = 'Beauty'
    AND(region_id = 3
    OR salary > 50000)


SELECT 
    employee_id,
    first_name,
    department,
    email
FROM employees
WHERE salary > 50000


-- Return the first name and email of female employees that work in the Tools department and earn more than 100,000.
SELECT
    first_name,
    email
FROM employees
WHERE 
    gender = 'F'
    AND department = 'Tools'
    AND salary > 100000;

-- Return the first name, hire date, and salary of employees that earn more than 150,000 or are male employees in the Sports department.
SELECT 
    first_name,
    hire_date,
    salary
FROM employees
WHERE
    salary > 150000
    OR (department = 'Sports'
    AND gender = 'M'
    );
    

-- Return the first name and hire date of employees that were hired between January 1, 2002 and January 1, 2004.
SELECT
    first_name,
    hire_date
FROM employees
WHERE
    hire_date 
    BETWEEN '2002-01-01'
    AND '2004-01-01';


-- Return the first name, department, and salary of male employees that work in the Automotive department
--  and earn between 30,000 and 100,000, and female employees that work in the Toys department.
SELECT *
FROM employees
WHERE
    salary > 30000
    AND salary < 100000
    AND department = 'Automotive'
    AND gender = 'M'
    OR (gender = 'F' AND department = 'Toys');