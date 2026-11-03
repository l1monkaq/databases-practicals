# Практична робота №4. Перетворення ER-діаграми у реляційну схему

**Предмет:** Бази даних  | **Група:** ІПЗ-41  | **Виконала:** Єва Якимчук

## Перетворення сутностей
| Сутність ER | Реляційна таблиця | PK | Домени й атрибути |
|---|---|---|---|
| Book | `library.books` | `book_id` | назва VARCHAR(200), автор VARCHAR(150), ISBN VARCHAR(17), рік SMALLINT, жанр VARCHAR(80) |
| Copy | `library.copies` | `copy_id` | `book_id` INTEGER, інвентарний № VARCHAR(30), стан VARCHAR(20) |
| Reader | `library.readers` | `reader_id` | ПІБ VARCHAR(150), номер квитка VARCHAR(30), телефон VARCHAR(25), дата DATE |
| Employee | `library.employees` | `employee_id` | ПІБ VARCHAR(150), посада VARCHAR(60) |
| Loan | `library.loans` | `loan_id` | `copy_id`, `reader_id`, `employee_id` INTEGER, дати DATE |

## Зв'язки і правила перетворення
| Зв'язок | Кардинальність | Зовнішній ключ | Видалення |
|---|---|---|---|
| Book → Copy | 1:N | `copies.book_id NOT NULL` | RESTRICT |
| Copy → Loan | 1:N | `loans.copy_id NOT NULL` | RESTRICT |
| Reader → Loan | 1:N | `loans.reader_id NOT NULL` | RESTRICT |
| Employee → Loan | 1:N | `loans.employee_id NOT NULL` | RESTRICT |
| Reader ↔ Copy | M:N у часі | асоціативна таблиця `loans` із власним PK | історія не губиться |

Таблиця `loans` розбиває M:N на два зв'язки 1:N та зберігає дату, термін повернення й працівника. Для простої таблиці без власних атрибутів зв'язку можна використати складений PK із двох FK. Тут **складений PK (`reader_id`, `copy_id`) непридатний**, оскільки один читач може позичати той самий примірник повторно; тому обрано `loan_id`.

## Обмеження цілісності
- `books`: PK, NOT NULL назви й автора, UNIQUE ISBN, CHECK року 1450–2100.
- `copies`: PK, FK NOT NULL і RESTRICT, UNIQUE інвентарного номера, CHECK стану, DEFAULT `good`.
- `readers`: PK, NOT NULL ПІБ, UNIQUE та NOT NULL номер квитка, DEFAULT поточної дати.
- `employees`: PK, NOT NULL ПІБ та посади.
- `loans`: PK; три обов'язкові FK з RESTRICT, дати початку/закінчення CHECK; частковий UNIQUE-індекс за `copy_id` для активної видачі (`returned_at IS NULL`).

Схема на рисунку `relational_schema.png` та редаговане джерело `relational_schema.dot`. `schema.sql` — її реалізація у PostgreSQL.

## Питання для захисту
1. FK на боці «багато», бо кожен дочірній рядок указує рівно на одного батька.
2. Посилальна цілісність — відсутність FK, які вказують на неіснуючий рядок; її контролює FOREIGN KEY.
3. M:N розбивають через проміжну таблицю з двома зовнішніми ключами; тут вона має власний PK через повторні позики.
4. `ON DELETE RESTRICT` не дозволить видалити батька за наявності пов'язаних дочірніх рядків.


## Висновок
Перетворено п’ять сутностей попередньої ER-моделі у п’ять таблиць. Визначено типи, ключі, обмеження, правила видалення та унікальність активної видачі.
