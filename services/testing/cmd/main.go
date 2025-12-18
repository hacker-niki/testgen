package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
)

func main() {
	// Get configuration from environment
	port := getEnv("PORT", "8003")
	dbHost := getEnv("DB_HOST", "localhost")
	dbPort := getEnv("DB_PORT", "3306")
	dbUser := getEnv("DB_USER", "testgen_user")
	dbPassword := getEnv("DB_PASSWORD", "testgen_password")
	dbName := getEnv("DB_NAME", "testgen")
	redisHost := getEnv("REDIS_HOST", "localhost")
	redisPort := getEnv("REDIS_PORT", "6379")

	// Log configuration
	log.Printf("Starting Testing Service on port %s", port)
	log.Printf("Database: %s:%s/%s", dbHost, dbPort, dbName)
	log.Printf("Redis: %s:%s", redisHost, redisPort)

	// TODO: Initialize database connection
	// db, err := initDB(dbHost, dbPort, dbUser, dbPassword, dbName)
	// if err != nil {
	//     log.Fatalf("Failed to connect to database: %v", err)
	// }

	// TODO: Initialize Redis connection
	// redisClient := redis.NewClient(&redis.Options{
	//     Addr: fmt.Sprintf("%s:%s", redisHost, redisPort),
	// })

	// Initialize Gin router
	router := gin.Default()

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "ok",
			"service": "testing-service",
			"version": "1.0.0",
		})
	})

	// TODO: Setup routes
	// api := router.Group("/api")
	// {
	//     // Questions
	//     questions := api.Group("/questions")
	//     questions.Use(authMiddleware())
	//     {
	//         questions.GET("", handleGetQuestions)
	//         questions.GET("/:id", handleGetQuestion)
	//         questions.POST("/:id/approve", handleApproveQuestion)
	//         questions.PUT("/:id", handleUpdateQuestion)
	//         questions.POST("", handleCreateQuestion)
	//         questions.DELETE("/:id", handleDeleteQuestion)
	//     }
	//
	//     // Tests
	//     tests := api.Group("/tests")
	//     tests.Use(authMiddleware())
	//     {
	//         tests.POST("", handleCreateTest)
	//         tests.GET("", handleGetTests)
	//         tests.GET("/:id", handleGetTest)
	//         tests.PUT("/:id", handleUpdateTest)
	//         tests.DELETE("/:id", handleDeleteTest)
	//         tests.GET("/:id/questions", handleGetTestQuestions)
	//         tests.POST("/:id/assign", handleAssignTest)
	//         tests.POST("/:id/start", handleStartTest)
	//         tests.POST("/:id/submit", handleSubmitTest)
	//     }
	//
	//     // Results
	//     results := api.Group("/results")
	//     results.Use(authMiddleware())
	//     {
	//         results.GET("/me", handleGetMyResults)
	//         results.GET("", handleGetAllResults)
	//         results.GET("/:id", handleGetResult)
	//     }
	// }

	// Start server
	addr := fmt.Sprintf(":%s", port)
	log.Printf("Testing Service listening on %s", addr)
	if err := router.Run(addr); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
