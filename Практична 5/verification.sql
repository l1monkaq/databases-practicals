-- Запускати в Query Tool, обравши базу college.
SELECT version() AS postgres_version,
       current_database() AS database_name,
       current_user AS username;

SELECT current_database() AS database_name,
       current_user AS username;

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'college';
