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


SELECT city || ", " || state_province || " " || postal_code AS "address",
	sales,
	ROUND(sales * 0.07, 2) AS sales_tax,
	4.99 AS shipping_cost,
	ROUND(sales + 4.99 + sales * 0.07, 2) AS total_cost
FROM orders;


SELECT order_id, 
	sales, profit,
	ROUND(profit / sales, 2) AS "profit_margin"
FROM orders
LIMIT 8;


SELECT order_id,
	sales, quantity,
	ROUND(sales / quantity, 2) AS "price_per_unit"
FROM orders
LIMIT 10