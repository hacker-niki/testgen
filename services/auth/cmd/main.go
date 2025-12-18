package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
)

func main() {
	// Get configuration from environment
	port := getEnv("PORT", "8001")
	dbHost := getEnv("DB_HOST", "localhost")
	dbPort := getEnv("DB_PORT", "3306")
	dbUser := getEnv("DB_USER", "testgen_user")
	dbPassword := getEnv("DB_PASSWORD", "testgen_password")
	dbName := getEnv("DB_NAME", "testgen")
	jwtSecret := getEnv("JWT_SECRET", "your-secret-key")

	// Log configuration (without sensitive data)
	log.Printf("Starting Auth Service on port %s", port)
	log.Printf("Database: %s:%s/%s", dbHost, dbPort, dbName)
	log.Printf("JWT Secret: %s", maskString(jwtSecret))

	// TODO: Initialize database connection
	// db, err := initDB(dbHost, dbPort, dbUser, dbPassword, dbName)
	// if err != nil {
	//     log.Fatalf("Failed to connect to database: %v", err)
	// }

	// Initialize Gin router
	router := gin.Default()

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "ok",
			"service": "auth-service",
			"version": "1.0.0",
		})
	})

	// TODO: Setup routes
	// api := router.Group("/api")
	// {
	//     auth := api.Group("/auth")
	//     {
	//         auth.POST("/register", handleRegister)
	//         auth.POST("/login", handleLogin)
	//         auth.POST("/verify", handleVerify)
	//     }
	//
	//     users := api.Group("/users")
	//     users.Use(authMiddleware())
	//     {
	//         users.GET("", handleGetUsers)
	//         users.GET("/:id", handleGetUser)
	//         users.PUT("/:id", handleUpdateUser)
	//         users.DELETE("/:id", handleDeleteUser)
	//     }
	// }

	// Start server
	addr := fmt.Sprintf(":%s", port)
	log.Printf("Auth Service listening on %s", addr)
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

func maskString(s string) string {
	if len(s) <= 4 {
		return "****"
	}
	return s[:2] + "****" + s[len(s)-2:]
}