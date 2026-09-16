SELECT ROW_NUMBER() OVER () AS no,
    first_name, hire_date, salary,
    SUM(salary) OVER(ORDER BY hire_date
    RANGE BETWEEN UNBOUNDED PRECEDING
    AND CURRENT ROW) AS runing_total_of_salaries
FROM employees

