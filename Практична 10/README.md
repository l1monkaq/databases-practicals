# Практична робота №10. Реалізація цілісності даних: ключі та обмеження

**Предмет:** Бази даних  | **Група:** ІПЗ-41  | **Виконала:** Єва Якимчук

## Перевірка обмежень
Файл `constraints.sql` створює окрему схему `integrity_demo`, щоб не пошкоджувати дані практичних №7–9. Для зв'язку курс/підрозділ у схемі `college` вже задано `ON DELETE RESTRICT` (`practice-07/schema.sql`). Наведені помилки є **типовими очікуваними PostgreSQL-повідомленнями**: їх фактичний текст і деталі залежать від версії та даних; після запуску скопіювати власний вивід NOTICE.

| Обмеження | Команда, що порушує правило | Типовий текст / SQLSTATE |
|---|---|---|
| PRIMARY KEY | `INSERT ... OVERRIDING SYSTEM VALUE ... id=1` | duplicate key value violates unique constraint (23505) |
| UNIQUE | `INSERT ... ref_code='ONE'` удруге | duplicate key value violates unique constraint (23505) |
| NOT NULL | `INSERT ... title=NULL` | null value in column ... violates not-null constraint (23502) |
| FOREIGN KEY | `INSERT ... parent_id=999` | violates foreign key constraint (23503) |
| CHECK | `INSERT ... score=101` | violates check constraint (23514) |
| RESTRICT | `DELETE FROM parents WHERE parent_id=1` (є дочірні записи) | update or delete ... violates foreign key constraint (23503) |

## Каскадна дія
`parents(2)` має два записи в `children`, не має записів у `samples`. До видалення `COUNT(children WHERE parent_id=2)=2`; команда `DELETE FROM parents WHERE parent_id=2` автоматично видалить обидва дочірні записи, після — 0. Для `college.departments` і `college.courses` використано **RESTRICT**, оскільки автоматично знищувати курси при видаленні підрозділу небезпечно.

## UNIQUE / NULL, CHECK / DEFAULT
У звичайному PostgreSQL `UNIQUE` дозволяє декілька `NULL`: вставка двох рядків із `ref_code=NULL` допускається, очікуваний COUNT=2 (не використано `NULLS NOT DISTINCT`). CHECK у PostgreSQL приймає `TRUE` або `UNKNOWN`, отже простий CHECK не забороняє NULL; необхідно додати NOT NULL. `DEFAULT 50` спрацьовує, коли `score` не задано або явно вказано DEFAULT, але **не замінює явно переданий NULL**; тому також задано NOT NULL.

## Питання для захисту
1. CHECK при NULL часто дає UNKNOWN і не відхиляє значення; для заборони NULL потрібен NOT NULL.
2. CASCADE — для залежних технічних рядків, RESTRICT — для важливих даних, які не можна видаляти автоматично.
3. Типова семантика UNIQUE вважає різні NULL не рівними; у PostgreSQL можлива альтернатива `NULLS NOT DISTINCT`.
4. FK захищає від посилання на неіснуючий батьківський запис.


## Висновок
Підготовлено ізольований скрипт перевірки всіх основних обмежень, RESTRICT, CASCADE, NULL та DEFAULT. Фактичні повідомлення помилок потрібно підтвердити запуском PostgreSQL.
