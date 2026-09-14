SELECT current_database(), current_schema();


CREATE TABLE fruit_imports
(
        id INT,
        name VARCHAR(20),
        season VARCHAR(10),
        state VARCHAR(20),
        supply INT,
        cost_per_unit DECIMAL
);


CREATE TABLE fruit_imports
(
	id INT,
	name VARCHAR(20),
	season VARCHAR(10),
	state VARCHAR(20),
	supply INT,
	cost_per_unit DECIMAL
);

INSERT INTO fruit_imports VALUES (1, 'Apple', 'All Year', 'Kansas', 32900, 0.22);
INSERT INTO fruit_imports VALUES (2, 'Avocado', 'All Year', 'Nebraska', 27000, 0.15);
INSERT INTO fruit_imports VALUES (3, 'Coconut', 'All Year', 'California', 15200, 0.75);
INSERT INTO fruit_imports VALUES (4, 'Orange', 'Winter', 'California', 17000, 0.22);
INSERT INTO fruit_imports VALUES (5, 'Pear', 'Winter', 'Iowa', 37250, 0.17);
INSERT INTO fruit_imports VALUES (6, 'Lime', 'Spring', 'Indiana', 40400, 0.15);
INSERT INTO fruit_imports VALUES (7, 'Mango', 'Spring', 'Texas', 13650, 0.60);
INSERT INTO fruit_imports VALUES (8, 'Orange', 'Spring', 'Iowa', 18000, 0.26);
INSERT INTO fruit_imports VALUES (9, 'Apricot', 'Spring', 'Indiana', 55000, 0.20);
INSERT INTO fruit_imports VALUES (10, 'Cherry', 'Summer', 'Texas', 62150, 0.02);
INSERT INTO fruit_imports VALUES (11, 'Cantaloupe', 'Summer', 'Texas', 8000, 0.49);
INSERT INTO fruit_imports VALUES (12, 'Apricot', 'Summer', 'Kansas', 14500, 0.20);
INSERT INTO fruit_imports VALUES (13, 'Mango', 'Summer', 'Texas', 17000, 0.68);
INSERT INTO fruit_imports VALUES (14, 'Pear', 'Fall', 'Nebraska', 30500, 0.12);
INSERT INTO fruit_imports VALUES (15, 'Grape', 'Fall', 'Illinois', 72500, 0.35);