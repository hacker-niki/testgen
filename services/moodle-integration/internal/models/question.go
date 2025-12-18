package models

import (
	"time"
)

// Question представляет вопрос в системе (из БД MariaDB)
type Question struct {
	ID              int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	QuestionText    string    `gorm:"type:text;not null" json:"question_text"`
	SourceDocumentID *int64   `gorm:"index" json:"source_document_id,omitempty"`
	CreatorID       int64     `gorm:"not null;index" json:"creator_id"`
	IsApproved      bool      `gorm:"not null;default:false" json:"is_approved"`
	ApprovedBy      *int64    `json:"approved_by,omitempty"`
	ApprovedAt      *time.Time `json:"approved_at,omitempty"`

	// Moodle интеграция
	MoodleName       *string   `gorm:"type:varchar(255)" json:"moodle_name,omitempty"`
	MoodleQuestionID *int64    `json:"moodle_question_id,omitempty"`
	DefaultGrade     float64   `gorm:"type:decimal(10,7);default:1.0" json:"default_grade"`
	Penalty          float64   `gorm:"type:decimal(10,7);default:0.3333333" json:"penalty"`
	ShuffleAnswers   bool      `gorm:"default:true" json:"shuffle_answers"`

	CreatedAt       time.Time  `gorm:"not null;default:CURRENT_TIMESTAMP" json:"created_at"`
	UpdatedAt       time.Time  `gorm:"not null;default:CURRENT_TIMESTAMP" json:"updated_at"`

	// Relationships
	AnswerOptions   []AnswerOption `gorm:"foreignKey:QuestionID;constraint:OnDelete:CASCADE" json:"answer_options,omitempty"`
}

// AnswerOption представляет вариант ответа
type AnswerOption struct {
	ID          int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	QuestionID  int64     `gorm:"not null;index" json:"question_id"`
	AnswerText  string    `gorm:"type:text;not null" json:"answer_text"`
	IsCorrect   bool      `gorm:"not null;default:false" json:"is_correct"`
	Fraction    *float64  `gorm:"type:decimal(10,7)" json:"fraction,omitempty"` // Для Moodle
	OptionOrder int       `gorm:"not null" json:"option_order"`
	CreatedAt   time.Time `gorm:"not null;default:CURRENT_TIMESTAMP" json:"created_at"`
}

// TableName указывает имя таблицы для Question
func (Question) TableName() string {
	return "questions"
}

// TableName указывает имя таблицы для AnswerOption
func (AnswerOption) TableName() string {
	return "answer_options"
}