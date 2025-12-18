-- Test results table
CREATE TABLE IF NOT EXISTS test_results (
    id INT PRIMARY KEY AUTO_INCREMENT,
    test_id INT NOT NULL,
    user_id INT NOT NULL,
    score INT NOT NULL,
    passed BOOLEAN,
    synced_to_moodle BOOLEAN DEFAULT FALSE COMMENT 'Синхронизировано в Moodle Gradebook',
    moodle_grade_id INT NULL COMMENT 'ID оценки в Moodle',
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (test_id) REFERENCES tests(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_test_id (test_id),
    INDEX idx_user_id (user_id),
    INDEX idx_completed_at (completed_at),
    INDEX idx_synced_to_moodle (synced_to_moodle)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User answers table
CREATE TABLE IF NOT EXISTS user_answers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    result_id INT NOT NULL,
    question_id INT NOT NULL,
    answer_id INT NOT NULL,
    is_correct BOOLEAN,
    FOREIGN KEY (result_id) REFERENCES test_results(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    FOREIGN KEY (answer_id) REFERENCES answers(id) ON DELETE CASCADE,
    INDEX idx_result_id (result_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
