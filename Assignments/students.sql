SET search_path TO course_data, public;


SELECT student_name, age
FROM students
WHERE age BETWEEN 18 AND 20
ORDER BY age;

SELECT student_name  
FROM students
WHERE student_name LIKE '%ch%' OR student_name LIKE '%nd';

SELECT student_name
FROM students
WHERE student_name
    LIKE '%ae%' AND student_name LIKE '%ph% ' AND age != 19;


SELECT student_name, age
FROM students
ORDER BY age DESC;

SELECT student_name, age
FROM students
ORDER BY age DESC
LIMIT 5;

SELECT student_name, age
FROM students
WHERE age <= 20 AND (student_no BETWEEN 3 AND 5 OR student_no = 7)
    OR (age > 20 AND student_no >= 5);

