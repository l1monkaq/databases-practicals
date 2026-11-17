-- =====================================================================
-- Практична робота №12. Нормалізація реляційних таблиць до 3НФ і BCNF
-- Предмет: Бази даних | Група: ІПЗ-41 | Виконала: Єва Якимчук
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS college_normalized;

-- Очищення перед розгортанням
DROP TABLE IF EXISTS college_normalized.student_advisors CASCADE;
DROP TABLE IF EXISTS college_normalized.advisor_courses CASCADE;
DROP TABLE IF EXISTS college_normalized.enrollments CASCADE;
DROP TABLE IF EXISTS college_normalized.courses CASCADE;
DROP TABLE IF EXISTS college_normalized.teachers CASCADE;
DROP TABLE IF EXISTS college_normalized.departments CASCADE;
DROP TABLE IF EXISTS college_normalized.students CASCADE;
DROP TABLE IF EXISTS college_normalized.unnormalized_registry CASCADE;

-- ---------------------------------------------------------------------
-- 1. Демонстрація вихідного ненормалізованого відношення (1НФ з аномаліями)
-- ---------------------------------------------------------------------
CREATE TABLE college_normalized.unnormalized_registry (
    student_id INTEGER NOT NULL,
    student_name VARCHAR(150) NOT NULL,
    group_code VARCHAR(12) NOT NULL,
    student_email VARCHAR(254) NOT NULL,
    course_id INTEGER NOT NULL,
    course_code VARCHAR(12) NOT NULL,
    course_title VARCHAR(150) NOT NULL,
    credits SMALLINT NOT NULL,
    tuition_fee NUMERIC(10,2) NOT NULL,
    department_id INTEGER NOT NULL,
    department_code VARCHAR(10) NOT NULL,
    department_name TEXT NOT NULL,
    head_of_department VARCHAR(150) NOT NULL,
    teacher_id INTEGER NOT NULL,
    teacher_name VARCHAR(150) NOT NULL,
    teacher_email VARCHAR(254) NOT NULL,
    enrolled_on DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(12) NOT NULL,
    grade SMALLINT,
    PRIMARY KEY (student_id, course_id)
);

-- Вставка початкових даних (дублювання інформації кафедр, викладачів та курсів)
INSERT INTO college_normalized.unnormalized_registry VALUES
(101, 'Іваненко Марія', '121', 'm.ivanenko@example.edu', 1, 'DB', 'Бази даних', 4, 1200.00, 10, 'IT', 'Кафедра ІТ', 'Проф. Ковальчук', 501, 'Олексієнко В.М.', 'oleks@example.edu', '2026-09-01', 'completed', 92),
(102, 'Петренко Олег', '121', 'o.petrenko@example.edu', 1, 'DB', 'Бази даних', 4, 1200.00, 10, 'IT', 'Кафедра ІТ', 'Проф. Ковальчук', 501, 'Олексієнко В.М.', 'oleks@example.edu', '2026-09-01', 'completed', 85),
(103, 'Шевчук Анна', '122', 'a.shevchuk@example.edu', 3, 'PHY', 'Загальна фізика', 5, 950.00, 20, 'FIZ', 'Кафедра Фізики', 'Доц. Мельник', 502, 'Савченко Т.П.', 'savchenko@example.edu', '2026-09-02', 'active', NULL);

-- Демонстрація аномалії оновлення (Update Anomaly):
-- Зміна завідувача кафедри ІТ потребує оновлення всіх записів студентів на курсах цієї кафедри:
-- UPDATE college_normalized.unnormalized_registry SET head_of_department = 'Проф. Сидоренко' WHERE department_id = 10;

-- ---------------------------------------------------------------------
-- 2. Нормалізована схема (3НФ та BCNF)
-- ---------------------------------------------------------------------

-- Кафедри (усунуто транзитивну залежність department_id -> department_name, head)
CREATE TABLE college_normalized.departments (
    department_id INTEGER PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name TEXT NOT NULL,
    head_of_department VARCHAR(150) NOT NULL
);

-- Викладачі (усунуто транзитивну залежність teacher_id -> teacher_name, email, department_id)
CREATE TABLE college_normalized.teachers (
    teacher_id INTEGER PRIMARY KEY,
    department_id INTEGER NOT NULL REFERENCES college_normalized.departments(department_id) ON DELETE RESTRICT,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(254) NOT NULL UNIQUE
);

-- Курси (усунуто часткові залежності від складеного ключа реєстрації)
CREATE TABLE college_normalized.courses (
    course_id INTEGER PRIMARY KEY,
    department_id INTEGER NOT NULL REFERENCES college_normalized.departments(department_id) ON DELETE RESTRICT,
    code VARCHAR(12) NOT NULL UNIQUE,
    title VARCHAR(150) NOT NULL,
    credits SMALLINT NOT NULL CHECK (credits BETWEEN 1 AND 30),
    tuition_fee NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (tuition_fee >= 0)
);

-- Студенти (усунуто часткову залежність student_id -> student_name, group, email)
CREATE TABLE college_normalized.students (
    student_id INTEGER PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    group_code VARCHAR(12) NOT NULL,
    email VARCHAR(254) NOT NULL UNIQUE
);

-- Реєстрації на курси (знаходиться в 3НФ / BCNF)
CREATE TABLE college_normalized.enrollments (
    student_id INTEGER NOT NULL REFERENCES college_normalized.students(student_id) ON DELETE CASCADE,
    course_id INTEGER NOT NULL REFERENCES college_normalized.courses(course_id) ON DELETE RESTRICT,
    enrolled_on DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(12) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
    grade SMALLINT CHECK (grade BETWEEN 0 AND 100),
    PRIMARY KEY (student_id, course_id)
);

-- ---------------------------------------------------------------------
-- 3. Класичний кейс нормалізації 3НФ -> BCNF (Керівництво курсовими роботами)
-- Відношення: Advisory(student_id, course_id, advisor_id)
-- Залежності:
--   {student_id, course_id} -> advisor_id (кожен студент з курсу має 1 наукового керівника)
--   advisor_id -> course_id (кожен керівник веде лише 1 конкретний курс)
-- Кандидатні ключі: {student_id, course_id} та {student_id, advisor_id}
-- У 3НФ: advisor_id -> course_id дозволено, бо course_id — первинний атрибут.
-- У BCNF: заборонено, оскільки advisor_id НЕ є суперключем.
-- Декомпозиція до BCNF:
-- ---------------------------------------------------------------------

-- Відношення 1: Прив'язка керівника до курсу (advisor_id є суперключем!)
CREATE TABLE college_normalized.advisor_courses (
    advisor_id INTEGER PRIMARY KEY,
    teacher_id INTEGER NOT NULL REFERENCES college_normalized.teachers(teacher_id) ON DELETE CASCADE,
    course_id INTEGER NOT NULL REFERENCES college_normalized.courses(course_id) ON DELETE RESTRICT
);

-- Відношення 2: Призначення студенту керівника
CREATE TABLE college_normalized.student_advisors (
    student_id INTEGER NOT NULL REFERENCES college_normalized.students(student_id) ON DELETE CASCADE,
    advisor_id INTEGER NOT NULL REFERENCES college_normalized.advisor_courses(advisor_id) ON DELETE CASCADE,
    PRIMARY KEY (student_id, advisor_id)
);

-- ---------------------------------------------------------------------
-- 4. Міграція даних з денормалізованої таблиці в нормалізовані
-- ---------------------------------------------------------------------
INSERT INTO college_normalized.departments (department_id, code, name, head_of_department)
SELECT DISTINCT department_id, department_code, department_name, head_of_department
FROM college_normalized.unnormalized_registry;

INSERT INTO college_normalized.teachers (teacher_id, department_id, full_name, email)
SELECT DISTINCT teacher_id, department_id, teacher_name, teacher_email
FROM college_normalized.unnormalized_registry;

INSERT INTO college_normalized.courses (course_id, department_id, code, title, credits, tuition_fee)
SELECT DISTINCT course_id, department_id, course_code, course_title, credits, tuition_fee
FROM college_normalized.unnormalized_registry;

INSERT INTO college_normalized.students (student_id, full_name, group_code, email)
SELECT DISTINCT student_id, student_name, group_code, student_email
FROM college_normalized.unnormalized_registry;

INSERT INTO college_normalized.enrollments (student_id, course_id, enrolled_on, status, grade)
SELECT student_id, course_id, enrolled_on, status, grade
FROM college_normalized.unnormalized_registry;

-- ---------------------------------------------------------------------
-- 5. Перевірка цілісності та відсутності аномалій
-- ---------------------------------------------------------------------
-- Тепер зміна імені завідувача кафедри виконується в одному рядку без аномалій:
UPDATE college_normalized.departments
SET head_of_department = 'Проф. Сидоренко О.В.'
WHERE department_id = 10;

-- Контрольний запит відновлення повних даних без втрат (Lossless Join):
SELECT s.student_id,
       s.full_name AS student,
       c.code AS course,
       d.name AS department,
       d.head_of_department,
       e.status,
       e.grade
FROM college_normalized.enrollments e
JOIN college_normalized.students s USING (student_id)
JOIN college_normalized.courses c USING (course_id)
JOIN college_normalized.departments d USING (department_id);
