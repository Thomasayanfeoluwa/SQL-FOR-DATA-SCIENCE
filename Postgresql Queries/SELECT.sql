SELECT *
FROM employees
WHERE 
    department = 'Tools'
    AND region_id = 3
    -- AND salary > 50000
    OR salary > 100000
    

