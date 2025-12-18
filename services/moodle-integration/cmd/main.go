package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"moodle-integration-service/internal/database"
	"moodle-integration-service/internal/handlers"
	"moodle-integration-service/internal/repository"
	"moodle-integration-service/internal/service"
)

func main() {
	// Загружаем конфигурацию из переменных окружения
	dbConfig := database.LoadConfigFromEnv()

	// Подключаемся к БД
	db, err := database.Connect(dbConfig)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	log.Println("Connected to MariaDB successfully")

	// Инициализируем слои приложения
	questionRepo := repository.NewQuestionRepository(db)
	moodleService := service.NewMoodleService(questionRepo)
	moodleHandler := handlers.NewMoodleHandler(moodleService)

	// Настраиваем Gin router
	if os.Getenv("DEBUG") != "true" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.Default()

	// CORS middleware
	router.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// Health check
	router.GET("/health", moodleHandler.HealthCheck)

	// API routes
	api := router.Group("/api/moodle")
	{
		// Импорт вопросов из Moodle XML
		// Требует аутентификации (в production добавить middleware)
		api.POST("/import", mockAuthMiddleware(), moodleHandler.ImportQuestions)

		// Экспорт вопросов в Moodle XML (по ID из body)
		api.POST("/export", moodleHandler.ExportQuestions)

		// Экспорт вопросов в Moodle XML (по ID из query)
		api.GET("/export", moodleHandler.ExportQuestionsByID)

		// Экспорт всех одобренных вопросов
		api.GET("/export/approved", moodleHandler.ExportAllApproved)
	}

	// Получаем порт из переменных окружения
	port := os.Getenv("PORT")
	if port == "" {
		port = "8004"
	}

	log.Printf("Starting Moodle Integration Service on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

// mockAuthMiddleware - заглушка для аутентификации
// В production нужно реализовать проверку JWT токена
func mockAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// В реальном приложении здесь должна быть проверка JWT токена
		// и извлечение user_id из токена

		// Для MVP используем hardcoded user_id=1
		userID := int64(1)

		// Или можно получать из query параметра для тестирования
		if c.Query("user_id") != "" {
			// В production это НЕ БЕЗОПАСНО!
			// Используется только для тестирования
		}

		c.Set("user_id", userID)
		c.Next()
	}
}