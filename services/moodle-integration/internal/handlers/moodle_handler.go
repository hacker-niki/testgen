package handlers

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"moodle-integration-service/internal/service"
)

// MoodleHandler обрабатывает HTTP запросы для Moodle интеграции
type MoodleHandler struct {
	service *service.MoodleService
}

// NewMoodleHandler создает новый экземпляр MoodleHandler
func NewMoodleHandler(service *service.MoodleService) *MoodleHandler {
	return &MoodleHandler{
		service: service,
	}
}

// ImportQuestions обрабатывает загрузку Moodle XML файла
// POST /api/moodle/import
func (h *MoodleHandler) ImportQuestions(c *gin.Context) {
	// Получаем creator_id из контекста (должен быть установлен middleware аутентификации)
	creatorID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	userID, ok := creatorID.(int64)
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user id"})
		return
	}

	// Получаем загруженный файл
	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "file is required"})
		return
	}

	// Открываем файл
	src, err := file.Open()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to open file"})
		return
	}
	defer src.Close()

	// Импортируем вопросы
	questions, err := h.service.ImportQuestionsFromXML(src, userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":        "questions imported successfully",
		"questions_count": len(questions),
		"questions":       questions,
	})
}

// ExportQuestions экспортирует вопросы в Moodle XML
// POST /api/moodle/export
// Body: {"question_ids": [1, 2, 3]}
func (h *MoodleHandler) ExportQuestions(c *gin.Context) {
	var request struct {
		QuestionIDs []int64 `json:"question_ids"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	if len(request.QuestionIDs) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "question_ids is required"})
		return
	}

	// Экспортируем вопросы
	xmlData, err := h.service.ExportQuestionsToXML(request.QuestionIDs)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Отправляем XML как файл для скачивания
	c.Header("Content-Disposition", "attachment; filename=moodle_questions.xml")
	c.Data(http.StatusOK, "application/xml", xmlData)
}

// ExportAllApproved экспортирует все одобренные вопросы в Moodle XML
// GET /api/moodle/export/approved
func (h *MoodleHandler) ExportAllApproved(c *gin.Context) {
	// Экспортируем все одобренные вопросы
	xmlData, err := h.service.ExportAllApprovedQuestionsToXML()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Отправляем XML как файл для скачивания
	c.Header("Content-Disposition", "attachment; filename=moodle_approved_questions.xml")
	c.Data(http.StatusOK, "application/xml", xmlData)
}

// ExportQuestionsByID экспортирует вопросы по ID из query параметров
// GET /api/moodle/export?ids=1,2,3
func (h *MoodleHandler) ExportQuestionsByID(c *gin.Context) {
	idsParam := c.Query("ids")
	if idsParam == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ids parameter is required"})
		return
	}

	// Парсим ID
	idStrings := strings.Split(idsParam, ",")
	questionIDs := make([]int64, 0, len(idStrings))

	for _, idStr := range idStrings {
		id, err := strconv.ParseInt(strings.TrimSpace(idStr), 10, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id format"})
			return
		}
		questionIDs = append(questionIDs, id)
	}

	// Экспортируем вопросы
	xmlData, err := h.service.ExportQuestionsToXML(questionIDs)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Отправляем XML как файл для скачивания
	c.Header("Content-Disposition", "attachment; filename=moodle_questions.xml")
	c.Data(http.StatusOK, "application/xml", xmlData)
}

// HealthCheck проверяет работоспособность сервиса
// GET /health
func (h *MoodleHandler) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "ok",
		"service": "moodle-integration-service",
	})
}