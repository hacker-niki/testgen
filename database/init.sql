-- =====================================================
-- Создание базы данных для системы TestGen
-- Система автоматизированного тестирования с генерацией вопросов
-- =====================================================

CREATE DATABASE IF NOT EXISTS testgen CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE testgen;

-- =====================================================
-- ОСНОВНЫЕ ТАБЛИЦЫ
-- =====================================================

-- Таблица ролей
CREATE TABLE IF NOT EXISTS `roles` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Название роли (admin, teacher, student)',
    `description` VARCHAR(255) DEFAULT NULL COMMENT 'Описание роли',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_name` (`name`)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Справочник ролей пользователей';

-- Таблица пользователей
CREATE TABLE IF NOT EXISTS `users` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `full_name` VARCHAR(255) NOT NULL COMMENT 'Полное имя пользователя',
    `email` VARCHAR(255) NOT NULL UNIQUE COMMENT 'Email для входа',
    `password_hash` VARCHAR(255) NOT NULL COMMENT 'Хэш пароля (bcrypt)',
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Активен ли аккаунт',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_email` (`email`),
    INDEX `idx_is_active` (`is_active`)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Пользователи системы';

-- Связь пользователей и ролей (многие ко многим)
CREATE TABLE IF NOT EXISTS `user_roles` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `role_id` INT UNSIGNED NOT NULL,
    `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_user_role` (`user_id`, `role_id`),
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_role_id` (`role_id`),
    CONSTRAINT `fk_user_roles_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_user_roles_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Связь пользователей и ролей';

-- Таблица групп
CREATE TABLE IF NOT EXISTS `groups` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL COMMENT 'Название группы/отдела',
    `description` TEXT DEFAULT NULL COMMENT 'Описание группы',
    `created_by` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Кто создал группу',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_name` (`name`),
    INDEX `idx_created_by` (`created_by`),
    CONSTRAINT `fk_groups_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Группы пользователей';

-- Связь пользователей и групп (многие ко многим)
CREATE TABLE IF NOT EXISTS `user_groups` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `group_id` BIGINT UNSIGNED NOT NULL,
    `joined_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_user_group` (`user_id`, `group_id`),
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_group_id` (`group_id`),
    CONSTRAINT `fk_user_groups_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_user_groups_group` FOREIGN KEY (`group_id`) REFERENCES `groups` (`id`) ON DELETE CASCADE
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Связь пользователей и групп';

-- Таблица исходных документов
CREATE TABLE IF NOT EXISTS `source_documents` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `filename` VARCHAR(255) NOT NULL COMMENT 'Оригинальное имя файла',
    `file_path` VARCHAR(500) DEFAULT NULL COMMENT 'Путь к файлу на сервере',
    `file_size` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Размер файла в байтах',
    `mime_type` VARCHAR(100) DEFAULT NULL COMMENT 'MIME-тип файла',
    `status` ENUM('pending', 'processing', 'completed', 'failed') NOT NULL DEFAULT 'pending' COMMENT 'Статус обработки',
    `error_message` TEXT DEFAULT NULL COMMENT 'Сообщение об ошибке при обработке',
    `uploader_id` BIGINT UNSIGNED NOT NULL COMMENT 'Кто загрузил документ',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `processed_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Время завершения обработки',
    PRIMARY KEY (`id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_uploader_id` (`uploader_id`),
    INDEX `idx_created_at` (`created_at`),
    CONSTRAINT `fk_source_documents_uploader` FOREIGN KEY (`uploader_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Исходные документы для генерации вопросов';

-- Таблица вопросов
CREATE TABLE IF NOT EXISTS `questions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `question_text` TEXT NOT NULL COMMENT 'Текст вопроса',
    `source_document_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Ссылка на документ (NULL для ручного создания)',
    `creator_id` BIGINT UNSIGNED NOT NULL COMMENT 'Кто создал/инициировал генерацию вопроса',
    `is_approved` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Одобрен ли вопрос',
    `approved_by` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Кто одобрил вопрос',
    `approved_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'Когда одобрен',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_source_document_id` (`source_document_id`),
    INDEX `idx_creator_id` (`creator_id`),
    INDEX `idx_is_approved` (`is_approved`),
    CONSTRAINT `fk_question_document` FOREIGN KEY (`source_document_id`) REFERENCES `source_documents` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_question_creator` FOREIGN KEY (`creator_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_question_approver` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Пул вопросов для тестов';

-- Таблица вариантов ответов
CREATE TABLE IF NOT EXISTS `answer_options` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `question_id` BIGINT UNSIGNED NOT NULL COMMENT 'Вопрос, к которому относится ответ',
    `answer_text` TEXT NOT NULL COMMENT 'Текст варианта ответа',
    `is_correct` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Является ли ответ правильным',
    `option_order` TINYINT UNSIGNED NOT NULL COMMENT 'Порядок отображения (1-5)',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_question_id` (`question_id`),
    INDEX `idx_is_correct` (`is_correct`),
    CONSTRAINT `fk_answer_option_question` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Варианты ответов на вопросы';

-- Таблица тестов
CREATE TABLE IF NOT EXISTS `tests` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(255) NOT NULL COMMENT 'Название теста',
    `description` TEXT DEFAULT NULL COMMENT 'Описание теста',
    `time_limit_minutes` INT UNSIGNED DEFAULT NULL COMMENT 'Ограничение по времени в минутах',
    `passing_score` DECIMAL(5,2) NOT NULL DEFAULT 70.00 COMMENT 'Проходной балл в процентах',
    `max_attempts` INT UNSIGNED DEFAULT NULL COMMENT 'Максимальное количество попыток (NULL = без ограничений)',
    `shuffle_questions` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Перемешивать вопросы',
    `shuffle_answers` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Перемешивать варианты ответов',
    `show_results` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Показывать результаты сразу',
    `show_correct_answers` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Показывать правильные ответы',
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Активен ли тест',
    `creator_id` BIGINT UNSIGNED NOT NULL COMMENT 'Кто создал тест',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_is_active` (`is_active`),
    INDEX `idx_creator_id` (`creator_id`),
    INDEX `idx_created_at` (`created_at`),
    CONSTRAINT `fk_tests_creator` FOREIGN KEY (`creator_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Тесты';

-- Связь тестов и вопросов (многие ко многим)
CREATE TABLE IF NOT EXISTS `test_questions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `test_id` BIGINT UNSIGNED NOT NULL,
    `question_id` BIGINT UNSIGNED NOT NULL,
    `question_order` INT UNSIGNED NOT NULL COMMENT 'Порядок вопроса в тесте',
    `points` DECIMAL(5,2) NOT NULL DEFAULT 1.00 COMMENT 'Баллы за правильный ответ',
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_test_question` (`test_id`, `question_id`),
    INDEX `idx_test_id` (`test_id`),
    INDEX `idx_question_id` (`question_id`),
    CONSTRAINT `fk_test_questions_test` FOREIGN KEY (`test_id`) REFERENCES `tests` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_test_questions_question` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Связь тестов и вопросов';

-- Таблица назначений тестов
CREATE TABLE IF NOT EXISTS `test_assignments` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `test_id` BIGINT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Назначение конкретному пользователю',
    `group_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Назначение группе',
    `assigned_by` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Кто назначил тест',
    `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `deadline` TIMESTAMP NULL DEFAULT NULL COMMENT 'Крайний срок прохождения',
    `is_completed` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Завершено ли назначение',
    PRIMARY KEY (`id`),
    INDEX `idx_test_id` (`test_id`),
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_group_id` (`group_id`),
    INDEX `idx_deadline` (`deadline`),
    CONSTRAINT `fk_test_assignments_test` FOREIGN KEY (`test_id`) REFERENCES `tests` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_test_assignments_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_test_assignments_group` FOREIGN KEY (`group_id`) REFERENCES `groups` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_test_assignments_assigner` FOREIGN KEY (`assigned_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `chk_assignment_target` CHECK ((`user_id` IS NOT NULL) OR (`group_id` IS NOT NULL))
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Назначение тестов пользователям или группам';

-- Таблица сессий тестирования
CREATE TABLE IF NOT EXISTS `test_sessions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `test_id` BIGINT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `assignment_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Связь с назначением теста',
    `status` ENUM('in_progress', 'completed', 'abandoned') NOT NULL DEFAULT 'in_progress',
    `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `completed_at` TIMESTAMP NULL DEFAULT NULL,
    `time_spent_seconds` INT UNSIGNED DEFAULT NULL COMMENT 'Время прохождения в секундах',
    `score` DECIMAL(5,2) DEFAULT NULL COMMENT 'Итоговый балл в процентах',
    `total_questions` INT UNSIGNED NOT NULL COMMENT 'Общее количество вопросов',
    `correct_answers` INT UNSIGNED DEFAULT 0 COMMENT 'Количество правильных ответов',
    `is_passed` BOOLEAN DEFAULT NULL COMMENT 'Пройден ли тест',
    PRIMARY KEY (`id`),
    INDEX `idx_test_id` (`test_id`),
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_started_at` (`started_at`),
    CONSTRAINT `fk_test_sessions_test` FOREIGN KEY (`test_id`) REFERENCES `tests` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_test_sessions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_test_sessions_assignment` FOREIGN KEY (`assignment_id`) REFERENCES `test_assignments` (`id`) ON DELETE SET NULL
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Сессии прохождения тестов';

-- Таблица ответов пользователей
CREATE TABLE IF NOT EXISTS `user_answers` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `test_session_id` BIGINT UNSIGNED NOT NULL COMMENT 'Сессия тестирования',
    `question_id` BIGINT UNSIGNED NOT NULL COMMENT 'Вопрос',
    `selected_option_id` BIGINT UNSIGNED NOT NULL COMMENT 'Выбранный вариант ответа',
    `is_correct` BOOLEAN NOT NULL COMMENT 'Правильный ли ответ',
    `answered_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_session_question` (`test_session_id`, `question_id`),
    INDEX `idx_test_session_id` (`test_session_id`),
    INDEX `idx_question_id` (`question_id`),
    INDEX `idx_selected_option_id` (`selected_option_id`),
    CONSTRAINT `fk_user_answers_session` FOREIGN KEY (`test_session_id`) REFERENCES `test_sessions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_user_answers_question` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_user_answers_option` FOREIGN KEY (`selected_option_id`) REFERENCES `answer_options` (`id`) ON DELETE CASCADE
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Ответы пользователей на вопросы в рамках сессий';

-- =====================================================
-- СИСТЕМА АУДИТА
-- =====================================================

-- Таблица журнала аудита
CREATE TABLE IF NOT EXISTS `audit_log` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `table_name` VARCHAR(64) NOT NULL COMMENT 'Название таблицы',
    `operation_type` ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL COMMENT 'Тип операции',
    `record_id` BIGINT UNSIGNED NOT NULL COMMENT 'ID измененной записи',
    `old_values` JSON DEFAULT NULL COMMENT 'Старые значения (для UPDATE и DELETE)',
    `new_values` JSON DEFAULT NULL COMMENT 'Новые значения (для INSERT и UPDATE)',
    `user_id` BIGINT UNSIGNED DEFAULT NULL COMMENT 'Пользователь, выполнивший операцию',
    `changed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Время изменения',
    PRIMARY KEY (`id`),
    INDEX `idx_table_record` (`table_name`, `record_id`),
    INDEX `idx_operation_date` (`operation_type`, `changed_at`),
    INDEX `idx_user` (`user_id`),
    CONSTRAINT `fk_audit_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Журнал аудита всех операций с данными';

-- =====================================================
-- ТРИГГЕРЫ ДЛЯ АВТОМАТИЗАЦИИ
-- =====================================================

DELIMITER //

-- Триггер для автоматического обновления времени одобрения вопроса
CREATE TRIGGER `trg_questions_approve`
BEFORE UPDATE ON `questions`
FOR EACH ROW
BEGIN
    IF NEW.is_approved = TRUE AND OLD.is_approved = FALSE THEN
        SET NEW.approved_at = NOW();
    END IF;
END//

-- Триггер для расчета результатов при завершении сессии
CREATE TRIGGER `trg_test_sessions_complete`
BEFORE UPDATE ON `test_sessions`
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status = 'in_progress' THEN
        SET NEW.completed_at = NOW();
        SET NEW.time_spent_seconds = TIMESTAMPDIFF(SECOND, NEW.started_at, NOW());

        -- Расчет балла
        IF NEW.total_questions > 0 THEN
            SET NEW.score = (NEW.correct_answers / NEW.total_questions) * 100;
        END IF;

        -- Определение, пройден ли тест
        SET NEW.is_passed = (NEW.score >= (SELECT passing_score FROM tests WHERE id = NEW.test_id));
    END IF;
END//

DELIMITER ;

-- =====================================================
-- ТРИГГЕРЫ АУДИТА
-- =====================================================

DELIMITER //

-- Аудит INSERT для users
CREATE TRIGGER `audit_users_insert`
AFTER INSERT ON `users`
FOR EACH ROW
BEGIN
    INSERT INTO `audit_log` (
        `table_name`,
        `operation_type`,
        `record_id`,
        `new_values`,
        `user_id`
    ) VALUES (
        'users',
        'INSERT',
        NEW.id,
        JSON_OBJECT(
            'email', NEW.email,
            'full_name', NEW.full_name,
            'is_active', NEW.is_active
        ),
        NEW.id
    );
END//

-- Аудит UPDATE для users
CREATE TRIGGER `audit_users_update`
AFTER UPDATE ON `users`
FOR EACH ROW
BEGIN
    INSERT INTO `audit_log` (
        `table_name`,
        `operation_type`,
        `record_id`,
        `old_values`,
        `new_values`,
        `user_id`
    ) VALUES (
        'users',
        'UPDATE',
        NEW.id,
        JSON_OBJECT(
            'email', OLD.email,
            'full_name', OLD.full_name,
            'is_active', OLD.is_active
        ),
        JSON_OBJECT(
            'email', NEW.email,
            'full_name', NEW.full_name,
            'is_active', NEW.is_active
        ),
        NEW.id
    );
END//

-- Аудит DELETE для users
CREATE TRIGGER `audit_users_delete`
AFTER DELETE ON `users`
FOR EACH ROW
BEGIN
    INSERT INTO `audit_log` (
        `table_name`,
        `operation_type`,
        `record_id`,
        `old_values`
    ) VALUES (
        'users',
        'DELETE',
        OLD.id,
        JSON_OBJECT(
            'email', OLD.email,
            'full_name', OLD.full_name,
            'is_active', OLD.is_active
        )
    );
END//

-- Аудит для tests
CREATE TRIGGER `audit_tests_insert`
AFTER INSERT ON `tests`
FOR EACH ROW
BEGIN
    INSERT INTO `audit_log` (
        `table_name`,
        `operation_type`,
        `record_id`,
        `new_values`,
        `user_id`
    ) VALUES (
        'tests',
        'INSERT',
        NEW.id,
        JSON_OBJECT(
            'title', NEW.title,
            'description', NEW.description,
            'time_limit_minutes', NEW.time_limit_minutes,
            'passing_score', NEW.passing_score,
            'is_active', NEW.is_active
        ),
        NEW.creator_id
    );
END//

CREATE TRIGGER `audit_tests_update`
AFTER UPDATE ON `tests`
FOR EACH ROW
BEGIN
    INSERT INTO `audit_log` (
        `table_name`,
        `operation_type`,
        `record_id`,
        `old_values`,
        `new_values`,
        `user_id`
    ) VALUES (
        'tests',
        'UPDATE',
        NEW.id,
        JSON_OBJECT(
            'title', OLD.title,
            'description', OLD.description,
            'time_limit_minutes', OLD.time_limit_minutes,
            'passing_score', OLD.passing_score,
            'is_active', OLD.is_active
        ),
        JSON_OBJECT(
            'title', NEW.title,
            'description', NEW.description,
            'time_limit_minutes', NEW.time_limit_minutes,
            'passing_score', NEW.passing_score,
            'is_active', NEW.is_active
        ),
        NEW.creator_id
    );
END//

CREATE TRIGGER `audit_tests_delete`
AFTER DELETE ON `tests`
FOR EACH ROW
BEGIN
    INSERT INTO `audit_log` (
        `table_name`,
        `operation_type`,
        `record_id`,
        `old_values`,
        `user_id`
    ) VALUES (
        'tests',
        'DELETE',
        OLD.id,
        JSON_OBJECT(
            'title', OLD.title,
            'description', OLD.description,
            'time_limit_minutes', OLD.time_limit_minutes,
            'passing_score', OLD.passing_score,
            'is_active', OLD.is_active
        ),
        OLD.creator_id
    );
END//

-- Аудит для test_sessions
CREATE TRIGGER `audit_test_sessions_insert`
AFTER INSERT ON `test_sessions`
FOR EACH ROW
BEGIN
    INSERT INTO `audit_log` (
        `table_name`,
        `operation_type`,
        `record_id`,
        `new_values`,
        `user_id`
    ) VALUES (
        'test_sessions',
        'INSERT',
        NEW.id,
        JSON_OBJECT(
            'test_id', NEW.test_id,
            'user_id', NEW.user_id,
            'status', NEW.status,
            'started_at', NEW.started_at
        ),
        NEW.user_id
    );
END//

CREATE TRIGGER `audit_test_sessions_update`
AFTER UPDATE ON `test_sessions`
FOR EACH ROW
BEGIN
    INSERT INTO `audit_log` (
        `table_name`,
        `operation_type`,
        `record_id`,
        `old_values`,
        `new_values`,
        `user_id`
    ) VALUES (
        'test_sessions',
        'UPDATE',
        NEW.id,
        JSON_OBJECT(
            'status', OLD.status,
            'score', OLD.score,
            'correct_answers', OLD.correct_answers,
            'is_passed', OLD.is_passed
        ),
        JSON_OBJECT(
            'status', NEW.status,
            'score', NEW.score,
            'correct_answers', NEW.correct_answers,
            'is_passed', NEW.is_passed
        ),
        NEW.user_id
    );
END//

DELIMITER ;

-- =====================================================
-- ХРАНИМЫЕ ПРОЦЕДУРЫ
-- =====================================================

DELIMITER //

-- Процедура для получения списка тестов, назначенных пользователю
CREATE PROCEDURE `sp_get_user_assigned_tests`(
    IN p_user_id BIGINT UNSIGNED
)
BEGIN
    SELECT DISTINCT
        t.id,
        t.title,
        t.description,
        t.time_limit_minutes,
        t.passing_score,
        ta.deadline,
        ta.is_completed,
        COUNT(DISTINCT tq.question_id) as questions_count
    FROM tests t
    INNER JOIN test_assignments ta ON t.id = ta.test_id
    LEFT JOIN test_questions tq ON t.id = tq.test_id
    WHERE (ta.user_id = p_user_id
           OR ta.group_id IN (SELECT group_id FROM user_groups WHERE user_id = p_user_id))
      AND t.is_active = TRUE
    GROUP BY t.id, t.title, t.description, t.time_limit_minutes, t.passing_score, ta.deadline, ta.is_completed
    ORDER BY ta.deadline ASC;
END//

-- Процедура для получения вопросов теста с вариантами ответов
CREATE PROCEDURE `sp_get_test_questions`(
    IN p_test_id BIGINT UNSIGNED
)
BEGIN
    SELECT
        q.id as question_id,
        q.question_text,
        q.difficulty,
        tq.points,
        tq.question_order,
        ao.id as option_id,
        ao.answer_text,
        ao.option_order
    FROM test_questions tq
    INNER JOIN questions q ON tq.question_id = q.id
    INNER JOIN answer_options ao ON q.id = ao.question_id
    WHERE tq.test_id = p_test_id
    ORDER BY tq.question_order, ao.option_order;
END//

-- Процедура для подсчета результатов теста
CREATE PROCEDURE `sp_calculate_test_score`(
    IN p_session_id BIGINT UNSIGNED,
    OUT p_score DECIMAL(5,2),
    OUT p_correct_count INT,
    OUT p_is_passed BOOLEAN
)
BEGIN
    DECLARE v_total_questions INT;
    DECLARE v_passing_score DECIMAL(5,2);

    -- Подсчет правильных ответов
    SELECT COUNT(*)
    INTO v_total_questions
    FROM user_answers
    WHERE test_session_id = p_session_id;

    SELECT COUNT(*)
    INTO p_correct_count
    FROM user_answers
    WHERE test_session_id = p_session_id AND is_correct = TRUE;

    -- Расчет балла
    IF v_total_questions > 0 THEN
        SET p_score = (p_correct_count / v_total_questions) * 100;
    ELSE
        SET p_score = 0;
    END IF;

    -- Получение проходного балла
    SELECT t.passing_score
    INTO v_passing_score
    FROM test_sessions ts
    INNER JOIN tests t ON ts.test_id = t.id
    WHERE ts.id = p_session_id;

    -- Определение, пройден ли тест
    SET p_is_passed = (p_score >= v_passing_score);

    -- Обновление сессии
    UPDATE test_sessions
    SET
        score = p_score,
        correct_answers = p_correct_count,
        is_passed = p_is_passed,
        status = 'completed',
        completed_at = NOW(),
        time_spent_seconds = TIMESTAMPDIFF(SECOND, started_at, NOW())
    WHERE id = p_session_id;
END//

-- Процедура для получения статистики по пользователю
CREATE PROCEDURE `sp_get_user_statistics`(
    IN p_user_id BIGINT UNSIGNED
)
BEGIN
    SELECT
        COUNT(DISTINCT ts.id) as total_sessions,
        COUNT(DISTINCT CASE WHEN ts.status = 'completed' THEN ts.id END) as completed_sessions,
        AVG(CASE WHEN ts.status = 'completed' THEN ts.score END) as average_score,
        COUNT(CASE WHEN ts.is_passed = TRUE THEN 1 END) as passed_tests,
        COUNT(CASE WHEN ts.is_passed = FALSE THEN 1 END) as failed_tests
    FROM test_sessions ts
    WHERE ts.user_id = p_user_id;
END//

DELIMITER ;

-- =====================================================
-- ДЕМОНСТРАЦИОННЫЕ ДАННЫЕ
-- =====================================================

-- Вставка ролей
INSERT INTO `roles` (`name`, `description`) VALUES
('admin', 'Администратор системы с полным доступом'),
('teacher', 'Преподаватель, создает и назначает тесты'),
('student', 'Студент, проходит тесты');

-- Вставка пользователей (пароль для всех: admin123)
-- Хэш: $2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYdU4O3qxfq
INSERT INTO `users` (`full_name`, `email`, `password_hash`, `is_active`) VALUES
('Администратор Системы', 'admin@testgen.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYdU4O3qxfq', TRUE),
('Преподаватель Иванов И.И.', 'teacher@testgen.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYdU4O3qxfq', TRUE),
('Студент Петров П.П.', 'student1@testgen.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYdU4O3qxfq', TRUE),
('Студент Сидоров С.С.', 'student2@testgen.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYdU4O3qxfq', TRUE);

-- Назначение ролей пользователям
INSERT INTO `user_roles` (`user_id`, `role_id`) VALUES
(1, 1), -- admin
(2, 2), -- teacher
(3, 3), -- student
(4, 3); -- student

-- Создание групп
INSERT INTO `groups` (`name`, `description`, `created_by`) VALUES
('Группа ПИ-21', 'Студенты группы ПИ-21', 1),
('Группа ИСТ-22', 'Студенты группы ИСТ-22', 1);

-- Добавление студентов в группы
INSERT INTO `user_groups` (`user_id`, `group_id`) VALUES
(3, 1),
(4, 1);

-- Загрузка документов
INSERT INTO `source_documents` (`filename`, `file_path`, `file_size`, `mime_type`, `status`, `uploader_id`, `processed_at`) VALUES
('Основы SQL.pdf', '/uploads/sql_basics.pdf', 1024000, 'application/pdf', 'completed', 1, NOW()),
('Реляционные СУБД.docx', '/uploads/relational_db.docx', 512000, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'processing', 1, NULL);

-- Создание вопросов
INSERT INTO `questions` (`question_text`, `source_document_id`, `creator_id`, `is_approved`, `approved_by`, `approved_at`) VALUES
('Какая SQL-команда используется для добавления новой записи в таблицу?', 1, 1, TRUE, 1, NOW()),
('Что такое первичный ключ (PRIMARY KEY) в базе данных?', 1, 1, TRUE, 1, NOW()),
('Какая команда используется для изменения структуры существующей таблицы?', 1, 1, TRUE, 1, NOW()),
('Что означает JOIN в SQL?', 1, 1, TRUE, 1, NOW()),
('Какой тип данных используется для хранения текста переменной длины в SQL?', 1, 1, TRUE, 1, NOW()),
('Что делает команда GROUP BY в SQL?', 1, 1, TRUE, 1, NOW()),
('Какая функция в SQL используется для подсчета количества строк?', 1, 1, TRUE, 1, NOW()),
('Что означает FOREIGN KEY в базе данных?', 1, 1, TRUE, 1, NOW()),
('Какая команда используется для удаления всех данных из таблицы?', 1, 1, TRUE, 1, NOW()),
('Что такое индекс в базе данных?', 1, 1, TRUE, 1, NOW());

-- Варианты ответов для вопроса 1
INSERT INTO `answer_options` (`question_id`, `answer_text`, `is_correct`, `option_order`) VALUES
(1, 'SELECT', FALSE, 1),
(1, 'INSERT', TRUE, 2),
(1, 'UPDATE', FALSE, 3),
(1, 'DELETE', FALSE, 4);

-- Варианты ответов для вопроса 2
INSERT INTO `answer_options` (`question_id`, `answer_text`, `is_correct`, `option_order`) VALUES
(2, 'Уникальный идентификатор записи в таблице', TRUE, 1),
(2, 'Ссылка на другую таблицу', FALSE, 2),
(2, 'Индекс для быстрого поиска', FALSE, 3),
(2, 'Поле для хранения паролей', FALSE, 4);

-- Варианты ответов для вопроса 3
INSERT INTO `answer_options` (`question_id`, `answer_text`, `is_correct`, `option_order`) VALUES
(3, 'MODIFY TABLE', FALSE, 1),
(3, 'CHANGE TABLE', FALSE, 2),
(3, 'ALTER TABLE', TRUE, 3),
(3, 'UPDATE TABLE', FALSE, 4);

-- Варианты ответов для вопроса 4
INSERT INTO `answer_options` (`question_id`, `answer_text`, `is_correct`, `option_order`) VALUES
(4, 'Удаление данных из таблицы', FALSE, 1),
(4, 'Объединение данных из нескольких таблиц', TRUE, 2),
(4, 'Создание новой таблицы', FALSE, 3),
(4, 'Сортировка результатов запроса', FALSE, 4);

-- Варианты ответов для вопроса 5
INSERT INTO `answer_options` (`question_id`, `answer_text`, `is_correct`, `option_order`) VALUES
(5, 'CHAR', FALSE, 1),
(5, 'VARCHAR', TRUE, 2),
(5, 'TEXT', FALSE, 3),
(5, 'STRING', FALSE, 4);

-- Варианты ответов для вопроса 6
INSERT INTO `answer_options` (`question_id`, `answer_text`, `is_correct`, `option_order`) VALUES
(6, 'Сортирует результаты', FALSE, 1),
(6, 'Группирует строки с одинаковыми значениями', TRUE, 2),
(6, 'Объединяет таблицы', FALSE, 3),
(6, 'Фильтрует данные', FALSE, 4);

-- Варианты ответов для вопроса 7
INSERT INTO `answer_options` (`question_id`, `answer_text`, `is_correct`, `option_order`) VALUES
(7, 'SUM()', FALSE, 1),
(7, 'COUNT()', TRUE, 2),
(7, 'AVG()', FALSE, 3),
(7, 'TOTAL()', FALSE, 4);

-- Варианты ответов для вопроса 8
INSERT INTO `answer_options` (`question_id`, `answer_text`, `is_correct`, `option_order`) VALUES
(8, 'Уникальный ключ таблицы', FALSE, 1),
(8, 'Ключ для шифрования данных', FALSE, 2),
(8, 'Ссылка на PRIMARY KEY другой таблицы', TRUE, 3),
(8, 'Индекс для поиска', FALSE, 4);

-- Варианты ответов для вопроса 9
INSERT INTO `answer_options` (`question_id`, `answer_text`, `is_correct`, `option_order`) VALUES
(9, 'DELETE FROM table_name', FALSE, 1),
(9, 'DROP TABLE table_name', FALSE, 2),
(9, 'TRUNCATE TABLE table_name', TRUE, 3),
(9, 'CLEAR TABLE table_name', FALSE, 4);

-- Варианты ответов для вопроса 10
INSERT INTO `answer_options` (`question_id`, `answer_text`, `is_correct`, `option_order`) VALUES
(10, 'Структура для ускорения поиска данных', TRUE, 1),
(10, 'Копия таблицы', FALSE, 2),
(10, 'Тип данных', FALSE, 3),
(10, 'Ограничение целостности', FALSE, 4);

-- Создание теста
INSERT INTO `tests` (`title`, `description`, `time_limit_minutes`, `passing_score`, `max_attempts`, `shuffle_questions`, `shuffle_answers`, `show_results`, `show_correct_answers`, `is_active`, `creator_id`) VALUES
('Основы SQL', 'Тест охватывает базовые SQL-команды и концепции реляционных баз данных', 45, 70.00, 3, TRUE, TRUE, TRUE, TRUE, TRUE, 1);

-- Связывание вопросов с тестом
INSERT INTO `test_questions` (`test_id`, `question_id`, `question_order`, `points`) VALUES
(1, 1, 1, 1.00),
(1, 2, 2, 1.00),
(1, 3, 3, 1.00),
(1, 4, 4, 1.00),
(1, 5, 5, 1.00),
(1, 6, 6, 1.00),
(1, 7, 7, 1.00),
(1, 8, 8, 1.00),
(1, 9, 9, 1.00),
(1, 10, 10, 1.00);

-- Назначение теста студентам
INSERT INTO `test_assignments` (`test_id`, `user_id`, `assigned_by`, `deadline`) VALUES
(1, 3, 1, DATE_ADD(NOW(), INTERVAL 7 DAY)),
(1, 4, 1, DATE_ADD(NOW(), INTERVAL 7 DAY));

-- Назначение теста группе
INSERT INTO `test_assignments` (`test_id`, `group_id`, `assigned_by`, `deadline`) VALUES
(1, 1, 1, DATE_ADD(NOW(), INTERVAL 14 DAY));

-- =====================================================
-- КОНЕЦ СКРИПТА ИНИЦИАЛИЗАЦИИ
-- =====================================================
