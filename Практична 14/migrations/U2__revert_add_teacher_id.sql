-- =====================================================================
-- Зворотна міграція U2: Відкат додавання teacher_id до courses
-- =====================================================================

-- Крок 1. Видалення обмеження зовнішнього ключа
ALTER TABLE college.courses DROP CONSTRAINT IF EXISTS fk_courses_teacher;

-- Крок 2. Видалення стовпця teacher_id з таблиці courses
ALTER TABLE college.courses DROP COLUMN IF EXISTS teacher_id;

-- Крок 3. Видалення таблиці викладачів
DROP TABLE IF EXISTS college.teachers CASCADE;
