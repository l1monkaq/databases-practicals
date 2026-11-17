-- =====================================================================
-- Симулятор версіонування міграцій (Flyway / Liquibase style runner)
-- Предмет: Бази даних | Група: ІПЗ-41 | Виконала: Єва Якимчук
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS college_migrations;

-- Таблиця обліку історії застосованих міграцій (schema_version / flyway_schema_history)
CREATE TABLE IF NOT EXISTS college_migrations.schema_history (
    installed_rank INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    version VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(200) NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'SQL',
    script VARCHAR(1000) NOT NULL,
    checksum VARCHAR(64) NOT NULL,
    installed_by VARCHAR(100) NOT NULL DEFAULT CURRENT_USER,
    installed_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    execution_time_ms INTEGER NOT NULL,
    success BOOLEAN NOT NULL
);

-- Процедура безпечного виконання міграції з перевіркою повторного запуску
CREATE OR REPLACE PROCEDURE college_migrations.apply_migration(
    p_version VARCHAR(50),
    p_description VARCHAR(200),
    p_script_name VARCHAR(1000),
    p_checksum VARCHAR(64),
    p_sql_code TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_ts TIMESTAMP;
    v_exec_ms INTEGER;
    v_already_applied BOOLEAN;
BEGIN
    -- Перевірка 1: Чи була версія вже застосована?
    SELECT EXISTS (
        SELECT 1 FROM college_migrations.schema_history
        WHERE version = p_version AND success = TRUE
    ) INTO v_already_applied;

    IF v_already_applied THEN
        RAISE NOTICE '>>> Пропуск міграції % (%): версія вже успішно застосована.', p_version, p_description;
        RETURN;
    END IF;

    RAISE NOTICE '>>> Застосування міграції %: % ...', p_version, p_description;
    v_start_ts := clock_timestamp();

    -- Виконання DDL коду
    EXECUTE p_sql_code;

    v_exec_ms := ROUND(EXTRACT(MILLISECONDS FROM (clock_timestamp() - v_start_ts)));

    -- Запис у журнал історії
    INSERT INTO college_migrations.schema_history (
        version, description, script, checksum, execution_time_ms, success
    ) VALUES (
        p_version, p_description, p_script_name, p_checksum, v_exec_ms, TRUE
    );

    RAISE NOTICE '>>> Міграція % успішно застосована за % мс.', p_version, v_exec_ms;
END;
$$;

-- Демонстраційний сценарій запуску міграцій V1 -> V2 -> V3
DO $$
BEGIN
    -- Застосування V1
    CALL college_migrations.apply_migration(
        '1.0',
        'init schema and core tables',
        'V1__init.sql',
        'a1b2c3d4e5f6',
        'CREATE TABLE IF NOT EXISTS college.departments (
            department_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            code VARCHAR(10) NOT NULL UNIQUE,
            name TEXT NOT NULL
         );
         CREATE TABLE IF NOT EXISTS college.courses (
            course_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            department_id INTEGER NOT NULL REFERENCES college.departments(department_id),
            code VARCHAR(12) NOT NULL UNIQUE,
            title VARCHAR(150) NOT NULL,
            credits SMALLINT NOT NULL CHECK (credits BETWEEN 1 AND 30),
            tuition_fee NUMERIC(10,2) NOT NULL DEFAULT 0
         );
         CREATE TABLE IF NOT EXISTS college.students (
            student_id INTEGER PRIMARY KEY,
            full_name VARCHAR(150) NOT NULL,
            group_code VARCHAR(12) NOT NULL,
            email VARCHAR(254) UNIQUE
         );
         CREATE TABLE IF NOT EXISTS college.enrollments (
            student_id INTEGER NOT NULL REFERENCES college.students(student_id),
            course_id INTEGER NOT NULL REFERENCES college.courses(course_id),
            status VARCHAR(12) NOT NULL DEFAULT ''active'',
            grade SMALLINT,
            enrolled_on DATE NOT NULL DEFAULT CURRENT_DATE,
            PRIMARY KEY (student_id, course_id)
         );
         INSERT INTO college.departments (code, name) VALUES (''IT'', ''Інформаційні технології''), (''FIZ'', ''Фізика'') ON CONFLICT DO NOTHING;
         INSERT INTO college.courses (department_id, code, title, credits, tuition_fee) VALUES
         (1, ''DB'', ''Бази даних'', 4, 1200.00), (2, ''PHY'', ''Фізика'', 5, 950.00) ON CONFLICT DO NOTHING;
        '
    );

    -- Застосування V2
    CALL college_migrations.apply_migration(
        '2.0',
        'add teachers table and teacher_id to courses',
        'V2__add_teacher_id.sql',
        'f6e5d4c3b2a1',
        'CREATE TABLE IF NOT EXISTS college.teachers (
            teacher_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            full_name VARCHAR(150) NOT NULL,
            email VARCHAR(254) NOT NULL UNIQUE,
            department_id INTEGER NOT NULL REFERENCES college.departments(department_id)
         );
         INSERT INTO college.teachers (full_name, email, department_id) VALUES
         (''Олексієнко В.М.'', ''oleks@example.edu'', 1) ON CONFLICT DO NOTHING;
         ALTER TABLE college.courses ADD COLUMN IF NOT EXISTS teacher_id INTEGER;
         UPDATE college.courses SET teacher_id = 1 WHERE teacher_id IS NULL;
         ALTER TABLE college.courses ALTER COLUMN teacher_id SET NOT NULL;
         ALTER TABLE college.courses DROP CONSTRAINT IF EXISTS fk_courses_teacher;
         ALTER TABLE college.courses ADD CONSTRAINT fk_courses_teacher FOREIGN KEY (teacher_id) REFERENCES college.teachers(teacher_id);
        '
    );

    -- Застосування V3
    CALL college_migrations.apply_migration(
        '3.0',
        'drop status and add completed_at in enrollments',
        'V3__drop_status.sql',
        'c3b2a1f6e5d4',
        'ALTER TABLE college.enrollments ADD COLUMN IF NOT EXISTS completed_at DATE;
         UPDATE college.enrollments SET completed_at = CURRENT_DATE WHERE status = ''completed'';
         ALTER TABLE college.enrollments DROP COLUMN IF EXISTS status;
        '
    );

    -- Демонстрація розпізнавання повторного застосування V2 (має бути пропущена!)
    CALL college_migrations.apply_migration(
        '2.0',
        'add teachers table and teacher_id to courses',
        'V2__add_teacher_id.sql',
        'f6e5d4c3b2a1',
        'SELECT 1;'
    );
END $$;

-- Перегляд фінального журналу міграцій
SELECT installed_rank, version, description, script, checksum, installed_on, execution_time_ms, success
FROM college_migrations.schema_history
ORDER BY installed_rank;
