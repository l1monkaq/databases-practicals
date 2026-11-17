-- =====================================================================
-- Міграція V1: Початкова ініціалізація схеми college (базові таблиці)
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS college;

CREATE TABLE IF NOT EXISTS college.departments (
    department_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS college.courses (
    course_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_id INTEGER NOT NULL REFERENCES college.departments(department_id) ON DELETE RESTRICT,
    code VARCHAR(12) NOT NULL UNIQUE,
    title VARCHAR(150) NOT NULL,
    credits SMALLINT NOT NULL CHECK (credits BETWEEN 1 AND 30),
    tuition_fee NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (tuition_fee >= 0)
);

CREATE TABLE IF NOT EXISTS college.students (
    student_id INTEGER PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    group_code VARCHAR(12) NOT NULL,
    email VARCHAR(254) UNIQUE
);

CREATE TABLE IF NOT EXISTS college.enrollments (
    student_id INTEGER NOT NULL REFERENCES college.students(student_id) ON DELETE CASCADE,
    course_id INTEGER NOT NULL REFERENCES college.courses(course_id) ON DELETE RESTRICT,
    status VARCHAR(12) NOT NULL DEFAULT 'active' CHECK (status IN ('active','completed','cancelled')),
    grade SMALLINT CHECK (grade BETWEEN 0 AND 100),
    enrolled_on DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (student_id, course_id)
);

-- Початкові дані
INSERT INTO college.departments (code, name) VALUES
('IT', 'Інформаційні технології'),
('FIZ', 'Фізика');

INSERT INTO college.courses (department_id, code, title, credits, tuition_fee) VALUES
(1, 'DB', 'Бази даних', 4, 1200.00),
(1, 'WEB', 'Вебтехнології', 3, 1100.00),
(2, 'PHY', 'Загальна фізика', 5, 950.00);

INSERT INTO college.students (student_id, full_name, group_code, email) VALUES
(101, 'Іваненко Марія', '121', 'm.ivanenko@example.edu'),
(102, 'Петренко Олег', '121', 'o.petrenko@example.edu');

INSERT INTO college.enrollments (student_id, course_id, status, grade) VALUES
(101, 1, 'active', NULL),
(102, 1, 'completed', 90);
