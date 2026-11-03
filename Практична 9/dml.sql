-- Prerequisite: practice-07/schema.sql (fresh college tables). Run as a whole in PostgreSQL.
BEGIN;
INSERT INTO college.departments (code,name) VALUES
 ('IT','Інформаційні технології'), ('FIZ','Фізика');
INSERT INTO college.courses(department_id,code,title,credits,tuition_fee)
VALUES (1,'DB','Бази даних',4,1200.00), (1,'WEB','Вебтехнології',3,1100.00), (2,'PHY','Фізика',5,950.00);
INSERT INTO college.students(student_id,full_name,group_code,email) VALUES
 (101,'Іваненко Марія','121','m.ivanenko@example.edu'),
 (102,'Петренко Олег','121','o.petrenko@example.edu'),
 (103,'Шевчук Анна','122',NULL),
 (104,'Коваль Назар','123','n.koval@example.edu') RETURNING student_id,full_name;
INSERT INTO college.enrollments(student_id,course_id,status,grade) VALUES
 (101,1,'active',NULL), (101,2,'active',NULL), (102,1,'active',NULL),
 (103,3,'active',NULL), (104,2,'cancelled',NULL);
-- BEFORE snapshots
SELECT student_id,course_id,status FROM college.enrollments WHERE student_id=101 ORDER BY course_id;
SELECT student_id,course_id,status FROM college.enrollments WHERE student_id=104 AND course_id=2;
-- Targeted UPDATE, only one enrollment
UPDATE college.enrollments SET status='completed',grade=92 WHERE student_id=101 AND course_id=1 RETURNING student_id,course_id,status,grade;
SELECT student_id,course_id,status,grade FROM college.enrollments WHERE student_id=101 ORDER BY course_id;
-- Targeted DELETE, only one link, not student or course
DELETE FROM college.enrollments WHERE student_id=104 AND course_id=2 RETURNING student_id,course_id;
SELECT student_id,course_id,status FROM college.enrollments WHERE student_id=104 AND course_id=2;
-- Five SELECT queries
SELECT student_id AS id,full_name AS student FROM college.students ORDER BY student_id;
SELECT course_id,title AS course,credits,credits*30 AS estimated_hours FROM college.courses ORDER BY credits DESC;
SELECT code AS department_code,name AS department FROM college.departments ORDER BY code;
SELECT student_id,course_id,status,grade,COALESCE(grade,0) AS grade_or_zero FROM college.enrollments ORDER BY student_id,course_id;
SELECT title AS course,tuition_fee,ROUND(tuition_fee*1.10,2) AS increased_fee FROM college.courses ORDER BY title;
COMMIT;
