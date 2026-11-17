-- =====================================================================
-- Практична робота №13. Вищі нормальні форми та денормалізація
-- Предмет: Бази даних | Група: ІПЗ-41 | Виконала: Єва Якимчук
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS advanced_nf;

-- ---------------------------------------------------------------------
-- 1. Демонстрація порушення 4НФ (Багатозначні залежності MVD)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS advanced_nf.teacher_skills_projects CASCADE;
DROP TABLE IF EXISTS advanced_nf.teacher_skills CASCADE;
DROP TABLE IF EXISTS advanced_nf.teacher_projects CASCADE;

-- Таблиця з комбінаторним вибухом (порушення 4НФ):
-- Викладач має множину навичок і незалежну множину проєктів
CREATE TABLE advanced_nf.teacher_skills_projects (
    teacher_id INTEGER NOT NULL,
    skill VARCHAR(50) NOT NULL,
    project_type VARCHAR(50) NOT NULL,
    PRIMARY KEY (teacher_id, skill, project_type)
);

-- Якщо викладач володіє 2 мовами (Python, SQL) і веде 2 типи проєктів (Web, AI),
-- у таблиці 1НФ-3НФ мусить бути 2 * 2 = 4 рядки:
INSERT INTO advanced_nf.teacher_skills_projects VALUES
(501, 'Python', 'Web Development'),
(501, 'Python', 'AI Research'),
(501, 'SQL',    'Web Development'),
(501, 'SQL',    'AI Research');

-- Декомпозиція до 4НФ (усунення незалежних MVD: teacher ->-> skill та teacher ->-> project):
CREATE TABLE advanced_nf.teacher_skills (
    teacher_id INTEGER NOT NULL,
    skill VARCHAR(50) NOT NULL,
    PRIMARY KEY (teacher_id, skill)
);

CREATE TABLE advanced_nf.teacher_projects (
    teacher_id INTEGER NOT NULL,
    project_type VARCHAR(50) NOT NULL,
    PRIMARY KEY (teacher_id, project_type)
);

-- Заповнення 4НФ таблиць (лише 2 + 2 = 4 рядки замість добутку):
INSERT INTO advanced_nf.teacher_skills VALUES (501, 'Python'), (501, 'SQL');
INSERT INTO advanced_nf.teacher_projects VALUES (501, 'Web Development'), (501, 'AI Research');

-- ---------------------------------------------------------------------
-- 2. Демонстрація 5НФ (Залежність з'єднання Join Dependency *[R1, R2, R3])
-- Трійка: Викладач - Курс - Підручник
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS advanced_nf.teacher_course_book_5nf CASCADE;
DROP TABLE IF EXISTS advanced_nf.teacher_courses CASCADE;
DROP TABLE IF EXISTS advanced_nf.course_books CASCADE;
DROP TABLE IF EXISTS advanced_nf.teacher_books CASCADE;

-- Декомпозиція на 3 проекції за теоремою 5НФ:
CREATE TABLE advanced_nf.teacher_courses (
    teacher_id INTEGER NOT NULL,
    course_code VARCHAR(12) NOT NULL,
    PRIMARY KEY (teacher_id, course_code)
);

CREATE TABLE advanced_nf.course_books (
    course_code VARCHAR(12) NOT NULL,
    book_title VARCHAR(150) NOT NULL,
    PRIMARY KEY (course_code, book_title)
);

CREATE TABLE advanced_nf.teacher_books (
    teacher_id INTEGER NOT NULL,
    book_title VARCHAR(150) NOT NULL,
    PRIMARY KEY (teacher_id, book_title)
);

-- Відновлення вихідної 3-арної залежності без фіктивних рядків:
CREATE VIEW advanced_nf.v_reconstructed_5nf AS
SELECT tc.teacher_id, tc.course_code, cb.book_title
FROM advanced_nf.teacher_courses tc
JOIN advanced_nf.course_books cb ON tc.course_code = cb.course_code
JOIN advanced_nf.teacher_books tb ON tc.teacher_id = tb.teacher_id AND cb.book_title = tb.book_title;

-- ---------------------------------------------------------------------
-- 3. Свідома контрольована денормалізація (Гіпотеза оптимізації читання)
-- ---------------------------------------------------------------------
-- Створюємо денормалізований кеш-стовпець у таблиці курсів для усунення важких COUNT(*)
ALTER TABLE college.courses ADD COLUMN IF NOT EXISTS cached_enrollments_count INTEGER DEFAULT 0;
ALTER TABLE college.courses ADD COLUMN IF NOT EXISTS cached_avg_grade NUMERIC(4,2) DEFAULT NULL;

-- Оновлюємо початкові значення:
UPDATE college.courses c
SET cached_enrollments_count = sub.cnt,
    cached_avg_grade = sub.avg_g
FROM (
    SELECT course_id, COUNT(*) AS cnt, ROUND(AVG(grade), 2) AS avg_g
    FROM college.enrollments
    GROUP BY course_id
) sub
WHERE c.course_id = sub.course_id;

-- ---------------------------------------------------------------------
-- 4. Забезпечення узгодженості денормалізованих даних через тригер
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION college.trg_sync_course_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE college.courses
        SET cached_enrollments_count = cached_enrollments_count + 1,
            cached_avg_grade = (
                SELECT ROUND(AVG(grade), 2) FROM college.enrollments WHERE course_id = NEW.course_id
            )
        WHERE course_id = NEW.course_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE college.courses
        SET cached_enrollments_count = GREATEST(0, cached_enrollments_count - 1),
            cached_avg_grade = (
                SELECT ROUND(AVG(grade), 2) FROM college.enrollments WHERE course_id = OLD.course_id
            )
        WHERE course_id = OLD.course_id;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.grade IS DISTINCT FROM NEW.grade THEN
            UPDATE college.courses
            SET cached_avg_grade = (
                SELECT ROUND(AVG(grade), 2) FROM college.enrollments WHERE course_id = NEW.course_id
            )
            WHERE course_id = NEW.course_id;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_enrollment_sync ON college.enrollments;
CREATE TRIGGER trg_enrollment_sync
AFTER INSERT OR UPDATE OR DELETE ON college.enrollments
FOR EACH ROW EXECUTE FUNCTION college.trg_sync_course_stats();

-- Альтернативний сучасний підхід: Матеріалізоване представлення (Materialized View)
DROP MATERIALIZED VIEW IF EXISTS college.mv_course_dashboard;
CREATE MATERIALIZED VIEW college.mv_course_dashboard AS
SELECT c.course_id,
       c.code AS course_code,
       c.title AS course_title,
       d.name AS department_name,
       COUNT(e.student_id) AS total_enrolled,
       ROUND(AVG(e.grade), 2) AS average_grade
FROM college.courses c
JOIN college.departments d USING (department_id)
LEFT JOIN college.enrollments e USING (course_id)
GROUP BY c.course_id, c.code, c.title, d.name;

-- Створення унікального індексу для оновлення без блокування (CONCURRENTLY):
CREATE UNIQUE INDEX IF NOT EXISTS uq_mv_course_dashboard_id ON college.mv_course_dashboard (course_id);
-- REFRESH MATERIALIZED VIEW CONCURRENTLY college.mv_course_dashboard;
