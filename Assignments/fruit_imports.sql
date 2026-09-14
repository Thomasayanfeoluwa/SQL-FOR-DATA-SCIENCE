SELECT state, 
    MAX(supply) AS "Largest Fruit Supply"
FROM fruits
GROUP BY state, supply
ORDER BY supply DESC
LIMIT 1;


SELECT 



