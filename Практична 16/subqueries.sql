-- =====================================================================
-- Практична робота №16. Складання запитів із підзапитами
-- Предмет: Бази даних | Група: ІПЗ-41 | Виконала: Єва Якимчук
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS college;

DROP TABLE IF EXISTS college.enrollments CASCADE;
DROP TABLE IF EXISTS college.students CASCADE;
DROP TABLE IF EXISTS college.courses CASCADE;
DROP TABLE IF EXISTS college.departments CASCADE;

-- Створення базової схеми
CREATE TABLE college.departments (
    department_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name TEXT NOT NULL
);

CREATE TABLE college.courses (
    course_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_id INTEGER NOT NULL REFERENCES college.departments(department_id) ON DELETE RESTRICT,
    code VARCHAR(12) NOT NULL UNIQUE,
    title VARCHAR(150) NOT NULL,
    credits SMALLINT NOT NULL CHECK (credits BETWEEN 1 AND 30),
    tuition_fee NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (tuition_fee >= 0)
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

-- Наповнення даними
INSERT INTO college.departments (code, name) VALUES
('IT', 'Інформаційні технології'),
('FIZ', 'Фізика'),
('HUM', 'Гуманітарні науки');

INSERT INTO college.courses (department_id, code, title, credits, tuition_fee) VALUES
(1, 'DB',   'Бази даних',           4, 1200.00),
(1, 'WEB',  'Вебтехнології',        3, 1100.00),
(1, 'SEC',  'Кібербезпека',         4, 1300.00),
(2, 'PHY',  'Загальна фізика',      5,  950.00),
(2, 'AST',  'Астрономія',           3,  850.00),
(1, 'ARCH', 'Архітектура комп''ютерів', 6, 1400.00);

INSERT INTO college.students (student_id, full_name, group_code, email) VALUES
(101, 'Іваненко Марія', '121', 'm.ivanenko@example.edu'),
(102, 'Петренко Олег', '121', 'o.petrenko@example.edu'),
(103, 'Шевчук Анна', '122', 'a.shevchuk@example.edu'),
(104, 'Коваль Назар', '123', 'n.koval@example.edu'),
(105, 'Бондаренко Денис', '121', 'd.bondarenko@example.edu');

INSERT INTO college.enrollments (student_id, course_id, status, grade) VALUES
(101, 1, 'completed', 92),
(101, 2, 'active', NULL),
(102, 1, 'completed', 85),
(103, 4, 'completed', 78),
(104, 1, 'active', NULL),
(104, 2, 'cancelled', NULL),
(105, 6, 'completed', 98);

-- =====================================================================
-- 1. Скалярний підзапит (Scalar Subquery)
-- Повертає рівно одне значення (1 рядок, 1 стовпець)
-- Знайти курси, вартість яких вища за середню плату по всіх курсах
-- =====================================================================
SELECT course_id,
       code,
       title,
       tuition_fee,
       ROUND((SELECT AVG(tuition_fee) FROM college.courses), 2) AS overall_avg_fee
FROM college.courses
WHERE tuition_fee > (SELECT AVG(tuition_fee) FROM college.courses)
ORDER BY tuition_fee DESC;

-- =====================================================================
-- 2. Багаторядковий підзапит із предикатом IN
-- Повертає список ідентифікаторів студентів, що обрали курси з кредитами > 4
-- =====================================================================
SELECT student_id,
       full_name,
       group_code
FROM college.students
WHERE student_id IN (
    SELECT e.student_id
    FROM college.enrollments e
    JOIN college.courses c ON e.course_id = c.course_id
    WHERE c.credits > 4
)
ORDER BY student_id;

-- =====================================================================
-- 3. Багаторядкові кванторні підзапити з ANY та ALL
-- Підмножина кредитів курсів фізичного підрозділу (департамент 2 FIZ: PHY=5, AST=3)
-- =====================================================================

-- 3.1. Квантор ANY (> ANY еквівалентно > MIN із підмножини, тобто > 3):
SELECT code, title, credits
FROM college.courses
WHERE credits > ANY (
    SELECT credits FROM college.courses WHERE department_id = 2
)
ORDER BY credits DESC;

-- 3.2. Квантор ALL (> ALL еквівалентно > MAX із підмножини, тобто > 5):
SELECT code, title, credits
FROM college.courses
WHERE credits > ALL (
    SELECT credits FROM college.courses WHERE department_id = 2
)
ORDER BY credits DESC;

-- =====================================================================
-- 4. Корельований підзапит із предикатом EXISTS
-- Знайти підрозділи, які мають хоча б один курс із фактичними реєстраціями
-- (Підзапит посилається на зовнішній рядок d.department_id)
-- =====================================================================
SELECT d.department_id,
       d.code AS department_code,
       d.name AS department_name
FROM college.departments d
WHERE EXISTS (
    SELECT 1
    FROM college.courses c
    JOIN college.enrollments e ON c.course_id = e.course_id
    WHERE c.department_id = d.department_id
)
ORDER BY d.department_id;

-- Протилежний випадок: кафедри без жодного студента (NOT EXISTS):
SELECT d.code, d.name
FROM college.departments d
WHERE NOT EXISTS (
    SELECT 1
    FROM college.courses c
    JOIN college.enrollments e ON c.course_id = e.course_id
    WHERE c.department_id = d.department_id
);

-- =====================================================================
-- 5. Порівняння реалізації одного завдання: Підзапит IN vs JOIN
-- Завдання: Отримати список студентів, зареєстрованих на курс 'Бази даних'
-- =====================================================================

-- Спосіб А: Підзапит IN (Semi-Join)
SELECT s.student_id, s.full_name
FROM college.students s
WHERE s.student_id IN (
    SELECT e.student_id
    FROM college.enrollments e
    JOIN college.courses c ON e.course_id = c.course_id
    WHERE c.code = 'DB'
)
ORDER BY s.student_id;

-- Спосіб Б: Реляційне з'єднання JOIN (потребує DISTINCT для уникнення дублікатів)
SELECT DISTINCT s.student_id, s.full_name
FROM college.students s
JOIN college.enrollments e ON s.student_id = e.student_id
JOIN college.courses c ON e.course_id = c.course_id
WHERE c.code = 'DB'
ORDER BY s.student_id;

-- =====================================================================
-- 6. Підзапит у секції FROM (Derived Table / Похідна таблиця)
-- Підрахунок агрегованої статистики: середня, максимальна та мінімальна
-- кількість студентів на один курс
-- =====================================================================
SELECT ROUND(AVG(course_stats.enrollments_count), 2) AS avg_enrollments_per_course,
       MAX(course_stats.enrollments_count) AS max_enrollments_on_course,
       MIN(course_stats.enrollments_count) AS min_enrollments_on_course,
       SUM(course_stats.enrollments_count) AS total_active_enrollments
FROM (
    SELECT c.course_id,
           c.title,
           COUNT(e.student_id) AS enrollments_count
    FROM college.courses c
    LEFT JOIN college.enrollments e ON c.course_id = e.course_id
    GROUP BY c.course_id, c.title
) AS course_stats;
