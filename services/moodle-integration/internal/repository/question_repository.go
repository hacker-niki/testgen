package repository

import (
	"fmt"

	"gorm.io/gorm"
	"moodle-integration-service/internal/models"
)

// QuestionRepository отвечает за работу с вопросами в БД
type QuestionRepository struct {
	db *gorm.DB
}

// NewQuestionRepository создает новый экземпляр QuestionRepository
func NewQuestionRepository(db *gorm.DB) *QuestionRepository {
	return &QuestionRepository{db: db}
}

// CreateQuestions создает несколько вопросов с ответами в транзакции
func (r *QuestionRepository) CreateQuestions(questions []models.Question, creatorID int64) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		for i := range questions {
			// Устанавливаем creator_id для каждого вопроса
			questions[i].CreatorID = creatorID

			// Создаем вопрос
			if err := tx.Create(&questions[i]).Error; err != nil {
				return fmt.Errorf("failed to create question: %w", err)
			}

			// Обновляем QuestionID для всех ответов
			for j := range questions[i].AnswerOptions {
				questions[i].AnswerOptions[j].QuestionID = questions[i].ID
			}
		}

		return nil
	})
}

// GetQuestionsByIDs получает вопросы по списку ID с их ответами
func (r *QuestionRepository) GetQuestionsByIDs(ids []int64) ([]models.Question, error) {
	var questions []models.Question

	err := r.db.Preload("AnswerOptions").Where("id IN ?", ids).Find(&questions).Error
	if err != nil {
		return nil, fmt.Errorf("failed to get questions: %w", err)
	}

	return questions, nil
}

// GetAllApprovedQuestions получает все одобренные вопросы с ответами
func (r *QuestionRepository) GetAllApprovedQuestions() ([]models.Question, error) {
	var questions []models.Question

	err := r.db.Preload("AnswerOptions").Where("is_approved = ?", true).Find(&questions).Error
	if err != nil {
		return nil, fmt.Errorf("failed to get approved questions: %w", err)
	}

	return questions, nil
}

// GetAllQuestions получает все вопросы с ответами
func (r *QuestionRepository) GetAllQuestions() ([]models.Question, error) {
	var questions []models.Question

	err := r.db.Preload("AnswerOptions").Find(&questions).Error
	if err != nil {
		return nil, fmt.Errorf("failed to get all questions: %w", err)
	}

	return questions, nil
}