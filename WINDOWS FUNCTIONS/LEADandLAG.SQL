SELECT first_name, last_name, salary,
    LEAD(salary) OVER() next_salary
FROM employees

SELECT first_name, last_name, salary,
    LAG(salary) OVER() previous_salary
FROM employees

SELECT first_name, last_name, salary,
    LAG(salary) OVER(ORDER BY salary DESC) closest_higher_salary
FROM employees

SELECT first_name, last_name, salary,
    LEAD(salary) OVER(ORDER BY salary DESC) closest_lowest_salary
FROM employees

