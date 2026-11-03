# Практична робота №7. Визначення схем у SQL/DDL

**Предмет:** Бази даних  | **Група:** ІПЗ-41  | **Виконала:** Єва Якимчук

## Створені таблиці
`schema.sql` створює навчальну схему `college`, чотири таблиці і перевіряє їх наявність. Таблиці `departments`, `courses`, `enrollments` обов'язкові; `students` додано, щоб зовнішній ключ із `enrollments` був коректним.

## Вибір типів
| Таблиця | Поле(я) | Тип і пояснення |
|---|---|---|
| departments | department_id | INTEGER IDENTITY — зростаючий PK |
| departments | code; name | VARCHAR(10) — короткий код; TEXT — довільна назва |
| courses | course_id; department_id | INTEGER — PK/FK однакового типу |
| courses | code; title | VARCHAR(12), VARCHAR(150) — обмежена довжина |
| courses | credits | SMALLINT — невелика кількість кредитів, CHECK 1..30 |
| courses | tuition_fee | NUMERIC(10,2) — точні суми без похибки REAL |
| students | student_id | INTEGER — узгоджується з номером студента 101 |
| students | full_name; group_code; email | VARCHAR(150), VARCHAR(12), VARCHAR(254) — текст з лімітами |
| enrollments | student_id; course_id | INTEGER — складений PK і два FK |
| enrollments | status; grade; enrolled_on | VARCHAR(12) CHECK, SMALLINT CHECK, DATE DEFAULT |

**Порядок:** departments → courses; students → enrollments, courses → enrollments. Програма виводить список таблиць через `information_schema.tables`.

## Скриншот для здачі
Після запуску SQL у PostgreSQL зробити `tables.png` із результатом SELECT або списком таблиць у pgAdmin. Фактичний скриншот ще не отримано.

## Питання для захисту
1. `NUMERIC` точний десятковий тип, `REAL` має бінарну похибку.
2. Імена обмежень полегшують діагностику помилок та міграції.
3. `GENERATED ALWAYS AS IDENTITY` — автоматично генероване значення стовпця (звичайне ручне присвоєння обмежене).
4. Спершу батьківські таблиці, потім дочірні з зовнішніми ключами.


## Висновок
Створено відтворюваний DDL для навчальних таблиць, ключів та обмежень. Для скриншота потрібен запуск у PostgreSQL.
