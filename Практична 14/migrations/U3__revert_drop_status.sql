-- =====================================================================
-- Зворотна міграція U3: Відкат видалення status (відновлення стовпця)
-- =====================================================================

-- Крок 1. Відновлення стовпця status
ALTER TABLE college.enrollments
    ADD COLUMN status VARCHAR(12) NOT NULL DEFAULT 'active';

-- Крок 2. Відновлення значень на основі completed_at
UPDATE college.enrollments
SET status = 'completed'
WHERE completed_at IS NOT NULL;

-- Крок 3. Додавання обмеження CHECK
ALTER TABLE college.enrollments
    ADD CONSTRAINT enrollments_status_check
    CHECK (status IN ('active', 'completed', 'cancelled'));

-- Крок 4. Видалення тимчасового стовпця completed_at
ALTER TABLE college.enrollments DROP COLUMN IF EXISTS completed_at;
