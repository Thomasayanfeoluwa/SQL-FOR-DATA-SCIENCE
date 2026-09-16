SELECT *
FROM sales
ORDER BY continent, country, city

SELECT continent, SUM(units_sold)
FROM sales
GROUP BY continent

SELECT country, SUM(units_sold)
FROM sales
GROUP BY country

SELECT city, SUM(units_sold)
FROM sales
GROUP BY city

SELECT continent, country, city, SUM(units_sold)
FROM sales
GROUP BY GROUPING SETS(continent, country, city)

SELECT continent, country, city, SUM(units_sold)
FROM sales
GROUP BY GROUPING SETS(continent, country, city, ())

SELECT continent, country, city, SUM(units_sold)
FROM sales
GROUP BY ROLLUP(continent, country, city)

SELECT continent, country, city, SUM(units_sold)
FROM sales
GROUP BY CUBE(continent, country, city)

