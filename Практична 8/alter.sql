-- Run after practice-07/schema.sql and practice-08/schema.sql, on database college.
-- 1. ALTER on existing college.courses; operations return to original state.
ALTER TABLE college.courses ADD COLUMN description TEXT;
ALTER TABLE college.courses ALTER COLUMN description SET DEFAULT 'опис відсутній';
SELECT column_name, column_default FROM information_schema.columns
 WHERE table_schema='college' AND table_name='courses' AND column_name='description';
ALTER TABLE college.courses DROP COLUMN description;
-- 2. TRUNCATE preserves table, DROP removes it.
DROP TABLE IF EXISTS college.ddl_demo;
CREATE TABLE college.ddl_demo(id INTEGER PRIMARY KEY, label TEXT);
INSERT INTO college.ddl_demo VALUES (1,'one'),(2,'two');
SELECT COUNT(*) AS before_truncate FROM college.ddl_demo; -- 2
TRUNCATE TABLE college.ddl_demo;
SELECT COUNT(*) AS after_truncate FROM college.ddl_demo; -- 0
SELECT table_name FROM information_schema.tables WHERE table_schema='college' AND table_name='ddl_demo';
DROP TABLE college.ddl_demo;
SELECT table_name FROM information_schema.tables WHERE table_schema='college' AND table_name='ddl_demo'; -- no rows
-- 3. Dependency demonstration: capture PostgreSQL error without aborting script.
DO $$ BEGIN
 BEGIN
  EXECUTE 'DROP TABLE college.departments';
 EXCEPTION WHEN dependent_objects_still_exist THEN
  RAISE NOTICE 'Expected dependency error (SQLSTATE %): %', SQLSTATE, SQLERRM;
 END;
END $$;
