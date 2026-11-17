-- =====================================================================
-- Міграція V2: Додавання сутності teachers та обов'язкового поля teacher_id до courses
-- Безпечний багатоетапний патерн для збереження цілісності наявних даних
-- =====================================================================

-- Крок 1. Створення таблиці викладачів
CREATE TABLE IF NOT EXISTS college.teachers (
    teacher_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(254) NOT NULL UNIQUE,
    department_id INTEGER NOT NULL REFERENCES college.departments(department_id) ON DELETE RESTRICT
);

-- Крок 2. Наповнення базовими викладачами (включно з черговим викладачем за замовчуванням)
INSERT INTO college.teachers (full_name, email, department_id) VALUES
('Олексієнко Василь Михайлович', 'v.oleksienko@example.edu', 1),
('Мельник Тетяна Петрівна', 't.melnyk@example.edu', 2),
('Кафедральний викладач (Default)', 'default.teacher@example.edu', 1);

-- Крок 3. Додавання стовпця teacher_id як NULLABLE (щоб уникнути помилки на наявних рядках)
ALTER TABLE college.courses ADD COLUMN teacher_id INTEGER;

-- Крок 4. Заповнення (Backfill) наявних курсів відповідними викладачами
UPDATE college.courses SET teacher_id = 1 WHERE code IN ('DB', 'WEB');
UPDATE college.courses SET teacher_id = 2 WHERE code = 'PHY';

-- Якщо залишаються нерозподілені курси, призначаємо дефолтного викладача:
UPDATE college.courses SET teacher_id = 3 WHERE teacher_id IS NULL;

-- Крок 5. Встановлення обмеження NOT NULL після гарантованого заповнення
ALTER TABLE college.courses ALTER COLUMN teacher_id SET NOT NULL;

-- Крок 6. Додавання обмеження зовнішнього ключа
ALTER TABLE college.courses
    ADD CONSTRAINT fk_courses_teacher
    FOREIGN KEY (teacher_id) REFERENCES college.teachers(teacher_id)
    ON DELETE RESTRICT;
