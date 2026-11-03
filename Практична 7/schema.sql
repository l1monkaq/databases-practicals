-- Run in database college; creates schema and four linked tables.
CREATE SCHEMA IF NOT EXISTS college;
DROP TABLE IF EXISTS college.enrollments, college.students, college.courses, college.departments CASCADE;
CREATE TABLE college.departments (
 department_id INTEGER GENERATED ALWAYS AS IDENTITY,
 code VARCHAR(10) NOT NULL,
 name TEXT NOT NULL,
 CONSTRAINT pk_departments PRIMARY KEY (department_id),
 CONSTRAINT uq_departments_code UNIQUE (code)
);
CREATE TABLE college.courses (
 course_id INTEGER GENERATED ALWAYS AS IDENTITY,
 department_id INTEGER NOT NULL,
 code VARCHAR(12) NOT NULL,
 title VARCHAR(150) NOT NULL,
 credits SMALLINT NOT NULL CHECK (credits BETWEEN 1 AND 30),
 tuition_fee NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (tuition_fee >= 0),
 CONSTRAINT pk_courses PRIMARY KEY (course_id),
 CONSTRAINT uq_courses_code UNIQUE (code),
 CONSTRAINT fk_courses_department FOREIGN KEY (department_id) REFERENCES college.departments(department_id) ON DELETE RESTRICT
);
CREATE TABLE college.students (
 student_id INTEGER PRIMARY KEY,
 full_name VARCHAR(150) NOT NULL,
 group_code VARCHAR(12) NOT NULL,
 email VARCHAR(254) UNIQUE
);
CREATE TABLE college.enrollments (
 student_id INTEGER NOT NULL,
 course_id INTEGER NOT NULL,
 status VARCHAR(12) NOT NULL DEFAULT 'active' CHECK (status IN ('active','completed','cancelled')),
 grade SMALLINT CHECK (grade BETWEEN 0 AND 100),
 enrolled_on DATE NOT NULL DEFAULT CURRENT_DATE,
 CONSTRAINT pk_enrollments PRIMARY KEY (student_id, course_id),
 CONSTRAINT fk_enrollments_student FOREIGN KEY (student_id) REFERENCES college.students(student_id) ON DELETE CASCADE,
 CONSTRAINT fk_enrollments_course FOREIGN KEY (course_id) REFERENCES college.courses(course_id) ON DELETE RESTRICT
);
SELECT table_name FROM information_schema.tables WHERE table_schema = 'college' AND table_type = 'BASE TABLE' ORDER BY table_name;
