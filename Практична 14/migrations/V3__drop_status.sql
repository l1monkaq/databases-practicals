-- =====================================================================
-- Міграція V3: Видалення стовпця status у таблиці enrollments
-- Статус тепер визначається динамічно за значенням grade або completed_at
-- =====================================================================

-- Крок 1. Додавання дати завершення замість текстового статусу
ALTER TABLE college.enrollments ADD COLUMN completed_at DATE;

-- Крок 2. Перенесення даних: якщо статус був 'completed', виставляємо дату
UPDATE college.enrollments
SET completed_at = CURRENT_DATE
WHERE status = 'completed';

-- Крок 3. Видалення застарілого обмеження CHECK
ALTER TABLE college.enrollments DROP CONSTRAINT IF EXISTS enrollments_status_check;

-- Крок 4. Видалення стовпця status
ALTER TABLE college.enrollments DROP COLUMN status;
