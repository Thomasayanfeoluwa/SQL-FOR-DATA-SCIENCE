SELECT *
FROM orders

SELECT order_id,
	   sales,
	   sales * 0.07 AS "7% Sales_tax"
FROM orders
LIMIT 5;



