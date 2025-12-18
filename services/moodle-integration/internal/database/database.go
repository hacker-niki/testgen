package database

import (
	"fmt"
	"log"
	"os"
	"time"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// Config содержит параметры подключения к БД
type Config struct {
	Host     string
	Port     string
	User     string
	Password string
	DBName   string
}

// LoadConfigFromEnv загружает конфигурацию из переменных окружения
func LoadConfigFromEnv() *Config {
	return &Config{
		Host:     getEnv("DB_HOST", "localhost"),
		Port:     getEnv("DB_PORT", "3306"),
		User:     getEnv("DB_USER", "testgen_user"),
		Password: getEnv("DB_PASSWORD", "testgen_pass"),
		DBName:   getEnv("DB_NAME", "testgen"),
	}
}

// Connect создает подключение к БД
func Connect(config *Config) (*gorm.DB, error) {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		config.User,
		config.Password,
		config.Host,
		config.Port,
		config.DBName,
	)

	// Настраиваем логгер
	gormLogger := logger.Default
	if getEnv("DEBUG", "false") == "true" {
		gormLogger = logger.Default.LogMode(logger.Info)
	}

	// Подключаемся к БД
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: gormLogger,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// Настраиваем connection pool
	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("failed to get database instance: %w", err)
	}

	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(time.Hour)

	log.Println("Database connection established successfully")
	return db, nil
}

// getEnv получает значение переменной окружения или возвращает default
func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}