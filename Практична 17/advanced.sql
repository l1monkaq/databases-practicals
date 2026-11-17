-- =====================================================================
-- Практична робота №17. Складні багатотабличні запити (JOIN + підзапити)
-- Предмет: Бази даних | Група: ІПЗ-41 | Виконала: Єва Якимчук
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS college;

DROP TABLE IF EXISTS college.enrollments CASCADE;
DROP TABLE IF EXISTS college.courses CASCADE;
DROP TABLE IF EXISTS college.teachers CASCADE;
DROP TABLE IF EXISTS college.departments CASCADE;
DROP TABLE IF EXISTS college.students CASCADE;

-- 1. Створення повної схеми з 5 сутностями
CREATE TABLE college.departments (
    department_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name TEXT NOT NULL
);

CREATE TABLE college.teachers (
    teacher_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_id INTEGER NOT NULL REFERENCES college.departments(department_id) ON DELETE RESTRICT,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(254) NOT NULL UNIQUE
);

CREATE TABLE college.courses (
    course_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_id INTEGER NOT NULL REFERENCES college.departments(department_id) ON DELETE RESTRICT,
    teacher_id INTEGER REFERENCES college.teachers(teacher_id) ON DELETE SET NULL,
    code VARCHAR(12) NOT NULL,
    title VARCHAR(150) NOT NULL,
    credits SMALLINT NOT NULL CHECK (credits BETWEEN 1 AND 30),
    tuition_fee NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (tuition_fee >= 0),
    CONSTRAINT uq_courses_dep_code UNIQUE (department_id, code)
);

CREATE TABLE college.students (
    student_id INTEGER PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    group_code VARCHAR(12) NOT NULL,
    email VARCHAR(254) UNIQUE
);

CREATE TABLE college.enrollments (
    student_id INTEGER NOT NULL REFERENCES college.students(student_id) ON DELETE CASCADE,
    course_id INTEGER NOT NULL REFERENCES college.courses(course_id) ON DELETE RESTRICT,
    status VARCHAR(12) NOT NULL DEFAULT 'active' CHECK (status IN ('active','completed','cancelled')),
    grade SMALLINT CHECK (grade BETWEEN 0 AND 100),
    enrolled_on DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (student_id, course_id)
);

-- 2. Наповнення даними
INSERT INTO college.departments (code, name) VALUES
('IT', 'Інформаційні технології'),
('FIZ', 'Фізика'),
('HUM', 'Гуманітарні науки');

INSERT INTO college.teachers (department_id, full_name, email) VALUES
(1, 'Олексієнко Василь Михайлович', 'v.oleksienko@example.edu'),
(1, 'Григоренко Ірина Сергіївна',    'i.hryhorenko@example.edu'),
(2, 'Мельник Тетяна Петрівна',       't.melnyk@example.edu'),
(3, 'Дмитрук Оксана Романівна',      'o.dmytruk@example.edu');

INSERT INTO college.courses (department_id, teacher_id, code, title, credits, tuition_fee) VALUES
(1, 1, 'DB',   'Бази даних',                     4, 1200.00),
(1, 1, 'WEB',  'Вебтехнології',                  3, 1100.00),
(1, 2, 'SEC',  'Кібербезпека',                   4, 1300.00),
(1, 1, 'DATA', 'Аналіз даних і статистика',      3, 1050.00),
(2, 3, 'PHY',  'Загальна фізика',                5,  950.00),
(2, 3, 'AST',  'Астрономія',                     3,  850.00),
(2, 3, 'DATA', 'Статистичні методи у фізиці',    3,  900.00); -- Спільний код дисципліни DATA для кафедр 1 і 2

INSERT INTO college.students (student_id, full_name, group_code, email) VALUES
(101, 'Іваненко Марія',   '121', 'm.ivanenko@example.edu'),
(102, 'Петренко Олег',    '121', 'o.petrenko@example.edu'),
(103, 'Шевчук Анна',      '122', 'a.shevchuk@example.edu'),
(104, 'Коваль Назар',     '123', 'n.koval@example.edu'),
(105, 'Бондаренко Денис', '121', 'd.bondarenko@example.edu');

INSERT INTO college.enrollments (student_id, course_id, status, grade) VALUES
(101, 1, 'completed', 92),
(101, 2, 'active',    NULL),
(102, 1, 'completed', 84),
(103, 5, 'completed', 78),
(104, 1, 'active',    NULL),
(104, 2, 'cancelled', NULL),
(105, 1, 'completed', 96),
(105, 5, 'completed', 88);
-- Курси 3 (SEC), 4 (DATA IT), 6 (AST), 7 (DATA FIZ) залишаються без студентів

-- =====================================================================
-- 1. Звіт «Підрозділ -> кількість курсів -> кількість реєстрацій»
-- Використання двох LEFT JOIN та COUNT(DISTINCT ...)
-- =====================================================================
SELECT d.name AS department,
       COUNT(DISTINCT c.course_id) AS courses,
       COUNT(e.student_id) AS enrollments
FROM college.departments AS d
LEFT JOIN college.courses AS c USING (department_id)
LEFT JOIN college.enrollments AS e USING (course_id)
GROUP BY d.name
ORDER BY enrollments DESC, courses DESC;

-- =====================================================================
-- 2. Звіт «Середній бал студента» (GPA) з JOIN, агрегацією та HAVING
-- Вибірка лише студентів, що мають щонайменше одну виставлену оцінку
-- =====================================================================
SELECT s.student_id,
       s.full_name AS student_name,
       s.group_code,
       COUNT(e.grade) AS graded_courses_count,
       ROUND(AVG(e.grade), 2) AS gpa
FROM college.students s
JOIN college.enrollments e USING (student_id)
WHERE e.grade IS NOT NULL
GROUP BY s.student_id, s.full_name, s.group_code
HAVING COUNT(e.grade) >= 1
ORDER BY gpa DESC, s.full_name ASC;

-- =====================================================================
-- 3. Звіт «Курси, які жодного разу не обрали»
-- Порівняння двох підходів: LEFT JOIN + IS NULL проти NOT EXISTS
-- =====================================================================

-- Підхід 3.1: LEFT JOIN + перевірка NULL
SELECT c.course_id,
       c.code AS course_code,
       c.title AS course_title,
       d.name AS department_name
FROM college.courses c
JOIN college.departments d USING (department_id)
LEFT JOIN college.enrollments e USING (course_id)
WHERE e.student_id IS NULL
ORDER BY c.course_id;

-- Підхід 3.2: NOT EXISTS (анти-з'єднання / Anti-Semi-Join)
SELECT c.course_id,
       c.code AS course_code,
       c.title AS course_title,
       d.name AS department_name
FROM college.courses c
JOIN college.departments d USING (department_id)
WHERE NOT EXISTS (
    SELECT 1
    FROM college.enrollments e
    WHERE e.course_id = c.course_id
)
ORDER BY c.course_id;

-- =====================================================================
-- 4. Звіт «Викладачі, які ведуть найбільше курсів»
-- Використання підзапиту в HAVING для динамічного знаходження максимуму
-- =====================================================================
SELECT t.teacher_id,
       t.full_name AS teacher_name,
       d.name AS department_name,
       COUNT(c.course_id) AS courses_taught
FROM college.teachers t
JOIN college.departments d USING (department_id)
JOIN college.courses c USING (teacher_id)
GROUP BY t.teacher_id, t.full_name, d.name
HAVING COUNT(c.course_id) = (
    SELECT MAX(course_count)
    FROM (
        SELECT COUNT(course_id) AS course_count
        FROM college.courses
        WHERE teacher_id IS NOT NULL
        GROUP BY teacher_id
    ) sub
)
ORDER BY t.teacher_id;

-- =====================================================================
-- 5. Комбінований звіт: Студенти з оцінкою вищою за середню по курсу
-- Корельований підзапит обчислює середній бал окремо для кожного курсу
-- =====================================================================
SELECT s.student_id,
       s.full_name AS student_name,
       c.code AS course_code,
       c.title AS course_title,
       e.grade AS student_grade,
       ROUND((
           SELECT AVG(e2.grade)
           FROM college.enrollments e2
           WHERE e2.course_id = e.course_id
       ), 2) AS course_average_grade
FROM college.enrollments e
JOIN college.students s USING (student_id)
JOIN college.courses c USING (course_id)
WHERE e.grade > (
    SELECT AVG(e2.grade)
    FROM college.enrollments e2
    WHERE e2.course_id = e.course_id
)
ORDER BY c.code, e.grade DESC;

-- =====================================================================
-- 6. Операція над множинами: INTERSECT
-- Знаходження кодів курсів, які пропонуються одночасно і кафедрою IT, і кафедрою Фізики
-- =====================================================================
SELECT code FROM college.courses WHERE department_id = 1
INTERSECT
SELECT code FROM college.courses WHERE department_id = 2
ORDER BY code;
