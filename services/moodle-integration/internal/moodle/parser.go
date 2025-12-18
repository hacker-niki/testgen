package moodle

import (
	"encoding/xml"
	"fmt"
	"io"
	"strconv"
	"strings"

	"moodle-integration-service/internal/models"
)

// Parser отвечает за парсинг Moodle XML
type Parser struct{}

// NewParser создает новый экземпляр Parser
func NewParser() *Parser {
	return &Parser{}
}

// ParseXML парсит Moodle XML и возвращает список вопросов
func (p *Parser) ParseXML(reader io.Reader) ([]models.Question, error) {
	var quiz models.MoodleQuiz
	decoder := xml.NewDecoder(reader)

	if err := decoder.Decode(&quiz); err != nil {
		return nil, fmt.Errorf("failed to decode XML: %w", err)
	}

	questions := make([]models.Question, 0)

	for _, mq := range quiz.Questions {
		// Поддерживаем только multichoice с single=true
		if mq.Type != "multichoice" {
			continue
		}

		// Проверяем, что это вопрос с одним правильным ответом
		if mq.Single != "true" {
			continue
		}

		question, err := p.convertMoodleQuestion(mq)
		if err != nil {
			return nil, fmt.Errorf("failed to convert question: %w", err)
		}

		questions = append(questions, question)
	}

	return questions, nil
}

// convertMoodleQuestion конвертирует Moodle вопрос в внутреннюю модель
func (p *Parser) convertMoodleQuestion(mq models.MoodleQuestion) (models.Question, error) {
	// Парсим DefaultGrade
	defaultGrade := 1.0
	if mq.DefaultGrade != "" {
		if parsed, err := strconv.ParseFloat(mq.DefaultGrade, 64); err == nil {
			defaultGrade = parsed
		}
	}

	// Парсим Penalty
	penalty := 0.3333333
	if mq.Penalty != "" {
		if parsed, err := strconv.ParseFloat(mq.Penalty, 64); err == nil {
			penalty = parsed
		}
	}

	// Парсим ShuffleAnswers
	shuffleAnswers := true
	if mq.ShuffleAnswers == "false" || mq.ShuffleAnswers == "0" {
		shuffleAnswers = false
	}

	// Извлекаем текст вопроса (убираем CDATA и HTML теги)
	questionText := p.cleanText(mq.QuestionText.Text)

	question := models.Question{
		QuestionText:   questionText,
		MoodleName:     &mq.Name.Text,
		DefaultGrade:   defaultGrade,
		Penalty:        penalty,
		ShuffleAnswers: shuffleAnswers,
		IsApproved:     false,
		AnswerOptions:  make([]models.AnswerOption, 0),
	}

	// Конвертируем ответы
	for i, ma := range mq.Answers {
		fraction, err := strconv.ParseFloat(ma.Fraction, 64)
		if err != nil {
			continue
		}

		isCorrect := fraction > 0
		answerText := p.cleanText(ma.Text)

		answer := models.AnswerOption{
			AnswerText:  answerText,
			IsCorrect:   isCorrect,
			Fraction:    &fraction,
			OptionOrder: i + 1,
		}

		question.AnswerOptions = append(question.AnswerOptions, answer)
	}

	return question, nil
}

// cleanText очищает текст от CDATA и базовых HTML тегов
func (p *Parser) cleanText(text string) string {
	// Убираем CDATA
	text = strings.ReplaceAll(text, "<![CDATA[", "")
	text = strings.ReplaceAll(text, "]]>", "")

	// Убираем некоторые HTML теги (базовая очистка)
	text = strings.ReplaceAll(text, "<p>", "")
	text = strings.ReplaceAll(text, "</p>", "")
	text = strings.ReplaceAll(text, "<br>", "\n")
	text = strings.ReplaceAll(text, "<br/>", "\n")

	// Убираем атрибуты dir и style (базовая очистка)
	// Более сложная очистка требует использования html.Parse

	return strings.TrimSpace(text)
}