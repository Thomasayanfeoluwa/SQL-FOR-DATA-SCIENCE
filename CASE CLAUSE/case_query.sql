SELECT first_name, salary,
CASE
    WHEN salary < 100000 THEN 'UNDER PAID'
    WHEN salary > 100000 THEN 'WELL PAID'
    ELSE 'UNPAID'
END
FROM employees
ORDER BY salary DESC;



SELECT first_name, salary,
CASE
    WHEN salary < 100000 THEN 'UNDER PAID'
    WHEN salary > 100000 THEN 'WELL PAID'
    ELSE 'UNPAID'
END
FROM employees
ORDER BY salary;


SELECT first_name, salary,
CASE
    WHEN salary < 100000 THEN 'UNDER PAID'
    WHEN salary > 100000 AND salary < 160000 THEN 'PAID WELL'
    ELSE 'EXECUTIVES'
END
FROM employees
ORDER BY salary DESC;


SELECT first_name, salary,
CASE
    WHEN salary < 100000 THEN 'UNDER PAID'
    WHEN salary > 100000 AND salary < 160000 THEN 'PAID WELL'
    WHEN salary > 160000 THEN 'EXECUTIVE'
    ELSE 'UNPAID'
END AS category
FROM employees
ORDER BY salary DESC;


SELECT a.category, COUNT(*) FROM (
    SELECT first_name, salary,
    CASE
        WHEN salary < 100000 THEN 'UNDER PAID'
        WHEN salary > 100000 AND salary < 160000 THEN 'PAID WELL'
        WHEN salary > 160000 THEN 'EXECUTIVE'
        ELSE 'UNPAID'
    END AS category
    FROM employees
    ORDER BY salary DESC
    )a
GROUP BY a.category