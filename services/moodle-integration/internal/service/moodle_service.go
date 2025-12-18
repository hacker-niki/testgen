package service

import (
	"bytes"
	"fmt"
	"io"

	"moodle-integration-service/internal/models"
	"moodle-integration-service/internal/moodle"
	"moodle-integration-service/internal/repository"
)

// MoodleService содержит бизнес-логику для работы с Moodle интеграцией
type MoodleService struct {
	repo     *repository.QuestionRepository
	parser   *moodle.Parser
	exporter *moodle.Exporter
}

// NewMoodleService создает новый экземпляр MoodleService
func NewMoodleService(repo *repository.QuestionRepository) *MoodleService {
	return &MoodleService{
		repo:     repo,
		parser:   moodle.NewParser(),
		exporter: moodle.NewExporter(),
	}
}

// ImportQuestionsFromXML импортирует вопросы из Moodle XML
func (s *MoodleService) ImportQuestionsFromXML(reader io.Reader, creatorID int64) ([]models.Question, error) {
	// Парсим XML
	questions, err := s.parser.ParseXML(reader)
	if err != nil {
		return nil, fmt.Errorf("failed to parse XML: %w", err)
	}

	if len(questions) == 0 {
		return nil, fmt.Errorf("no valid questions found in XML")
	}

	// Сохраняем в БД
	if err := s.repo.CreateQuestions(questions, creatorID); err != nil {
		return nil, fmt.Errorf("failed to save questions: %w", err)
	}

	return questions, nil
}

// ExportQuestionsToXML экспортирует вопросы в Moodle XML формат
func (s *MoodleService) ExportQuestionsToXML(questionIDs []int64) ([]byte, error) {
	// Получаем вопросы из БД
	questions, err := s.repo.GetQuestionsByIDs(questionIDs)
	if err != nil {
		return nil, fmt.Errorf("failed to get questions: %w", err)
	}

	if len(questions) == 0 {
		return nil, fmt.Errorf("no questions found")
	}

	// Экспортируем в XML
	var buf bytes.Buffer
	if err := s.exporter.ExportToXML(questions, &buf); err != nil {
		return nil, fmt.Errorf("failed to export to XML: %w", err)
	}

	return buf.Bytes(), nil
}

// ExportAllApprovedQuestionsToXML экспортирует все одобренные вопросы
func (s *MoodleService) ExportAllApprovedQuestionsToXML() ([]byte, error) {
	// Получаем все одобренные вопросы
	questions, err := s.repo.GetAllApprovedQuestions()
	if err != nil {
		return nil, fmt.Errorf("failed to get approved questions: %w", err)
	}

	if len(questions) == 0 {
		return nil, fmt.Errorf("no approved questions found")
	}

	// Экспортируем в XML
	var buf bytes.Buffer
	if err := s.exporter.ExportToXML(questions, &buf); err != nil {
		return nil, fmt.Errorf("failed to export to XML: %w", err)
	}

	return buf.Bytes(), nil
}