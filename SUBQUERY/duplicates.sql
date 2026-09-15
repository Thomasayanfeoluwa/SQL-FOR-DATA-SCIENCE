SELECT DISTINCT(name)
FROM dupes
GROUP BY name;

SELECT *
FROM dupes
WHERE id IN (
    SELECT MIN(id)
    FROM dupes
    GROUP BY name
);

DELETE FROM dupes
WHERE id NOT IN (
    SELECT MIN(id)
    FROM dupes
    GROUP BY name
);


SELECT DISTINCT(name), id
FROM dupes
GROUP BY name, id;