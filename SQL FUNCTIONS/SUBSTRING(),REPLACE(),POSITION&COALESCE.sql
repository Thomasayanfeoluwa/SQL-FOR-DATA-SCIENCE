SELECT SUBSTRING('This is test data' FROM 6 FOR ) AS "Substring Example";








SELECT SUBSTRING(first_name, 1, 3) AS "First 3 Letters", 
    REPLACE(last_name, 'a', 'A') AS "Replaced Last Name",
    POSITION('a' IN last_name) AS "Position of a in Last Name",
    COALESCE(email, 'No Email') AS "Email"
FROM employees