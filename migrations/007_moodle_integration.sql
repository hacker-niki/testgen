-- Миграция для добавления полей Moodle интеграции

-- Добавляем поля для интеграции с Moodle в таблицу questions
ALTER TABLE questions
ADD COLUMN moodle_name VARCHAR(255) COMMENT 'Название вопроса в Moodle' AFTER approved_at,
ADD COLUMN moodle_question_id BIGINT COMMENT 'ID вопроса в Moodle' AFTER moodle_name,
ADD COLUMN default_grade DECIMAL(10,7) DEFAULT 1.0000000 COMMENT 'Оценка по умолчанию' AFTER moodle_question_id,
ADD COLUMN penalty DECIMAL(10,7) DEFAULT 0.3333333 COMMENT 'Штраф за неправильный ответ' AFTER default_grade,
ADD COLUMN shuffle_answers BOOLEAN DEFAULT TRUE COMMENT 'Перемешивать ответы' AFTER penalty;

-- Добавляем поле fraction в таблицу answer_options для Moodle
ALTER TABLE answer_options
ADD COLUMN fraction DECIMAL(10,7) COMMENT 'Процент правильности в Moodle (100 для правильного, 0 для неправильного)' AFTER is_correct;

-- Создаем индексы для улучшения производительности
CREATE INDEX idx_moodle_question_id ON questions(moodle_question_id);

-- Обновляем существующие записи: устанавливаем fraction на основе is_correct
UPDATE answer_options
SET fraction = CASE
    WHEN is_correct = TRUE THEN 100.0000000
    ELSE 0.0000000
END;

-- Комментарии к таблицам
ALTER TABLE questions COMMENT = 'Вопросы с поддержкой Moodle интеграции';
ALTER TABLE answer_options COMMENT = 'Варианты ответов с поддержкой Moodle fraction';