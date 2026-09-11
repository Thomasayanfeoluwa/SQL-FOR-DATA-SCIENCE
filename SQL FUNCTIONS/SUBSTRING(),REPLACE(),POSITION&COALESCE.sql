-- SQL script of testing SUBSTRING()
SELECT SUBSTRING('This is test data' FROM 6 FOR 7) AS "Substring Example";

SELECT SUBSTRING('This is test data' FROM 6) AS "Substring Example";






-- This SQL script demonstrates the use of SUBSTRING(), REPLACE(), POSITION(), and COALESCE() functions.
SELECT SUBSTRING(first_name, 1, 3) AS "First 3 Letters", 
    REPLACE(last_name, 'a', 'A') AS "Replaced Last Name",
    POSITION('a' IN last_name) AS "Position of a in Last Name",
    COALESCE(email, 'No Email') AS "Email"
FROM employees