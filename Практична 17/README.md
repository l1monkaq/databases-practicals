# Практична робота №17. Складні багатотабличні запити (JOIN + підзапити)

**Предмет:** Бази даних  | **Група:** ІПЗ-41  | **Виконала:** Єва Якимчук

---

## 1. Мета роботи
Узагальнити та закріпити практичні компетенції з побудови складних аналітичних SQL-запитів на базі нормалізованої схеми даних. Навчитися комбінувати багатотабличні реляційні з'єднання (`JOIN`), корельовані підзапити, предикати відбору груп (`HAVING`), розширені агрегатні обчислення та операції над множинами (`INTERSECT`).

---

## 2. Структура схеми та початкові дані
Для наскрізного моделювання використано повний комплекс із 5 взаємопов'язаних таблиць схеми `college`:
* `departments`: 3 кафедри (`IT`, `FIZ`, `HUM` — без курсів і викладачів).
* `teachers`: 4 викладачі (`Олексієнко` — 3 курси, `Григоренко` — 1 курс, `Мельник` — 3 курси, `Дмитрук` — 0 курсів).
* `courses`: 7 курсів (зокрема спільний міжкафедральний код `DATA`).
* `students`: 5 студентів (`101`–`105`).
* `enrollments`: 8 реєстрацій із реальними оцінками (`92`, `84`, `78`, `96`, `88`) та статусами (`completed`, `active`, `cancelled`).

---

## 3. Наскрізні складні запити та аналіз результатів

### 3.1. Звіт «Підрозділ $\to$ кількість курсів $\to$ кількість реєстрацій»
```sql
SELECT d.name AS department,
       COUNT(DISTINCT c.course_id) AS courses,
       COUNT(e.student_id) AS enrollments
FROM college.departments AS d
LEFT JOIN college.courses AS c USING (department_id)
LEFT JOIN college.enrollments AS e USING (course_id)
GROUP BY d.name
ORDER BY enrollments DESC, courses DESC;
```
* **Очікуваний результат:**

| department | courses | enrollments |
|---|---:|---:|
| Інформаційні технології | 4 | 6 |
| Фізика | 3 | 2 |
| Гуманітарні науки | 0 | 0 |

* **Аналіз:** Подвійний `LEFT JOIN` забезпечує присутність кафедри «Гуманітарні науки» (0 курсів, 0 реєстрацій). Обов'язкове використання `COUNT(DISTINCT c.course_id)` запобігає аномалії множення: якби використовувався звичайний `COUNT(c.course_id)`, кількість курсів штучно помножилася б на кількість студентів у них.

---

### 3.2. «Середній бал студента» (GPA) з JOIN, агрегацією та HAVING
```sql
SELECT s.student_id,
       s.full_name AS student_name,
       s.group_code,
       COUNT(e.grade) AS graded_courses_count,
       ROUND(AVG(e.grade), 2) AS gpa
FROM college.students s
JOIN college.enrollments e USING (student_id)
WHERE e.grade IS NOT NULL
GROUP BY s.student_id, s.full_name, s.group_code
HAVING COUNT(e.grade) >= 1
ORDER BY gpa DESC, s.full_name ASC;
```
* **Очікуваний результат:**

| student_id | student_name | group_code | graded_courses_count | gpa |
|---:|---|---|---:|---:|
| 105 | Бондаренко Денис | 121 | 2 | 92.00 |
| 101 | Іваненко Марія | 121 | 1 | 92.00 |
| 102 | Петренко Олег | 121 | 1 | 84.00 |
| 103 | Шевчук Анна | 122 | 1 | 78.00 |

* **Пояснення:** Студент Коваль Назар (104) має лише активну та скасовану реєстрацію без оцінок (`grade IS NULL`), тому відфільтровується секцією `WHERE e.grade IS NOT NULL` і не потрапляє у рейтинг.

---

### 3.3. «Курси, які жодного разу не обрали»: Порівняння двох підходів

#### Спосіб А: `LEFT JOIN` + перевірка `IS NULL`
```sql
SELECT c.course_id, c.code, c.title, d.name AS department_name
FROM college.courses c
JOIN college.departments d USING (department_id)
LEFT JOIN college.enrollments e USING (course_id)
WHERE e.student_id IS NULL
ORDER BY c.course_id;
```

#### Спосіб Б: Анти-з'єднання через `NOT EXISTS`
```sql
SELECT c.course_id, c.code, c.title, d.name AS department_name
FROM college.courses c
JOIN college.departments d USING (department_id)
WHERE NOT EXISTS (
    SELECT 1 FROM college.enrollments e WHERE e.course_id = c.course_id
)
ORDER BY c.course_id;
```

* **Очікуваний результат (однаковий для обох способів):**

| course_id | code | title | department_name |
|---:|---|---|---|
| 3 | SEC | Кібербезпека | Інформаційні технології |
| 4 | DATA | Аналіз даних і статистика | Інформаційні технології |
| 6 | AST | Астрономія | Фізика |
| 7 | DATA | Статистичні методи у фізиці | Фізика |

* **Порівняння підходів:**

| Критерій | `LEFT JOIN + IS NULL` | `NOT EXISTS` |
|---|---|---|
| **Семантична читабельність** | Потребує аналізу зовнішнього з'єднання та фільтрації за первинним ключем правої таблиці. | Інтуїтивно зрозумілий вираз «де не існує реєстрацій». |
| **План виконання (PostgreSQL)** | Виконує `Hash Left Join`, генерує проміжні `NULL` і потім фільтрує їх. | Трансформується оптимізатором у високоефективний `HashSetOp Anti Join`, який зупиняє пошук при першому збігу. |
| **Стійкість до NULL** | Вимагає перевірки суворо на поле `NOT NULL` (PK). | Абсолютно безпечний до наявності `NULL` у внутрішніх полях. |

---

### 3.4. «Викладачі, які ведуть найбільше курсів»
```sql
SELECT t.teacher_id,
       t.full_name AS teacher_name,
       d.name AS department_name,
       COUNT(c.course_id) AS courses_taught
FROM college.teachers t
JOIN college.departments d USING (department_id)
JOIN college.courses c USING (teacher_id)
GROUP BY t.teacher_id, t.full_name, d.name
HAVING COUNT(c.course_id) = (
    SELECT MAX(course_count)
    FROM (
        SELECT COUNT(course_id) AS course_count
        FROM college.courses
        WHERE teacher_id IS NOT NULL
        GROUP BY teacher_id
    ) sub
)
ORDER BY t.teacher_id;
```
* **Очікуваний результат:**
  * Олексієнко В.М. (3 курси) та Мельник Т.П. (3 курси). Запит коректно обробляє ситуацію нічиєї (tie) між лідерами завдяки використанню підзапиту максимуму в `HAVING`.

---

### 3.5. Студенти з оцінкою вищою за середню по курсу (Корельований підзапит)
```sql
SELECT s.student_id,
       s.full_name AS student_name,
       c.code AS course_code,
       c.title AS course_title,
       e.grade AS student_grade,
       ROUND((
           SELECT AVG(e2.grade)
           FROM college.enrollments e2
           WHERE e2.course_id = e.course_id
       ), 2) AS course_average_grade
FROM college.enrollments e
JOIN college.students s USING (student_id)
JOIN college.courses c USING (course_id)
WHERE e.grade > (
    SELECT AVG(e2.grade)
    FROM college.enrollments e2
    WHERE e2.course_id = e.course_id
)
ORDER BY c.code, e.grade DESC;
```
* **Очікуваний результат:**
  * Курс `DB`: оцінки 92, 84, 96 (середня = 90.67). Вище середнього:
    * Бондаренко Денис (96 > 90.67);
    * Іваненко Марія (92 > 90.67).
  * Курс `PHY`: оцінки 78, 88 (середня = 83.00). Вище середнього:
    * Бондаренко Денис (88 > 83.00).

---

### 3.6. Операція над множинами: `INTERSECT`
Знаходження дисциплін, які читаються одночасно на кафедрі ІТ (`dep=1`) та кафедрі Фізики (`dep=2`):
```sql
SELECT code FROM college.courses WHERE department_id = 1
INTERSECT
SELECT code FROM college.courses WHERE department_id = 2
ORDER BY code;
```
* **Очікуваний результат:** код `DATA` (потужність множини $|R| = 1$).

---

## 4. Відповіді на питання для захисту

1. **Як вирішити, що використати: JOIN чи підзапит?**
   * **`JOIN`** обирають, коли в кінцевий вивід `SELECT` необхідно включити стовпці з кількох таблиць одночасно, або коли потрібно згрупувати дані за комбінованими атрибутами.
   * **Підзапит (`EXISTS`, `IN`)** обирають, коли потрібно лише перевірити наявність/відсутність зв'язаних фактів у дочірній таблиці без виведення її стовпців (Semi-Join / Anti-Join), або коли потрібно розрахувати скалярний поріг (наприклад, середнє по курсу).

2. **Чому `COUNT(DISTINCT ...)` потрібен після множення рядків через JOIN?**
   Коли таблиця з'єднується з двома дочірніми таблицями зі зв'язками $1:N$ і $1:M$ (наприклад, `departments` $\to$ `courses` та `courses` $\to$ `enrollments`), утворюється декартовий добуток на рівні рядків. Ідентифікатори курсів дублюються стільки разів, скільки студентів записано на кожен курс. Простий `COUNT(course_id)` підрахував би не кількість курсів, а кількість реєстрацій. `COUNT(DISTINCT course_id)` примусово усуває дублікати перед підрахунком.

3. **Як перевірити коректність складного запиту?**
   * **Покрокове складання (Bottom-Up):** запускати та верифікувати кожен підзапит або окремий JOIN окремо перед їх об'єднанням.
   * **Контроль кількості рядків:** перевіряти потужність вибірки до і після з'єднань, контролюючи відсутність небажаного декартового множення.
   * **Тестові крайові кейси:** внесення нульових значень (`NULL`), записів без пар, однакових значень для перевірки `HAVING` і `DISTINCT`.
   * **Аналіз плану виконання:** використання команди `EXPLAIN (ANALYZE, BUFFERS)` для перевірки типів сканування та виявлення прихованих вузьких місць.

4. **Що змінить `LEFT JOIN` на `INNER JOIN` у першому запиті?**
   Заміна `LEFT JOIN` на `INNER JOIN` призведе до вилучення кафедри «Гуманітарні науки» (оскільки вона не має курсів), а також до вилучення курсів, які не мають жодної реєстрації студента. Замість повного звіту про структуру коледжу запит виведе лише ті підрозділи, де триває навчальний процес.

---

## 5. Підсумковий висновок
У практичній роботі побудовано комплексний аналітичний набір запитів для повноцінної реляційної системи навчального закладу. Досліджено ефект множення рядків у ланцюжках з'єднань, обґрунтовано застосування `COUNT(DISTINCT)` та порівняно альтернативні патерни пошуку незбігів (`LEFT JOIN + IS NULL` проти `NOT EXISTS`). Створені запити оптимізовані та задокументовані у файлі `advanced.sql`.
