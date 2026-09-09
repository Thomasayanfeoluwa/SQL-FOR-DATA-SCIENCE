DROP SCHEMA IF EXISTS courses CASCADE;
DROP SCHEMA IF EXISTS student_enrollment CASCADE;
DROP SCHEMA IF EXISTS professors CASCADE;
DROP SCHEMA IF EXISTS teach CASCADE;
DROP SCHEMA IF EXISTS student CASCADE;
DROP SCHEMA IF EXISTS course_data CASCADE;

CREATE SCHEMA IF NOT EXISTS course_data;

CREATE TABLE IF NOT EXISTS course_data.students (
	student_no INT,
	student_name VARCHAR(20),
	age INT
);

INSERT INTO course_data.students VALUES (1, 'Michael', 19);
INSERT INTO course_data.students VALUES (2, 'Doug', 18);
INSERT INTO course_data.students VALUES (3, 'Samantha', 21);
INSERT INTO course_data.students VALUES (4, 'Pete', 20);
INSERT INTO course_data.students VALUES (5, 'Ralph', 19);
INSERT INTO course_data.students VALUES (6, 'Arnold', 22);
INSERT INTO course_data.students VALUES (7, 'Michael', 19);
INSERT INTO course_data.students VALUES (8, 'Jack', 19);
INSERT INTO course_data.students VALUES (9, 'Rand', 17);
INSERT INTO course_data.students VALUES (10, 'Sylvia', 20);

CREATE TABLE IF NOT EXISTS course_data.courses (
	course_no VARCHAR(5),
	course_title VARCHAR(20),
	credits INT
);

INSERT INTO course_data.courses VALUES ('CS110', 'Pre Calculus', 4);
INSERT INTO course_data.courses VALUES ('CS180', 'Physics', 4);
INSERT INTO course_data.courses VALUES ('CS107', 'Intro to Psychology', 3);
INSERT INTO course_data.courses VALUES ('CS210', 'Art History', 3);
INSERT INTO course_data.courses VALUES ('CS220', 'US History', 3);

CREATE TABLE IF NOT EXISTS course_data.student_enrollment (
	student_no INT,
	course_no VARCHAR(5)
);

INSERT INTO course_data.student_enrollment VALUES (1, 'CS110');
INSERT INTO course_data.student_enrollment VALUES (1, 'CS180');
INSERT INTO course_data.student_enrollment VALUES (1, 'CS210');
INSERT INTO course_data.student_enrollment VALUES (2, 'CS107');
INSERT INTO course_data.student_enrollment VALUES (2, 'CS220');
INSERT INTO course_data.student_enrollment VALUES (3, 'CS110');
INSERT INTO course_data.student_enrollment VALUES (3, 'CS180');
INSERT INTO course_data.student_enrollment VALUES (4, 'CS220');
INSERT INTO course_data.student_enrollment VALUES (5, 'CS110');
INSERT INTO course_data.student_enrollment VALUES (5, 'CS180');
INSERT INTO course_data.student_enrollment VALUES (5, 'CS210');
INSERT INTO course_data.student_enrollment VALUES (5, 'CS220');
INSERT INTO course_data.student_enrollment VALUES (6, 'CS110');
INSERT INTO course_data.student_enrollment VALUES (7, 'CS110');
INSERT INTO course_data.student_enrollment VALUES (7, 'CS210');

CREATE TABLE IF NOT EXISTS course_data.professors (
	last_name VARCHAR(20),
	department VARCHAR(12),
	salary INT,
	hire_date DATE
);

INSERT INTO course_data.professors VALUES ('Chong', 'Science', 88000, '2006-04-18');
INSERT INTO course_data.professors VALUES ('Brown', 'Math', 97000, '2002-08-22');
INSERT INTO course_data.professors VALUES ('Jones', 'History', 67000, '2009-11-17');
INSERT INTO course_data.professors VALUES ('Wilson', 'Astronomy', 110000, '2005-01-15');
INSERT INTO course_data.professors VALUES ('Miller', 'Agriculture', 82000, '2008-05-08');
INSERT INTO course_data.professors VALUES ('Williams', 'Law', 105000, '2001-06-05');

CREATE TABLE IF NOT EXISTS course_data.teach (
	last_name VARCHAR(20),
	course_no VARCHAR(5)
);

INSERT INTO course_data.teach VALUES ('Chong', 'CS180');
INSERT INTO course_data.teach VALUES ('Brown', 'CS110');
INSERT INTO course_data.teach VALUES ('Brown', 'CS180');
INSERT INTO course_data.teach VALUES ('Jones', 'CS210');
INSERT INTO course_data.teach VALUES ('Jones', 'CS220');
INSERT INTO course_data.teach VALUES ('Wilson', 'CS110');
INSERT INTO course_data.teach VALUES ('Wilson', 'CS180');
INSERT INTO course_data.teach VALUES ('Williams', 'CS107');