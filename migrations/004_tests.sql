-- Tests table
CREATE TABLE IF NOT EXISTS tests (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    duration_minutes INT DEFAULT 30,
    passing_score INT DEFAULT 70,
    created_by INT NOT NULL,
    moodle_quiz_id INT NULL COMMENT 'ID quiz в Moodle',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_created_by (created_by),
    INDEX idx_created_at (created_at),
    INDEX idx_moodle_quiz_id (moodle_quiz_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Test questions (many-to-many)
CREATE TABLE IF NOT EXISTS test_questions (
    test_id INT NOT NULL,
    question_id INT NOT NULL,
    order_num INT NOT NULL,
    PRIMARY KEY (test_id, question_id),
    FOREIGN KEY (test_id) REFERENCES tests(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    INDEX idx_test_id (test_id),
    INDEX idx_order_num (order_num)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Test assignments
CREATE TABLE IF NOT EXISTS test_assignments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    test_id INT NOT NULL,
    user_id INT NOT NULL,
    deadline TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (test_id) REFERENCES tests(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_assignment (test_id, user_id),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
