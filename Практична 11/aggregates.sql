-- =====================================================================
-- Практична робота №11. Агрегація, групування та операції над множинами
-- Предмет: Бази даних | Група: ІПЗ-41 | Виконала: Єва Якимчук
-- =====================================================================

-- 0. Підготовка середовища та контрольних даних (схема college)
CREATE SCHEMA IF NOT EXISTS college;

DROP TABLE IF EXISTS college.enrollments CASCADE;
DROP TABLE IF EXISTS college.students CASCADE;
DROP TABLE IF EXISTS college.courses CASCADE;
DROP TABLE IF EXISTS college.departments CASCADE;

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
(1, 'DB', 'Бази даних', 4, 1200.00),
(1, 'WEB', 'Вебтехнології', 3, 1100.00),
(1, 'SEC', 'Кібербезпека', 4, 1300.00),
(2, 'PHY', 'Загальна фізика', 5, 950.00),
(2, 'AST', 'Астрономія', 3, 850.00);

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
(103, 3, 'completed', 78),
(104, 1, 'active', NULL),
(104, 2, 'cancelled', NULL),
(105, 1, 'completed', 95),
(105, 3, 'completed', 60);

-- =====================================================================
-- Завдання 1. Звіти з агрегатними функціями для схеми college
-- =====================================================================

-- 1.1. Кількість курсів у кожному підрозділі: COUNT, GROUP BY
SELECT d.name AS department_name,
       COUNT(c.course_id) AS total_courses
FROM college.departments d
LEFT JOIN college.courses c ON d.department_id = c.department_id
GROUP BY d.name
ORDER BY total_courses DESC, d.name ASC;

-- 1.2. Середня кількість кредитів курсів: AVG (із заокругленням)
SELECT ROUND(AVG(credits), 2) AS avg_credits,
       MIN(credits) AS min_credits,
       MAX(credits) AS max_credits,
       SUM(credits) AS total_credits
FROM college.courses;

-- 1.3. Мінімальна та максимальна оцінка серед реєстрацій: MIN, MAX
SELECT MIN(grade) AS min_grade,
       MAX(grade) AS max_grade,
       ROUND(AVG(grade), 2) AS avg_grade,
       COUNT(grade) AS graded_students_count
FROM college.enrollments;

-- 1.4. Сумарна кількість реєстрацій на курс із фільтрацією HAVING
SELECT c.code AS course_code,
       c.title AS course_title,
       COUNT(e.student_id) AS enrollments_count
FROM college.courses c
JOIN college.enrollments e ON c.course_id = e.course_id
GROUP BY c.course_id, c.code, c.title
HAVING COUNT(e.student_id) >= 2
ORDER BY enrollments_count DESC;

-- =====================================================================
-- Завдання 2. Порівняння та відмінність WHERE і HAVING
-- =====================================================================

-- Спосіб 1: HAVING фільтрує вже після агрегації рядків
SELECT course_id,
       COUNT(*) AS enrollments
FROM college.enrollments
GROUP BY course_id
HAVING COUNT(*) >= 2;

-- Спосіб 2: WHERE фільтрує окремі рядки ДО побудови груп і агрегації
SELECT course_id,
       COUNT(*) AS active_or_completed_count
FROM college.enrollments
WHERE status <> 'cancelled'
GROUP BY course_id;

-- Поєднання: WHERE відсікає скасовані реєстрації до обчислення,
-- а HAVING залишає лише курси з 2+ дійсними студентами
SELECT course_id,
       COUNT(*) AS valid_enrollments
FROM college.enrollments
WHERE status IN ('active', 'completed')
GROUP BY course_id
HAVING COUNT(*) >= 2;

-- =====================================================================
-- Завдання 3. Операції над множинами: UNION, UNION ALL, INTERSECT, EXCEPT
-- =====================================================================

-- Підмножина A: курси кафедр IT та спільних курсів
-- Підмножина B: курси із кредитами <= 3 або спецкурси
-- 3.1. UNION: об'єднання множин із вилученням дублікатів
SELECT code, title FROM college.courses WHERE department_id = 1
UNION
SELECT code, title FROM college.courses WHERE credits <= 3
ORDER BY code;

-- 3.2. UNION ALL: об'єднання мультимножин зі збереженням дублікатів
SELECT code, title FROM college.courses WHERE department_id = 1
UNION ALL
SELECT code, title FROM college.courses WHERE credits <= 3
ORDER BY code;

-- 3.3. INTERSECT: перетин множин (курси IT, що мають не більше 3 кредитів)
SELECT code, title FROM college.courses WHERE department_id = 1
INTERSECT
SELECT code, title FROM college.courses WHERE credits <= 3
ORDER BY code;

-- 3.4. EXCEPT: різниця множин (курси IT, що мають суворо більше 3 кредитів)
SELECT code, title FROM college.courses WHERE department_id = 1
EXCEPT
SELECT code, title FROM college.courses WHERE credits <= 3
ORDER BY code;

-- =====================================================================
-- Завдання 4. Прикладний звіт: «Топ курсів за кількістю студентів»
-- =====================================================================
SELECT c.course_id,
       c.code AS course_code,
       c.title AS course_title,
       d.name AS department_name,
       COUNT(e.student_id) AS total_students,
       COUNT(CASE WHEN e.status = 'completed' THEN 1 END) AS completed_students,
       ROUND(AVG(e.grade), 1) AS average_grade
FROM college.courses c
JOIN college.departments d ON c.department_id = d.department_id
LEFT JOIN college.enrollments e ON c.course_id = e.course_id
GROUP BY c.course_id, c.code, c.title, d.name
ORDER BY total_students DESC, average_grade DESC NULLS LAST;
