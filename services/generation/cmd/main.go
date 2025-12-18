package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/gin-gonic/gin"
)

func main() {
	// Get configuration from environment
	port := getEnv("PORT", "8002")
	dbHost := getEnv("DB_HOST", "localhost")
	dbPort := getEnv("DB_PORT", "3306")
	dbUser := getEnv("DB_USER", "testgen_user")
	dbPassword := getEnv("DB_PASSWORD", "testgen_password")
	dbName := getEnv("DB_NAME", "testgen")
	redisHost := getEnv("REDIS_HOST", "localhost")
	redisPort := getEnv("REDIS_PORT", "6379")
	ollamaURL := getEnv("OLLAMA_URL", "http://localhost:11434")

	// Log configuration
	log.Printf("Starting Generation Service on port %s", port)
	log.Printf("Database: %s:%s/%s", dbHost, dbPort, dbName)
	log.Printf("Redis: %s:%s", redisHost, redisPort)
	log.Printf("Ollama: %s", ollamaURL)

	// TODO: Initialize database connection
	// db, err := initDB(dbHost, dbPort, dbUser, dbPassword, dbName)
	// if err != nil {
	//     log.Fatalf("Failed to connect to database: %v", err)
	// }

	// TODO: Initialize Redis connection
	// redisClient := redis.NewClient(&redis.Options{
	//     Addr: fmt.Sprintf("%s:%s", redisHost, redisPort),
	// })

	// Create context for graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Start background worker in a goroutine
	go startBackgroundWorker(ctx, redisHost, redisPort, ollamaURL)

	// Initialize Gin router
	router := gin.Default()

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "ok",
			"service": "generation-service",
			"version": "1.0.0",
			"worker":  "running",
		})
	})

	// TODO: Setup routes
	// api := router.Group("/api")
	// {
	//     documents := api.Group("/documents")
	//     documents.Use(authMiddleware())
	//     {
	//         documents.POST("", handleUploadDocument)
	//         documents.GET("", handleGetDocuments)
	//         documents.GET("/:id", handleGetDocument)
	//         documents.DELETE("/:id", handleDeleteDocument)
	//     }
	// }

	// Setup graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	// Start HTTP server in goroutine
	go func() {
		addr := fmt.Sprintf(":%s", port)
		log.Printf("Generation Service HTTP API listening on %s", addr)
		if err := router.Run(addr); err != nil {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for shutdown signal
	<-quit
	log.Println("Shutting down Generation Service...")
	cancel() // Stop background worker
}

// startBackgroundWorker runs the AI worker in a loop
func startBackgroundWorker(ctx context.Context, redisHost, redisPort, ollamaURL string) {
	log.Printf("Starting Background Worker...")
	log.Printf("Worker will process tasks from Redis queue: ai:tasks")

	// TODO: Initialize Redis client
	// redisClient := redis.NewClient(&redis.Options{
	//     Addr: fmt.Sprintf("%s:%s", redisHost, redisPort),
	// })

	// TODO: Initialize Ollama client
	// ollamaClient := NewOllamaClient(ollamaURL)

	// Main worker loop
	for {
		select {
		case <-ctx.Done():
			log.Println("Background Worker shutting down...")
			return
		default:
			// TODO: Implement worker logic
			// 1. BLPOP from Redis queue (ai:tasks)
			// 2. Parse task
			// 3. Fetch document from DB
			// 4. Call Ollama API to generate questions
			// 5. Parse response
			// 6. Save questions to DB
			// 7. Update document status

			// For now, just log that worker is running
			// log.Println("Worker waiting for tasks...")
			// time.Sleep(5 * time.Second)
		}
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
