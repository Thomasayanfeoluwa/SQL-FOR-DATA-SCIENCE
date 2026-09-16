SELECT first_name, last_name, salary,
    LEAD(salary) OVER() next_salary
FROM employees

SELECT first_name, last_name, salary,
    LEAD(salary) OVER() next_salary
FROM employees