-- =====================================================================
-- Практична робота №15. Складання запитів із внутрішніми та зовнішніми JOIN
-- Предмет: Бази даних | Група: ІПЗ-41 | Виконала: Єва Якимчук
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS college;

DROP TABLE IF EXISTS college.enrollments CASCADE;
DROP TABLE IF EXISTS college.students CASCADE;
DROP TABLE IF EXISTS college.courses CASCADE;
DROP TABLE IF EXISTS college.departments CASCADE;

-- 1. Створення таблиць
CREATE TABLE college.departments (
    department_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name TEXT NOT NULL
);

-- У таблиці courses робимо department_id NULLable для демонстрації RIGHT/FULL JOIN
CREATE TABLE college.courses (
    course_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_id INTEGER REFERENCES college.departments(department_id) ON DELETE SET NULL,
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

-- 2. Наповнення даними з характерними випадками незбігів
INSERT INTO college.departments (code, name) VALUES
('IT', 'Інформаційні технології'),
('FIZ', 'Фізика'),
('HUM', 'Гуманітарні науки'); -- Підрозділ БЕЗ курсів

INSERT INTO college.courses (department_id, code, title, credits, tuition_fee) VALUES
(1, 'DB',  'Бази даних', 4, 1200.00),
(1, 'WEB', 'Вебтехнології', 3, 1100.00),
(2, 'PHY', 'Загальна фізика', 5, 950.00),
(2, 'AST', 'Астрономія', 3, 850.00),     -- Курс без студентів
(NULL, 'FREE', 'Міжкафедральний семінар', 2, 0.00); -- Курс БЕЗ підрозділу

INSERT INTO college.students (student_id, full_name, group_code, email) VALUES
(101, 'Іваненко Марія', '121', 'm.ivanenko@example.edu'),
(102, 'Петренко Олег', '121', 'o.petrenko@example.edu'),
(103, 'Шевчук Анна', '122', 'a.shevchuk@example.edu'),
(104, 'Коваль Назар', '123', 'n.koval@example.edu'),
(105, 'Бондаренко Денис', '121', 'd.bondarenko@example.edu'); -- Студент БЕЗ реєстрацій

INSERT INTO college.enrollments (student_id, course_id, status, grade) VALUES
(101, 1, 'completed', 92),
(101, 2, 'active', NULL),
(102, 1, 'completed', 85),
(103, 3, 'completed', 78),
(104, 2, 'cancelled', NULL);

-- =====================================================================
-- 2. Запит INNER JOIN
-- =====================================================================
-- Повертає лише ті пари, де є точний збіг за department_id
SELECT d.name AS department,
       c.title AS course
FROM college.courses AS c
JOIN college.departments AS d USING (department_id)
ORDER BY d.name, c.title;

-- =====================================================================
-- 3. Запит LEFT JOIN від departments до courses
-- =====================================================================
-- Зберігає ВСІ кафедри, навіть якщо вони не мають жодного курсу
SELECT d.name AS department,
       c.title AS course
FROM college.departments AS d
LEFT JOIN college.courses AS c USING (department_id)
ORDER BY d.name, c.title;

-- =====================================================================
-- 4. Запити RIGHT JOIN та FULL JOIN
-- =====================================================================

-- 4.1. RIGHT JOIN (зберігає всі курси, навіть без закріпленої кафедри)
SELECT d.name AS department,
       c.title AS course
FROM college.departments AS d
RIGHT JOIN college.courses AS c USING (department_id)
ORDER BY d.name NULLS LAST, c.title;

-- 4.2. FULL JOIN (зберігає і кафедри без курсів, і курси без кафедр)
SELECT d.name AS department,
       c.title AS course
FROM college.departments AS d
FULL JOIN college.courses AS c USING (department_id)
ORDER BY d.name NULLS LAST, c.title;

-- =====================================================================
-- 5. Багатотабличний звіт «студент — курс — оцінка» (два JOIN)
-- =====================================================================
-- Використовуємо LEFT JOIN, щоб побачити повну картину (включно зі студентами без курсів)
SELECT s.student_id,
       s.full_name AS student_name,
       COALESCE(c.title, '(немає реєстрацій)') AS course_title,
       e.status,
       COALESCE(e.grade::TEXT, '—') AS grade
FROM college.students s
LEFT JOIN college.enrollments e ON s.student_id = e.student_id
LEFT JOIN college.courses c ON e.course_id = c.course_id
ORDER BY s.student_id, c.title;

-- =====================================================================
-- 6. Порівняння USING та ON: вплив на структуру стовпців вибірки
-- =====================================================================

-- Варіант А: USING (department_id присутній у результуючому наборі лише ОДИН раз)
SELECT *
FROM college.departments d
JOIN college.courses c USING (department_id)
LIMIT 1;

-- Варіант Б: ON (обидва однойменні стовпці d.department_id та c.department_id
-- потрапляють до вибірки окремо, що дозволяє використовувати нееквівалентні умови)
SELECT d.department_id AS dep_pk,
       c.department_id AS course_fk,
       d.name AS department_name,
       c.title AS course_title
FROM college.departments d
JOIN college.courses c ON d.department_id = c.department_id;
