SELECT state, 
    supply AS "Largest Fruit Supply"
FROM fruits
GROUP BY state, supply
ORDER BY SUM(supply) DESC
LIMIT 1;



SELECT season, MAX(cost_per_unit) "Most Expensive Cost per_unit"
FROM fruits
GROUP BY season;



SELECT state
FROM fruits
GROUP BY state, anme
HAVING COUNT(name) > 1

