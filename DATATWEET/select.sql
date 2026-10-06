SELECT *
FROM orders

SELECT order_id,
	   sales,
	   ROUND(sales * 0.07, 2) AS "7% Sales_tax"
FROM orders
LIMIT 5;



SELECT order_id,
	   ROUND(sales, 2) AS "rounded_sales",
	   ROUND(sales * 0.07, 2) AS "7% rounded_sales_tax"
FROM orders
LIMIT 5;


SELECT ship_mode AS 'original_ship_mode',
	UPPER(ship_mode) AS 'upper_ship_mode'
FROM orders
LIMIT 5;



SELECT city || " " || state_province AS location
FROM orders
LIMIT 5;



SELECT city || ", " || state_province AS location
FROM orders
LIMIT 5;


SELECT "superstore " || city AS location
FROM orders
LIMIT 5;


SELECT sales, 2 AS promotional_discount
  FROM orders
 LIMIT 5;