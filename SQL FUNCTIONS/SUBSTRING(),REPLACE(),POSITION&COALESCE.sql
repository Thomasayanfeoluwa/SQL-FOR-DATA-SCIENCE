-- SQL script of testing SUBSTRING()
SELECT SUBSTRING('This is test data' FROM 6 FOR 7) AS "Substring Example";

SELECT SUBSTRING('This is test data' FROM 6) AS "Substring Example";


""" This SQL script demonstrates the use of SUBSTRING(), REPLACE(), POSITION(), and COALESCE() functions. """

-- QUERY 1: Using SUBSTRING() to extract a portion of a string
SELECT department,
    SUBSTRING(department, 1, 3) AS "First 3 Letters"
FROM employees

-- QUERY 2: Using REPLACE() to replace a substring within a string
SELECT department, 
    REPLACE(department, 'Clothing', 'Apparel') AS "Replaced Department"
FROM employees

-- QUERY 3: Using POSITION() to find the position of a substring within a string
SELECT department,
    POSITION('o' IN department) AS "Position of o in Department"
FROM employees

-- QUERY 4: Using COALESCE() to handle NULL values
SELECT department,
    COALESCE(email, 'No Email') AS "Email"
FROM employees


SELECT department, 
REPLACE(department, 'Clothing', 'Apparel') AS "Replaced Department",
    department || ' department ' 
FROM employees




-- QUERY 5: Combining SUBSTRING(), REPLACE(), POSITION(), and COALESCE() in a single query
SELECT SUBSTRING(first_name, 1, 3) AS "First 3 Letters", 
    REPLACE(last_name, 'a', 'A') AS "Replaced Last Name",
    POSITION('a' IN last_name) AS "Position of a in Last Name",
    COALESCE(email, 'No Email') AS "Email"
FROM employees