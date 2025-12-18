# Многостадийная сборка для минимизации размера образа

# Стадия 1: Сборка приложения
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Копируем go.mod и go.sum для кеширования зависимостей
COPY go.mod go.sum ./
RUN go mod download

# Копируем исходный код
COPY . .

# Собираем приложение
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o moodle-service ./cmd/main.go

# Стадия 2: Финальный образ
FROM alpine:latest

# Устанавливаем сертификаты для HTTPS
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Копируем скомпилированное приложение из builder
COPY --from=builder /app/moodle-service .

# Порт по умолчанию
EXPOSE 8004

# Запускаем приложение
CMD ["./moodle-service"]