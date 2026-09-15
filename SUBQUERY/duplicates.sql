SELECT DISTINCT(name)
FROM dupes
GROUP BY name

SELECT *
FROM dupes
WHERE id IN (
    SELECT MIN(id)
    FROM dupes
    GROUP BY name
);


