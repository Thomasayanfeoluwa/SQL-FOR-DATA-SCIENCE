-- SELECT datname FROM pg_database;

SELECT current_database(), current_schema();

SHOW search_path;


-- SELECT table_schema, table_name
-- FROM information_schema.tables
-- WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
-- ORDER BY table_schema, table_name;


-- SELECT table_schema, table_name
-- FROM information_schema.tables
-- WHERE table_name = 'employees';