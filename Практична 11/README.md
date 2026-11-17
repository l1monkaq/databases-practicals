# Практична робота №11. Агрегація, групування та операції над множинами

**Предмет:** Бази даних  | **Група:** ІПЗ-41  | **Виконала:** Єва Якимчук

---

## 1. Мета роботи
Опанувати практичні навички побудови аналітичних звітів за допомогою агрегатних функцій SQL (`COUNT`, `AVG`, `MIN`, `MAX`, `SUM`), секцій групування `GROUP BY`, постфільтрації агрегованих груп за допомогою `HAVING`, а також теоретико-множинних операцій (`UNION`, `UNION ALL`, `INTERSECT`, `EXCEPT`).

---

## 2. Початкові дані схеми `college`
Використовується схема `college` (файл `aggregates.sql`), що містить 4 взаємопов'язані таблиці:
* `departments`: 3 підрозділи (`IT`, `FIZ`, `HUM` — гуманітарні науки без курсів для перевірки крайових випадків).
* `courses`: 5 курсів (`DB` 4 кр., `WEB` 3 кр., `SEC` 4 кр., `PHY` 5 кр., `AST` 3 кр.).
* `students`: 5 студентів (`101`–`105`).
* `enrollments`: 8 записів реєстрацій із різними статусами (`active`, `completed`, `cancelled`) та оцінками (`92`, `85`, `78`, `95`, `60`, а також значення `NULL` для незавершених).

---

## 3. Виконання завдань та аналіз результатів

### Завдання 1. Звіти з агрегатними функціями

#### 1.1. Кількість курсів у кожному підрозділі
```sql
SELECT d.name AS department_name,
       COUNT(c.course_id) AS total_courses
FROM college.departments d
LEFT JOIN college.courses c ON d.department_id = c.department_id
GROUP BY d.name
ORDER BY total_courses DESC, d.name ASC;
```
* **Очікуваний результат:**

| department_name | total_courses |
|---|---:|
| Інформаційні технології | 3 |
| Фізика | 2 |
| Гуманітарні науки | 0 |

* **Пояснення:** Використання `LEFT JOIN` у комбінації з `COUNT(c.course_id)` гарантує, що кафедра «Гуманітарні науки» не губиться у звіті, а повертає коректне значення `0` (оскільки `COUNT(NULL) = 0`). Якби було використано `COUNT(*)`, для кафедри без курсів результат помилково дорівнював би `1`.

#### 1.2. Середня кількість кредитів курсів
```sql
SELECT ROUND(AVG(credits), 2) AS avg_credits,
       MIN(credits) AS min_credits,
       MAX(credits) AS max_credits,
       SUM(credits) AS total_credits
FROM college.courses;
```
* **Очікуваний результат:**

| avg_credits | min_credits | max_credits | total_credits |
|---:|---:|---:|---:|
| 3.80 | 3 | 5 | 19 |

* **Пояснення:** Агрегація без `GROUP BY` згортає всю вибірку в один результуючий рядок. Середнє значення $(4 + 3 + 4 + 5 + 3) / 5 = 19 / 5 = 3.80$.

#### 1.3. Мінімальна та максимальна оцінка серед реєстрацій
```sql
SELECT MIN(grade) AS min_grade,
       MAX(grade) AS max_grade,
       ROUND(AVG(grade), 2) AS avg_grade,
       COUNT(grade) AS graded_students_count
FROM college.enrollments;
```
* **Очікуваний результат:**

| min_grade | max_grade | avg_grade | graded_students_count |
|---:|---:|---:|---:|
| 60 | 95 | 82.00 | 5 |

* **Пояснення:** Усі агрегатні функції автоматично ігнорують значення `NULL`. З 8 реєстрацій оцінки виставлені для 5: $\{92, 85, 78, 95, 60\}$. Середнє обчислюється як $(92 + 85 + 78 + 95 + 60) / 5 = 410 / 5 = 82.00$.

#### 1.4. Сумарна кількість реєстрацій на курс із фільтрацією `HAVING`
```sql
SELECT c.code AS course_code,
       c.title AS course_title,
       COUNT(e.student_id) AS enrollments_count
FROM college.courses c
JOIN college.enrollments e ON c.course_id = e.course_id
GROUP BY c.course_id, c.code, c.title
HAVING COUNT(e.student_id) >= 2
ORDER BY enrollments_count DESC;
```
* **Очікуваний результат:**

| course_code | course_title | enrollments_count |
|---|---|---:|
| DB | Бази даних | 4 |
| WEB | Вебтехнології | 2 |
| PHY | Загальна фізика | 2 |

* **Пояснення:** Курси `AST` (0 реєстрацій) та `SEC` (0 реєстрацій) не проходять поріг `HAVING COUNT >= 2`.

---

### Завдання 2. Відмінність `WHERE` від `HAVING`

У реляційній моделі та конвеєрі виконання SQL-запиту:
$$\text{FROM} \longrightarrow \text{WHERE} \longrightarrow \text{GROUP BY} \longrightarrow \text{HAVING} \longrightarrow \text{SELECT} \longrightarrow \text{ORDER BY}$$

1. **`WHERE`** фільтрує *окремі кортежі (рядки)* до моменту їх об'єднання в групи. Не може містити агрегатних функцій.
2. **`HAVING`** фільтрує *сформовані групи* за значеннями агрегованих показників (`COUNT`, `AVG` тощо).

**Порівняльні запити:**
```sql
-- Спосіб А: HAVING (фільтрація за результатом агрегації)
SELECT course_id, COUNT(*) AS enrollments
FROM college.enrollments
GROUP BY course_id
HAVING COUNT(*) >= 2;
-- Результат: course_id 1 (4 записи), 2 (2 записи), 3 (2 записи).

-- Спосіб Б: WHERE (фільтрація атомарних рядків до групування)
SELECT course_id, COUNT(*) AS active_or_completed_count
FROM college.enrollments
WHERE status <> 'cancelled'
GROUP BY course_id;
-- Результат: для course_id 2 скасований запис Коваля вилучено ще ДО підрахунку; результат 1.

-- Поєднання способів:
SELECT course_id, COUNT(*) AS valid_enrollments
FROM college.enrollments
WHERE status IN ('active', 'completed')
GROUP BY course_id
HAVING COUNT(*) >= 2;
-- Результат: залишаються лише course_id 1 (3 записи) та course_id 3 (2 записи).
```

---

### Завдання 3. Операції над множинами

Розглянуто дві підмножини курсів:
* **Множина $A$** (курси кафедри IT: `department_id = 1`): `{'DB', 'WEB', 'SEC'}` ($|A| = 3$).
* **Множина $B$** (курси з кредитами $\le 3$): `{'WEB', 'AST'}` ($|B| = 2$).

| Операція | Синтаксис SQL | Результат (множина кодів) | Потужність ($|R|$) | Пояснення |
|---|---|---|:---:|---|
| **UNION** | `SELECT code FROM ... WHERE dep=1 UNION SELECT code ... credits<=3` | `{'AST', 'DB', 'SEC', 'WEB'}` | 4 | Об'єднання множин із вилученням повторів (`WEB` враховано один раз). |
| **UNION ALL** | `... UNION ALL ...` | `{'DB', 'SEC', 'WEB', 'AST', 'WEB'}` | 5 | Об'єднання мультимножин зі збереженням дублікатів (без сортування та deduplication). |
| **INTERSECT** | `... INTERSECT ...` | `{'WEB'}` | 1 | Перетин множин: курси, які одночасно належать кафедрі IT і мають $\le 3$ кредити. |
| **EXCEPT** | `... EXCEPT ...` | `{'DB', 'SEC'}` | 2 | Різниця множин ($A \setminus B$): курси IT, що мають суворо більше 3 кредитів. |

---

### Завдання 4. Прикладний звіт «Топ курсів за кількістю студентів»
```sql
SELECT c.course_id,
       c.code AS course_code,
       c.title AS course_title,
       d.name AS department_name,
       COUNT(e.student_id) AS total_students,
       COUNT(CASE WHEN e.status = 'completed' THEN 1 END) AS completed_students,
       ROUND(AVG(e.grade), 1) AS average_grade
FROM college.courses c
JOIN college.departments d ON c.department_id = d.department_id
LEFT JOIN college.enrollments e ON c.course_id = e.course_id
GROUP BY c.course_id, c.code, c.title, d.name
ORDER BY total_students DESC, average_grade DESC NULLS LAST;
```

* **Очікуваний результат:**

| course_id | course_code | course_title | department_name | total_students | completed_students | average_grade |
|---:|---|---|---|---:|---:|---:|
| 1 | DB | Бази даних | Інформаційні технології | 4 | 3 | 90.7 |
| 3 | PHY | Загальна фізика | Фізика | 2 | 2 | 69.0 |
| 2 | WEB | Вебтехнології | Інформаційні технології | 2 | 0 | NULL |
| 4 | AST | Астрономія | Фізика | 0 | 0 | NULL |
| 5 | SEC | Кібербезпека | Інформаційні технології | 0 | 0 | NULL |

---

## 4. Відповіді на питання для захисту

1. **Чому `WHERE` не можна використати для фільтрації після групування?**
   Згідно з логічним порядком обробки запиту (query execution order), предикати секції `WHERE` оцінюються для кожного рядка базових таблиць до формування груп. На етапі `WHERE` агреговані значення (суми, середні, кількості) ще фізично не існують. Для фільтрації результатів агрегатних функцій стандарт SQL вводить секцію `HAVING`.

2. **Що повертає `COUNT(*)` за відсутності рядків?**
   Якщо у вибірці немає жодного рядка (або якщо запит без `GROUP BY` застосовано до порожньої таблиці), `COUNT(*)` повертає ціле число `0` (на відміну від `AVG`, `SUM`, `MIN`, `MAX`, які для порожньої множини повертають `NULL`). Якщо застосовується `GROUP BY`, і жодна група не утворилася, запит повертає `0` рядків.

3. **У чому різниця між `UNION` і `UNION ALL`?**
   `UNION` об'єднує результати двох підзапитів як математичні множини і виконує додатковий етап дедуплікації (сортування або хешування), видаляючи дублікати рядків. `UNION ALL` об'єднує результати як мультимножини (bag semantics), зберігаючи всі рядки включно з дублікатами. `UNION ALL` працює суттєво швидше, оскільки не потребує додаткових витрат пам'яті та процесорного часу на усунення однакових значень.

4. **Як `NULL` впливає на агрегатні функції?**
   Усі стандартні агрегатні функції (`SUM`, `AVG`, `MIN`, `MAX`, `COUNT(стовпець)`) ігнорують значення `NULL` під час розрахунку. Наприклад, `AVG(grade)` розраховує середнє лише серед ненульових оцінок, ділячи суму на кількість непорожніх значень, а не на загальну кількість рядків. Винятком є `COUNT(*)`, який рахує фізичні рядки незалежно від вмісту їхніх стовпців.

---

## 5. Висновок
У ході практичної роботи було детально опрацьовано механізми агрегації даних, групування та багаторівневої фільтрації у PostgreSQL. Продемонстровано фундаментальну різницю між атомарною фільтрацією рядків (`WHERE`) та груповою фільтрацією (`HAVING`), досліджені операції теорії множин та побудовано комплексний звіт успішності курсів. Усі запити оформлено у файлі `aggregates.sql`.
