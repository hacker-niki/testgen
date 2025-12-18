.PHONY: build up down restart logs clean migrate-up migrate-down seed test lint

# Build all services
build:
	@echo "Building all services..."
	docker-compose build

build-auth:
	@echo "Building auth-service..."
	docker-compose build auth-service

build-generation:
	@echo "Building generation-service..."
	docker-compose build generation-service

build-testing:
	@echo "Building testing-service..."
	docker-compose build testing-service

# Start services
up:
	@echo "Starting services..."
	docker-compose up -d

# Stop services
down:
	@echo "Stopping services..."
	docker-compose down

# Restart services
restart:
	@echo "Restarting services..."
	docker-compose restart

# View logs
logs:
	docker-compose logs -f

logs-auth:
	docker-compose logs -f auth-service

logs-generation:
	docker-compose logs -f generation-service

logs-testing:
	docker-compose logs -f testing-service

logs-nginx:
	docker-compose logs -f nginx

# Clean up
clean:
	@echo "Cleaning up..."
	docker-compose down -v
	docker system prune -f

# Database migrations
migrate-up:
	@echo "Applying migrations..."
	@echo "Migrations are auto-applied on startup"

migrate-down:
	@echo "Rolling back migrations..."
	@echo "Manual rollback required"

# Seed test data
seed:
	@echo "Seeding test data..."
	./scripts/seed-data.sh

# Run tests
test:
	@echo "Running tests..."
	cd services/auth-service && go test ./...
	cd services/generation-service && go test ./...
	cd services/testing-service && go test ./...

test-auth:
	@echo "Running auth-service tests..."
	cd services/auth-service && go test ./...

test-generation:
	@echo "Running generation-service tests..."
	cd services/generation-service && go test ./...

test-testing:
	@echo "Running testing-service tests..."
	cd services/testing-service && go test ./...

# Lint code
lint:
	@echo "Running linter..."
	cd services/auth-service && golangci-lint run
	cd services/generation-service && golangci-lint run
	cd services/testing-service && golangci-lint run

# Initialize Ollama model
init-ollama:
	@echo "Pulling Ollama model..."
	docker exec testgen-ollama ollama pull mistral-nemo:12b-instruct-2407-q8_0