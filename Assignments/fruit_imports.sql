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
GROUP BY state, name
HAVING COUNT(name) > 1;



SELECT season, COUNT(name) AS "Products Per Season"
FROM fruits
GROUP BY season
HAVING COUNT(season) = 3 OR COUNT(season) = 4;



SELECT supply, cost_per_unit