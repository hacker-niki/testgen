# Документация по базе данных TestGen

## Оглавление

1. [Общее описание](#общее-описание)
2. [Инфологическая модель](#инфологическая-модель)
3. [Даталогическая модель](#даталогическая-модель)
4. [Физическая модель](#физическая-модель)
5. [Триггеры и хранимые процедуры](#триггеры-и-хранимые-процедуры)
6. [Система аудита](#система-аудита)
7. [Примеры запросов](#примеры-запросов)

---

## Общее описание

База данных TestGen спроектирована для хранения данных системы автоматизированного тестирования с генерацией вопросов. Используется СУБД **MariaDB 11.2** с кодировкой **utf8mb4**.

### Основные возможности БД:

- Хранение пользователей с ролевой моделью доступа
- Управление группами пользователей
- Хранение исходных документов для генерации вопросов
- Пул вопросов с вариантами ответов
- Создание и управление тестами
- Назначение тестов пользователям и группам
- Отслеживание сессий тестирования и ответов
- Система аудита всех операций с данными
- Автоматические триггеры для обновления полей

---

## Инфологическая модель

### Основные сущности:

1. **Пользователь (User)** – зарегистрированный участник системы
2. **Роль (Role)** – определяет уровень доступа (admin, teacher, student)
3. **Группа (Group)** – объединение пользователей
4. **Исходный документ (Source Document)** – загруженный файл для генерации вопросов
5. **Вопрос (Question)** – единица контента для тестов
6. **Вариант ответа (Answer Option)** – возможный ответ на вопрос
7. **Тест (Test)** – набор вопросов для оценки знаний
8. **Назначение теста (Test Assignment)** – связь теста с пользователем/группой
9. **Сессия тестирования (Test Session)** – попытка прохождения теста
10. **Ответ пользователя (User Answer)** – выбранный ответ в рамках сессии

### Связи между сущностями:

- **User ↔ Role**: многие-ко-многим (через `user_roles`)
- **User ↔ Group**: многие-ко-многим (через `user_groups`)
- **Question ↔ Test**: многие-ко-многим (через `test_questions`)
- **SourceDocument → Question**: один-ко-многим
- **Question → AnswerOption**: один-ко-многим
- **Test → TestAssignment**: один-ко-многим
- **Test → TestSession**: один-ко-многим
- **TestSession → UserAnswer**: один-ко-многим

---

## Даталогическая модель

### Таблица: `roles`

| Поле          | Тип          | Ключ | Описание           |
|---------------|--------------|------|--------------------|
| id            | INT          | PK   | ID роли            |
| name          | VARCHAR(50)  | UQ   | Название роли      |
| description   | VARCHAR(255) |      | Описание роли      |
| created_at    | TIMESTAMP    |      | Время создания     |

### Таблица: `users`

| Поле           | Тип          | Ключ | Описание              |
|----------------|--------------|------|-----------------------|
| id             | BIGINT       | PK   | ID пользователя       |
| full_name      | VARCHAR(255) |      | Полное имя            |
| email          | VARCHAR(255) | UQ   | Email для входа       |
| password_hash  | VARCHAR(255) |      | Хэш пароля (bcrypt)   |
| is_active      | BOOLEAN      |      | Активен ли аккаунт    |
| created_at     | TIMESTAMP    |      | Время создания        |
| updated_at     | TIMESTAMP    |      | Время обновления      |

### Таблица: `user_roles`

| Поле        | Тип       | Ключ    | Описание        |
|-------------|-----------|---------|-----------------|
| id          | BIGINT    | PK      | ID связи        |
| user_id     | BIGINT    | FK      | ID пользователя |
| role_id     | INT       | FK      | ID роли         |
| assigned_at | TIMESTAMP |         | Время назначения|

### Таблица: `groups`

| Поле        | Тип          | Ключ | Описание           |
|-------------|--------------|------|--------------------|
| id          | BIGINT       | PK   | ID группы          |
| name        | VARCHAR(255) |      | Название группы    |
| description | TEXT         |      | Описание группы    |
| created_by  | BIGINT       | FK   | Кто создал группу  |
| created_at  | TIMESTAMP    |      | Время создания     |
| updated_at  | TIMESTAMP    |      | Время обновления   |

### Таблица: `user_groups`

| Поле      | Тип       | Ключ | Описание         |
|-----------|-----------|------|------------------|
| id        | BIGINT    | PK   | ID связи         |
| user_id   | BIGINT    | FK   | ID пользователя  |
| group_id  | BIGINT    | FK   | ID группы        |
| joined_at | TIMESTAMP |      | Время вступления |

### Таблица: `source_documents`

| Поле           | Тип          | Ключ | Описание                          |
|----------------|--------------|------|-----------------------------------|
| id             | BIGINT       | PK   | ID документа                      |
| filename       | VARCHAR(255) |      | Имя файла                         |
| file_path      | VARCHAR(500) |      | Путь к файлу                      |
| file_size      | BIGINT       |      | Размер файла в байтах             |
| mime_type      | VARCHAR(100) |      | MIME-тип файла                    |
| status         | ENUM         |      | Статус (pending/processing/...)   |
| error_message  | TEXT         |      | Сообщение об ошибке               |
| uploader_id    | BIGINT       | FK   | Кто загрузил                      |
| created_at     | TIMESTAMP    |      | Время загрузки                    |
| processed_at   | TIMESTAMP    |      | Время завершения обработки        |

### Таблица: `questions`

| Поле               | Тип       | Ключ | Описание                    |
|--------------------|-----------|------|-----------------------------|
| id                 | BIGINT    | PK   | ID вопроса                  |
| question_text      | TEXT      |      | Текст вопроса               |
| source_document_id | BIGINT    | FK   | Ссылка на документ          |
| creator_id         | BIGINT    | FK   | Кто создал                  |
| difficulty         | ENUM      |      | Сложность (easy/medium/hard)|
| is_approved        | BOOLEAN   |      | Одобрен ли вопрос           |
| approved_by        | BIGINT    | FK   | Кто одобрил                 |
| approved_at        | TIMESTAMP |      | Время одобрения             |
| created_at         | TIMESTAMP |      | Время создания              |
| updated_at         | TIMESTAMP |      | Время обновления            |

### Таблица: `answer_options`

| Поле         | Тип       | Ключ | Описание                    |
|--------------|-----------|------|-----------------------------|
| id           | BIGINT    | PK   | ID варианта ответа          |
| question_id  | BIGINT    | FK   | ID вопроса                  |
| answer_text  | TEXT      |      | Текст варианта ответа       |
| is_correct   | BOOLEAN   |      | Правильный ли ответ         |
| option_order | TINYINT   |      | Порядок отображения (1-5)   |
| created_at   | TIMESTAMP |      | Время создания              |

### Таблица: `tests`

| Поле                  | Тип           | Ключ | Описание                      |
|-----------------------|---------------|------|-------------------------------|
| id                    | BIGINT        | PK   | ID теста                      |
| title                 | VARCHAR(255)  |      | Название теста                |
| description           | TEXT          |      | Описание теста                |
| time_limit_minutes    | INT           |      | Ограничение по времени        |
| passing_score         | DECIMAL(5,2)  |      | Проходной балл (%)            |
| max_attempts          | INT           |      | Макс. количество попыток      |
| shuffle_questions     | BOOLEAN       |      | Перемешивать вопросы          |
| shuffle_answers       | BOOLEAN       |      | Перемешивать ответы           |
| show_results          | BOOLEAN       |      | Показывать результаты         |
| show_correct_answers  | BOOLEAN       |      | Показывать правильные ответы  |
| is_active             | BOOLEAN       |      | Активен ли тест               |
| creator_id            | BIGINT        | FK   | Кто создал тест               |
| created_at            | TIMESTAMP     |      | Время создания                |
| updated_at            | TIMESTAMP     |      | Время обновления              |

### Таблица: `test_questions`

| Поле           | Тип           | Ключ | Описание             |
|----------------|---------------|------|----------------------|
| id             | BIGINT        | PK   | ID связи             |
| test_id        | BIGINT        | FK   | ID теста             |
| question_id    | BIGINT        | FK   | ID вопроса           |
| question_order | INT           |      | Порядок в тесте      |
| points         | DECIMAL(5,2)  |      | Баллы за ответ       |

### Таблица: `test_assignments`

| Поле         | Тип       | Ключ | Описание                |
|--------------|-----------|------|-------------------------|
| id           | BIGINT    | PK   | ID назначения           |
| test_id      | BIGINT    | FK   | ID теста                |
| user_id      | BIGINT    | FK   | ID пользователя (NULL)  |
| group_id     | BIGINT    | FK   | ID группы (NULL)        |
| assigned_by  | BIGINT    | FK   | Кто назначил            |
| assigned_at  | TIMESTAMP |      | Время назначения        |
| deadline     | TIMESTAMP |      | Крайний срок            |
| is_completed | BOOLEAN   |      | Завершено ли            |

### Таблица: `test_sessions`

| Поле               | Тип           | Ключ | Описание                    |
|--------------------|---------------|------|-----------------------------|
| id                 | BIGINT        | PK   | ID сессии                   |
| test_id            | BIGINT        | FK   | ID теста                    |
| user_id            | BIGINT        | FK   | ID пользователя             |
| assignment_id      | BIGINT        | FK   | ID назначения               |
| status             | ENUM          |      | Статус сессии               |
| started_at         | TIMESTAMP     |      | Время начала                |
| completed_at       | TIMESTAMP     |      | Время завершения            |
| time_spent_seconds | INT           |      | Время прохождения (сек)     |
| score              | DECIMAL(5,2)  |      | Балл (%)                    |
| total_questions    | INT           |      | Всего вопросов              |
| correct_answers    | INT           |      | Правильных ответов          |
| is_passed          | BOOLEAN       |      | Пройден ли тест             |

### Таблица: `user_answers`

| Поле              | Тип       | Ключ | Описание              |
|-------------------|-----------|------|-----------------------|
| id                | BIGINT    | PK   | ID ответа             |
| test_session_id   | BIGINT    | FK   | ID сессии             |
| question_id       | BIGINT    | FK   | ID вопроса            |
| selected_option_id| BIGINT    | FK   | ID выбранного ответа  |
| is_correct        | BOOLEAN   |      | Правильный ли ответ   |
| answered_at       | TIMESTAMP |      | Время ответа          |

### Таблица: `audit_log`

| Поле           | Тип       | Ключ | Описание              |
|----------------|-----------|------|-----------------------|
| id             | BIGINT    | PK   | ID записи аудита      |
| table_name     | VARCHAR   |      | Название таблицы      |
| operation_type | ENUM      |      | Тип операции          |
| record_id      | BIGINT    |      | ID записи             |
| old_values     | JSON      |      | Старые значения       |
| new_values     | JSON      |      | Новые значения        |
| user_id        | BIGINT    | FK   | ID пользователя       |
| changed_at     | TIMESTAMP |      | Время изменения       |

---

## Физическая модель

### Индексы

Для оптимизации производительности созданы следующие индексы:

- **users**: `idx_email`, `idx_is_active`
- **user_roles**: `idx_user_id`, `idx_role_id`, `unique_user_role`
- **groups**: `idx_name`, `idx_created_by`
- **user_groups**: `idx_user_id`, `idx_group_id`, `unique_user_group`
- **source_documents**: `idx_status`, `idx_uploader_id`, `idx_created_at`
- **questions**: `idx_source_document_id`, `idx_creator_id`, `idx_is_approved`, `idx_difficulty`
- **answer_options**: `idx_question_id`, `idx_is_correct`
- **tests**: `idx_is_active`, `idx_creator_id`, `idx_created_at`
- **test_questions**: `idx_test_id`, `idx_question_id`, `unique_test_question`
- **test_assignments**: `idx_test_id`, `idx_user_id`, `idx_group_id`, `idx_deadline`
- **test_sessions**: `idx_test_id`, `idx_user_id`, `idx_status`, `idx_started_at`
- **user_answers**: `idx_test_session_id`, `idx_question_id`, `idx_selected_option_id`, `unique_session_question`
- **audit_log**: `idx_table_record`, `idx_operation_date`, `idx_user`

### Внешние ключи

Все связи реализованы через внешние ключи с соответствующими правилами:

- `ON DELETE CASCADE` – каскадное удаление связанных записей
- `ON DELETE SET NULL` – установка NULL при удалении родительской записи

---

## Триггеры и хранимые процедуры

### Триггеры

#### 1. Автоматическое одобрение вопросов

```sql
CREATE TRIGGER trg_questions_approve
BEFORE UPDATE ON questions
FOR EACH ROW
BEGIN
    IF NEW.is_approved = TRUE AND OLD.is_approved = FALSE THEN
        SET NEW.approved_at = NOW();
    END IF;
END;
```

#### 2. Расчет результатов при завершении сессии

```sql
CREATE TRIGGER trg_test_sessions_complete
BEFORE UPDATE ON test_sessions
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status = 'in_progress' THEN
        SET NEW.completed_at = NOW();
        SET NEW.time_spent_seconds = TIMESTAMPDIFF(SECOND, NEW.started_at, NOW());
        IF NEW.total_questions > 0 THEN
            SET NEW.score = (NEW.correct_answers / NEW.total_questions) * 100;
        END IF;
        SET NEW.is_passed = (NEW.score >= (SELECT passing_score FROM tests WHERE id = NEW.test_id));
    END IF;
END;
```

### Хранимые процедуры

#### 1. Получение тестов, назначенных пользователю

```sql
CALL sp_get_user_assigned_tests(user_id);
```

Возвращает список тестов, назначенных конкретному пользователю или его группам.

#### 2. Получение вопросов теста с вариантами ответов

```sql
CALL sp_get_test_questions(test_id);
```

Возвращает все вопросы теста с вариантами ответов, упорядоченные по порядку.

#### 3. Подсчет результатов теста

```sql
CALL sp_calculate_test_score(session_id, @score, @correct_count, @is_passed);
```

Подсчитывает итоговый балл и обновляет сессию тестирования.

#### 4. Статистика по пользователю

```sql
CALL sp_get_user_statistics(user_id);
```

Возвращает статистику прохождения тестов пользователем.

---

## Система аудита

Система аудита автоматически отслеживает все изменения в ключевых таблицах:

- `users`
- `tests`
- `test_sessions`

### Триггеры аудита

Для каждой таблицы созданы триггеры:

- `audit_[table]_insert` – отслеживает добавление записей
- `audit_[table]_update` – отслеживает изменение записей
- `audit_[table]_delete` – отслеживает удаление записей

### Пример записи аудита

```json
{
  "table_name": "users",
  "operation_type": "UPDATE",
  "record_id": 1,
  "old_values": {"email": "old@example.com", "is_active": true},
  "new_values": {"email": "new@example.com", "is_active": true},
  "user_id": 1,
  "changed_at": "2025-11-27 10:30:00"
}
```

---

## Примеры запросов

### 1. Получение всех одобренных вопросов

```sql
SELECT
    q.id,
    q.question_text,
    q.difficulty
FROM questions q
WHERE q.is_approved = TRUE
ORDER BY q.created_at DESC;
```

### 2. Получение вопросов теста с вариантами ответов

```sql
SELECT
    q.id as question_id,
    q.question_text,
    ao.id as option_id,
    ao.answer_text,
    ao.is_correct
FROM test_questions tq
JOIN questions q ON tq.question_id = q.id
JOIN answer_options ao ON q.id = ao.question_id
WHERE tq.test_id = 1
ORDER BY tq.question_order, ao.option_order;
```

### 3. Получение статистики пользователя

```sql
SELECT
    u.full_name,
    COUNT(DISTINCT ts.id) as total_sessions,
    COUNT(CASE WHEN ts.is_passed = TRUE THEN 1 END) as passed_tests,
    AVG(ts.score) as average_score
FROM users u
LEFT JOIN test_sessions ts ON u.id = ts.user_id
WHERE u.id = 1
GROUP BY u.id, u.full_name;
```

### 4. Получение тестов, назначенных пользователю

```sql
SELECT DISTINCT
    t.id,
    t.title,
    ta.deadline
FROM tests t
JOIN test_assignments ta ON t.id = ta.test_id
WHERE (ta.user_id = 1 OR ta.group_id IN (SELECT group_id FROM user_groups WHERE user_id = 1))
  AND t.is_active = TRUE
ORDER BY ta.deadline ASC;
```

### 5. Подсчет результатов сессии

```sql
UPDATE test_sessions ts
SET
    score = (SELECT (COUNT(CASE WHEN ua.is_correct = TRUE THEN 1 END) / COUNT(*)) * 100
             FROM user_answers ua
             WHERE ua.test_session_id = ts.id),
    correct_answers = (SELECT COUNT(*)
                       FROM user_answers ua
                       WHERE ua.test_session_id = ts.id AND ua.is_correct = TRUE),
    status = 'completed',
    completed_at = NOW()
WHERE ts.id = 1;
```

### 6. Аудит изменений конкретной записи

```sql
SELECT
    al.changed_at,
    al.operation_type,
    al.old_values,
    al.new_values,
    u.email as changed_by
FROM audit_log al
LEFT JOIN users u ON al.user_id = u.id
WHERE al.table_name = 'tests' AND al.record_id = 1
ORDER BY al.changed_at DESC;
```

---

## Демонстрационные данные

В базу данных загружены тестовые данные:

- **4 пользователя**: 1 admin, 1 teacher, 2 students (пароль для всех: `admin123`)
- **3 роли**: admin, teacher, student
- **2 группы**: ПИ-21, ИСТ-22
- **2 документа**: Основы SQL (обработан), Реляционные СУБД (в обработке)
- **10 вопросов** по SQL с вариантами ответов
- **1 тест** «Основы SQL» с 10 вопросами
- **Назначения тестов** студентам с дедлайнами

---

## Контакты и поддержка

Для вопросов по структуре БД обращайтесь к администратору системы.
