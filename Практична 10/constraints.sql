-- Standalone integrity demonstrations; run in database college AFTER practice-07/schema.sql.
-- Uses own schema; expected violations are caught and reported as NOTICEs.
CREATE SCHEMA IF NOT EXISTS integrity_demo;
DROP TABLE IF EXISTS integrity_demo.children, integrity_demo.parents, integrity_demo.samples CASCADE;
CREATE TABLE integrity_demo.parents (
 parent_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 code VARCHAR(10) NOT NULL UNIQUE
);
CREATE TABLE integrity_demo.children (
 child_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 parent_id INTEGER NOT NULL REFERENCES integrity_demo.parents(parent_id) ON DELETE CASCADE,
 label TEXT NOT NULL DEFAULT 'новий'
);
CREATE TABLE integrity_demo.samples (
 id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 ref_code VARCHAR(10) UNIQUE,
 parent_id INTEGER NOT NULL REFERENCES integrity_demo.parents(parent_id) ON DELETE RESTRICT,
 score SMALLINT NOT NULL DEFAULT 50 CHECK (score BETWEEN 0 AND 100),
 title TEXT NOT NULL
);
INSERT INTO integrity_demo.parents(code) VALUES ('A'),('B');
INSERT INTO integrity_demo.samples(ref_code,parent_id,title) VALUES ('ONE',1,'valid');
-- Check DEFAULT is applied when score is omitted.
SELECT id,score FROM integrity_demo.samples ORDER BY id;
-- Multiple NULL ref_code values are allowed by ordinary UNIQUE.
INSERT INTO integrity_demo.samples(ref_code,parent_id,title) VALUES (NULL,1,'null-one'),(NULL,1,'null-two');
SELECT COUNT(*) AS null_unique_rows FROM integrity_demo.samples WHERE ref_code IS NULL; -- 2
-- Each expected error is intentionally trapped; table contents remain valid.
DO $$ BEGIN
 BEGIN INSERT INTO integrity_demo.samples(id,ref_code,parent_id,title) OVERRIDING SYSTEM VALUE VALUES (1,'TWO',1,'pk bad');
 EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PRIMARY KEY SQLSTATE %: %', SQLSTATE, SQLERRM; END;
 BEGIN INSERT INTO integrity_demo.samples(ref_code,parent_id,title) VALUES ('ONE',1,'unique bad');
 EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'UNIQUE SQLSTATE %: %', SQLSTATE, SQLERRM; END;
 BEGIN INSERT INTO integrity_demo.samples(ref_code,parent_id,title) VALUES ('FK',999,'fk bad');
 EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'FOREIGN KEY SQLSTATE %: %', SQLSTATE, SQLERRM; END;
 BEGIN INSERT INTO integrity_demo.samples(ref_code,parent_id,title) VALUES ('NN',1,NULL);
 EXCEPTION WHEN not_null_violation THEN RAISE NOTICE 'NOT NULL SQLSTATE %: %', SQLSTATE, SQLERRM; END;
 BEGIN INSERT INTO integrity_demo.samples(ref_code,parent_id,score,title) VALUES ('CHECK',1,101,'range bad');
 EXCEPTION WHEN check_violation THEN RAISE NOTICE 'CHECK SQLSTATE %: %', SQLSTATE, SQLERRM; END;
 BEGIN DELETE FROM integrity_demo.parents WHERE parent_id=1;
 EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'RESTRICT SQLSTATE %: %', SQLSTATE, SQLERRM; END;
END $$;
-- CASCADE demonstration uses a different parent (id=2) with children only.
INSERT INTO integrity_demo.children(parent_id,label) VALUES (2,'one'),(2,'two');
SELECT COUNT(*) AS children_before FROM integrity_demo.children WHERE parent_id=2; -- 2
DELETE FROM integrity_demo.parents WHERE parent_id=2;
SELECT COUNT(*) AS children_after FROM integrity_demo.children WHERE parent_id=2; -- 0
-- Direct demo on courses/department (departments 1 and 2 from practice-09):
-- DELETE FROM college.departments WHERE department_id=1; -- expect FK violation; DO NOT execute in regular run
