package moodle

import (
	"encoding/xml"
	"fmt"
	"io"
	"strconv"

	"moodle-integration-service/internal/models"
)

// Exporter отвечает за экспорт вопросов в Moodle XML
type Exporter struct{}

// NewExporter создает новый экземпляр Exporter
func NewExporter() *Exporter {
	return &Exporter{}
}

// ExportToXML экспортирует вопросы в Moodle XML формат
func (e *Exporter) ExportToXML(questions []models.Question, writer io.Writer) error {
	quiz := models.MoodleQuiz{
		Questions: make([]models.MoodleQuestion, 0),
	}

	for _, q := range questions {
		mq, err := e.convertToMoodleQuestion(q)
		if err != nil {
			return fmt.Errorf("failed to convert question %d: %w", q.ID, err)
		}
		quiz.Questions = append(quiz.Questions, mq)
	}

	// Записываем XML заголовок
	if _, err := writer.Write([]byte(xml.Header)); err != nil {
		return fmt.Errorf("failed to write XML header: %w", err)
	}

	// Кодируем quiz в XML
	encoder := xml.NewEncoder(writer)
	encoder.Indent("", "  ")

	if err := encoder.Encode(quiz); err != nil {
		return fmt.Errorf("failed to encode XML: %w", err)
	}

	return nil
}

// convertToMoodleQuestion конвертирует внутреннюю модель в Moodle формат
func (e *Exporter) convertToMoodleQuestion(q models.Question) (models.MoodleQuestion, error) {
	// Название вопроса
	name := "Question"
	if q.MoodleName != nil && *q.MoodleName != "" {
		name = *q.MoodleName
	} else {
		name = fmt.Sprintf("Question %d", q.ID)
	}

	mq := models.MoodleQuestion{
		Type: "multichoice",
		Name: models.MoodleText{
			Text: name,
		},
		QuestionText: models.MoodleText{
			Format: "html",
			Text:   q.QuestionText,
		},
		GeneralFeedback: models.MoodleText{
			Format: "html",
			Text:   "",
		},
		DefaultGrade:            strconv.FormatFloat(q.DefaultGrade, 'f', 7, 64),
		Penalty:                 strconv.FormatFloat(q.Penalty, 'f', 7, 64),
		Hidden:                  "0",
		IDNumber:                "",
		Single:                  "true",
		ShuffleAnswers:          e.boolToString(q.ShuffleAnswers),
		AnswerNumbering:         "none",
		ShowStandardInstruction: "1",
		CorrectFeedback: models.MoodleText{
			Format: "html",
			Text:   "",
		},
		PartiallyCorrectFeedback: models.MoodleText{
			Format: "html",
			Text:   "",
		},
		IncorrectFeedback: models.MoodleText{
			Format: "html",
			Text:   "",
		},
		Answers: make([]models.MoodleAnswer, 0),
	}

	// Конвертируем ответы
	for _, ans := range q.AnswerOptions {
		fraction := "0"
		if ans.IsCorrect {
			fraction = "100"
		} else if ans.Fraction != nil {
			fraction = strconv.FormatFloat(*ans.Fraction, 'f', 0, 64)
		}

		ma := models.MoodleAnswer{
			Fraction: fraction,
			Format:   "html",
			Text:     ans.AnswerText,
			Feedback: models.MoodleText{
				Format: "html",
				Text:   "",
			},
		}

		mq.Answers = append(mq.Answers, ma)
	}

	return mq, nil
}

// boolToString конвертирует bool в строку для XML
func (e *Exporter) boolToString(b bool) string {
	if b {
		return "true"
	}
	return "false"
}