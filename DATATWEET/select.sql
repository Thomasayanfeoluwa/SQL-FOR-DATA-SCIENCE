SELECT *
FROM orders

SELECT order_id,
	   sales,
	   sales * 0.7 AS "7% Old Sales"
FROM orders
LIMIT 5;

