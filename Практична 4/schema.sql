-- PostgreSQL. Run inside database college using psql -v ON_ERROR_STOP=1 -f schema.sql
CREATE SCHEMA IF NOT EXISTS library;
DROP TABLE IF EXISTS library.loans, library.copies, library.readers, library.employees, library.books CASCADE;
CREATE TABLE library.books (
 book_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 title VARCHAR(200) NOT NULL,
 author VARCHAR(150) NOT NULL,
 isbn VARCHAR(17) UNIQUE,
 publication_year SMALLINT CHECK (publication_year BETWEEN 1450 AND 2100),
 genre VARCHAR(80)
);
CREATE TABLE library.copies (
 copy_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 book_id INTEGER NOT NULL REFERENCES library.books(book_id) ON DELETE RESTRICT,
 inventory_number VARCHAR(30) NOT NULL UNIQUE,
 condition VARCHAR(20) NOT NULL DEFAULT 'good' CHECK (condition IN ('new','good','worn','repair'))
);
CREATE TABLE library.readers (
 reader_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 full_name VARCHAR(150) NOT NULL,
 card_number VARCHAR(30) NOT NULL UNIQUE,
 phone VARCHAR(25),
 registered_at DATE NOT NULL DEFAULT CURRENT_DATE
);
CREATE TABLE library.employees (
 employee_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 full_name VARCHAR(150) NOT NULL,
 role VARCHAR(60) NOT NULL
);
CREATE TABLE library.loans (
 loan_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 copy_id INTEGER NOT NULL REFERENCES library.copies(copy_id) ON DELETE RESTRICT,
 reader_id INTEGER NOT NULL REFERENCES library.readers(reader_id) ON DELETE RESTRICT,
 employee_id INTEGER NOT NULL REFERENCES library.employees(employee_id) ON DELETE RESTRICT,
 issued_at DATE NOT NULL DEFAULT CURRENT_DATE,
 due_at DATE NOT NULL,
 returned_at DATE,
 CONSTRAINT ck_loan_dates CHECK (due_at >= issued_at AND (returned_at IS NULL OR returned_at >= issued_at))
);
CREATE UNIQUE INDEX uq_library_active_copy ON library.loans(copy_id) WHERE returned_at IS NULL;
