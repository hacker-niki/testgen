# TestGen - AI-Powered Test Generation Platform

Платформа для автоматической генерации тестовых вопросов с использованием локальных языковых моделей и интеграцией с Moodle LMS.

## Архитектура

Микросервисная архитектура на базе Go:

- **Auth Service** (8001) - JWT аутентификация и управление пользователями
- **Generation Service** (8002) - Загрузка документов и генерация вопросов через Ollama
- **Testing Service** (8003) - Управление тестами и результатами
- **Moodle Integration Service** (8004) - Синхронизация с Moodle LMS
- **Frontend** (React + Vite) - Пользовательский интерфейс
- **Nginx** - API Gateway и reverse proxy
- **MariaDB** - База данных
- **Redis** - Очередь задач и кеш
- **Ollama** - Локальная языковая модель (Mistral-Nemo)

### Диаграмма архитектуры

```
┌─────────────┐
│   Frontend  │ (React + Vite)
│   :3000     │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Nginx    │ (API Gateway + Reverse Proxy)
│    :80      │
└──────┬──────┘
       │
       ├──────────┬──────────┬──────────┬──────────┬──────────┐
       ▼          ▼          ▼          ▼          ▼          ▼
┌──────────┐ ┌────────┐ ┌─────────┐ ┌─────────┐ ┌──────────┐ ┌──────────┐
│   Auth   │ │ Gener- │ │ Testing │ │ Moodle  │ │   Redis  │ │ MariaDB  │
│ Service  │ │ ation  │ │ Service │ │ Integr. │ │  :6379   │ │  :3306   │
│  :8001   │ │ :8002  │ │  :8003  │ │  :8004  │ └──────────┘ └──────────┘
└──────────┘ └─────┬──┘ └─────────┘ └────┬────┘
                   │                      │
                   │                      │
                   ▼                      ▼
                Ollama              Moodle LMS
                :11434           (External API)
```

## Структура проекта

```
application/
│
├── 📄 README.md                         # Полная документация проекта
├── 📄 PROJECT_STRUCTURE.md              # Детальная структура
├── 📄 .gitignore                        # Git ignore
├── 📄 docker-compose.yml                # Оркестрация всех сервисов
├── 📄 Makefile                          # Автоматизация команд (build, run, test)
│
├── 🌐 nginx/                            # API Gateway & Reverse Proxy
│   ├── 📄 Dockerfile                    # Nginx контейнер
│   ├── 📄 nginx.conf                    # Конфигурация маршрутизации
│   └── 📄 ssl/                          # SSL сертификаты (опционально)
│
├── 🔧 services/                         # Микросервисы на Go
│   │
│   ├── 🔐 auth-service/                 # Сервис аутентификации
│   │   ├── cmd/
│   │   │   └── main.go                  # Точка входа
│   │   ├── internal/
│   │   │   ├── handlers/                # HTTP handlers
│   │   │   │   ├── auth.go             # POST /api/auth/register, /login
│   │   │   │   └── users.go            # GET /api/users (админ)
│   │   │   ├── models/                  # Модели данных
│   │   │   │   └── user.go             # User, Role
│   │   │   ├── repository/              # Работа с БД
│   │   │   │   └── user_repo.go
│   │   │   ├── service/                 # Бизнес-логика
│   │   │   │   └── auth_service.go     # Хеширование паролей, выдача JWT
│   │   │   └── middleware/
│   │   │       └── jwt.go               # Валидация токенов
│   │   ├── pkg/
│   │   │   └── jwt/                     # JWT утилиты
│   │   │       └── jwt.go
│   │   ├── 📄 Dockerfile
│   │   ├── 📄 go.mod
│   │   └── 📄 go.sum
│   │
│   ├── 📄 generation-service/           # Сервис генерации вопросов + AI Worker
│   │   ├── cmd/
│   │   │   └── main.go                  # HTTP сервер + фоновый воркер
│   │   ├── internal/
│   │   │   ├── handlers/
│   │   │   │   └── documents.go        # POST, GET, DELETE /api/documents
│   │   │   ├── worker/
│   │   │   │   └── worker.go            # Фоновый воркер (горутина)
│   │   │   ├── ollama/
│   │   │   │   ├── client.go            # HTTP клиент для Ollama API
│   │   │   │   └── prompts.go           # Промпты для генерации
│   │   │   ├── models/
│   │   │   │   ├── document.go         # Document, Status
│   │   │   │   └── task.go             # GenerationTask
│   │   │   ├── repository/
│   │   │   │   └── document_repo.go
│   │   │   ├── service/
│   │   │   │   ├── document_service.go # Загрузка, парсинг .txt/.md
│   │   │   │   └── queue_service.go    # Постановка задач в Redis
│   │   │   └── middleware/
│   │   │       └── auth.go              # Проверка JWT
│   │   ├── 📄 Dockerfile
│   │   ├── 📄 go.mod
│   │   └── 📄 go.sum
│   │
│   ├── 📝 testing-service/              # Сервис тестирования
│   │   ├── cmd/
│   │   │   └── main.go                  # Точка входа
│   │   ├── internal/
│   │   │   ├── handlers/
│   │   │   │   ├── questions.go        # CRUD /api/questions
│   │   │   │   ├── tests.go            # CRUD /api/tests
│   │   │   │   └── results.go          # GET, POST /api/results
│   │   │   ├── models/
│   │   │   │   ├── question.go         # Question, Answer
│   │   │   │   ├── test.go             # Test, TestQuestion
│   │   │   │   └── result.go           # TestResult, UserAnswer
│   │   │   ├── repository/
│   │   │   │   ├── question_repo.go
│   │   │   │   ├── test_repo.go
│   │   │   │   └── result_repo.go
│   │   │   ├── service/
│   │   │   │   ├── question_service.go # Одобрение, фильтрация
│   │   │   │   ├── test_service.go     # Создание тестов, назначение
│   │   │   │   └── result_service.go   # Подсчет баллов, статистика
│   │   │   └── middleware/
│   │   │       └── auth.go              # Проверка JWT
│   │   ├── 📄 Dockerfile
│   │   ├── 📄 go.mod
│   │   └── 📄 go.sum
│   │
│   └── 🔗 moodle-integration-service/   # Сервис интеграции с Moodle
│       ├── cmd/
│       │   └── main.go                  # Точка входа
│       ├── internal/
│       │   ├── handlers/
│       │   │   ├── sync.go             # POST /api/moodle/sync
│       │   │   └── courses.go          # GET /api/moodle/courses
│       │   ├── moodle/
│       │   │   ├── client.go            # Moodle Web Services API клиент
│       │   │   └── mapper.go            # Маппинг данных TestGen ↔ Moodle
│       │   ├── models/
│       │   │   ├── course.go           # Moodle Course
│       │   │   └── quiz.go             # Moodle Quiz
│       │   ├── repository/
│       │   │   └── sync_repo.go
│       │   └── service/
│       │       ├── sync_service.go     # Синхронизация тестов
│       │       └── grade_service.go    # Отправка оценок в Moodle
│       ├── 📄 Dockerfile
│       ├── 📄 go.mod
│       └── 📄 go.sum
│
├── ⚛️  frontend/                        # React Frontend
│   ├── 📄 Dockerfile
│   ├── 📄 package.json
│   ├── 📄 vite.config.js
│   ├── 📄 index.html
│   └── src/
│       ├── 📄 main.jsx
│       ├── 📄 index.css
│       ├── 📄 App.jsx
│       ├── 📄 App.css
│       ├── api/                         # API клиенты
│       │   └── client.js                # Axios + JWT interceptor
│       ├── context/
│       │   └── AuthContext.jsx
│       ├── components/
│       │   └── ProtectedRoute.jsx
│       └── pages/
│           ├── 📄 Login.jsx             # Авторизация
│           ├── 📄 Dashboard.jsx
│           ├── 📄 Documents.jsx
│           ├── 📄 Questions.jsx
│           ├── 📄 Tests.jsx
│           ├── 📄 TakeTest.jsx
│           └── 📄 MoodleSync.jsx        # Синхронизация с Moodle
│
├── 🗄️  migrations/                      # SQL миграции для MariaDB
│   ├── 📄 001_init_schema.sql           # Таблицы users, roles
│   ├── 📄 002_documents.sql             # Таблица documents
│   ├── 📄 003_questions.sql             # Таблица questions, answers
│   ├── 📄 004_tests.sql                 # Таблицы tests, test_questions
│   ├── 📄 005_results.sql               # Таблицы test_results, user_answers
│   └── 📄 006_moodle_sync.sql           # Таблицы moodle_courses, moodle_quizzes
│
└── 📜 scripts/                          # Утилиты
    ├── 🚀 start.sh                      # Быстрый старт (docker-compose up)
    ├── 📄 init-db.sh                    # Применение миграций
    ├── 📄 seed-data.sh                  # Тестовые данные
    └── 📄 test-ollama.sh                # Проверка подключения к Ollama
```

## Возможности

### Реализовано:
- ✅ JWT аутентификация и авторизация
- ✅ Ролевая модель (admin, teacher, user)
- ✅ Загрузка документов (.txt, .md)
- ✅ Автоматическая генерация вопросов через Ollama
- ✅ Асинхронная обработка через Redis Queue
- ✅ Одобрение/редактирование вопросов
- ✅ Создание и назначение тестов
- ✅ Прохождение тестов с таймером
- ✅ Подсчет результатов и статистика
- ✅ Микросервисная архитектура
- ✅ Персистентность данных (MariaDB)

### Интеграция с Moodle:
- ✅ Синхронизация пользователей из Moodle
- ✅ Экспорт тестов в Moodle Quiz (формат XML)
- ✅ Импорт курсов из Moodle
- ✅ Автоматическая отправка результатов в Gradebook
- ✅ SSO через Moodle (опционально)

## Быстрый старт

### Требования

- Docker и Docker Compose
- NVIDIA GPU с 18+ GB VRAM (для Ollama)
- CUDA Toolkit 11.8+
- (Опционально) Доступ к Moodle LMS с включенными Web Services

### Запуск

```bash
# 1. Запустить все сервисы
./scripts/start.sh

# Или через make
make up

# Или напрямую через docker-compose
docker-compose up -d --build
```

### Доступ к приложению

После запуска приложение будет доступно по адресу: **http://localhost**

**Дефолтные учетные данные администратора:**
- Email: `admin@testgen.com`
- Password: `admin123`

## Инициализация Ollama модели

После первого запуска необходимо загрузить модель Ollama:

```bash
make init-ollama
```

Это загрузит модель `mistral-nemo:12b-instruct-2407-q8_0`.

## Управление сервисами

### Просмотр логов

```bash
# Все логи
make logs

# Логи конкретного сервиса
make logs-auth
make logs-generation
make logs-testing
make logs-moodle
```

### Остановка сервисов

```bash
make down
```

### Перезапуск

```bash
make restart
```

### Очистка

```bash
# Остановить и удалить все контейнеры и volumes
make clean
```

## API Endpoints

### Auth Service (http://localhost/api/auth)
- `POST /api/auth/register` - Регистрация
- `POST /api/auth/login` - Вход
- `POST /api/auth/verify` - Проверка токена
- `GET /api/users` - Список пользователей (admin)
- `GET /api/users/{id}` - Детали пользователя
- `PUT /api/users/{id}` - Редактирование пользователя (admin)
- `DELETE /api/users/{id}` - Удаление пользователя (admin)

### Generation Service (http://localhost/api/documents)
- `POST /api/documents` - Загрузка документа (admin/teacher)
- `GET /api/documents` - Список документов
- `GET /api/documents/{id}` - Детали документа
- `DELETE /api/documents/{id}` - Удаление документа (admin/teacher)

### Testing Service (http://localhost/api)
- `GET /api/questions` - Список вопросов
- `GET /api/questions/{id}` - Детали вопроса
- `POST /api/questions/{id}/approve` - Одобрить вопрос (admin/teacher)
- `PUT /api/questions/{id}` - Редактировать вопрос (admin/teacher)
- `POST /api/questions` - Создать вопрос вручную (admin/teacher)
- `DELETE /api/questions/{id}` - Удалить вопрос (admin/teacher)
- `POST /api/tests` - Создание теста (admin/teacher)
- `GET /api/tests` - Список тестов
- `GET /api/tests/{id}` - Детали теста
- `PUT /api/tests/{id}` - Редактировать тест (admin/teacher)
- `DELETE /api/tests/{id}` - Удалить тест (admin/teacher)
- `POST /api/tests/{id}/start` - Начать тест
- `POST /api/tests/{id}/submit` - Отправить ответы
- `GET /api/results` - Результаты (admin/teacher - все, user - свои)
- `GET /api/results/{id}` - Детали результата

### Moodle Integration Service (http://localhost/api/moodle)
- `GET /api/moodle/courses` - Список курсов из Moodle
- `GET /api/moodle/courses/{id}/students` - Студенты курса
- `POST /api/moodle/sync/users` - Синхронизация пользователей
- `POST /api/moodle/sync/courses` - Синхронизация курсов
- `POST /api/moodle/export/test/{id}` - Экспорт теста в Moodle Quiz
- `POST /api/moodle/grades/sync` - Синхронизация оценок в Gradebook
- `GET /api/moodle/status` - Статус подключения к Moodle

## Интеграция с Moodle LMS

TestGen поддерживает полную интеграцию с Moodle через Web Services API.

### Настройка Moodle

#### 1. Включение Web Services в Moodle

1. Войдите в Moodle как администратор
2. Перейдите в **Site Administration → Advanced features**
3. Включите **Enable web services**
4. Перейдите в **Site Administration → Plugins → Web services → Manage protocols**
5. Включите **REST protocol**

#### 2. Создание Web Service пользователя

1. Создайте нового пользователя или используйте существующего
2. Перейдите в **Site Administration → Plugins → Web services → Manage tokens**
3. Создайте новый токен для пользователя
4. Скопируйте созданный токен

#### 3. Настройка прав доступа

Пользователь должен иметь следующие capabilities:
- `moodle/course:view` - просмотр курсов
- `moodle/course:viewparticipants` - просмотр участников
- `moodle/user:viewdetails` - просмотр деталей пользователей
- `moodle/question:add` - добавление вопросов
- `moodle/grade:edit` - редактирование оценок

### Конфигурация TestGen

Добавьте следующие переменные окружения в `docker-compose.yml` для сервиса `moodle-integration-service`:

```yaml
moodle-integration-service:
  environment:
    - MOODLE_URL=https://your-moodle-site.com
    - MOODLE_TOKEN=your_web_service_token
    - MOODLE_SERVICE=moodle_mobile_app  # или ваш custom service
```

### Использование интеграции

#### Синхронизация пользователей

```bash
# Через API
curl -X POST http://localhost/api/moodle/sync/users \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

Или через интерфейс:
1. Войдите как admin/teacher
2. Перейдите в **Moodle Sync**
3. Нажмите **Синхронизировать пользователей**

#### Экспорт теста в Moodle

```bash
# Экспорт теста с ID=5 в Moodle курс с ID=10
curl -X POST http://localhost/api/moodle/export/test/5 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "course_id": 10,
    "quiz_name": "AI Generated Quiz",
    "time_limit": 3600,
    "attempts_allowed": 3
  }'
```

Или через интерфейс:
1. Откройте тест в TestGen
2. Нажмите **Экспортировать в Moodle**
3. Выберите курс и настройки
4. Нажмите **Экспортировать**

#### Автоматическая синхронизация оценок

При включенной синхронизации, результаты прохождения тестов в TestGen автоматически отправляются в Moodle Gradebook.

Конфигурация:

```yaml
moodle-integration-service:
  environment:
    - AUTO_SYNC_GRADES=true
    - SYNC_INTERVAL=300  # секунды, проверка каждые 5 минут
```

#### Формат экспорта вопросов

TestGen экспортирует вопросы в формат Moodle XML (GIFT format):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<quiz>
  <question type="multichoice">
    <name>
      <text>Question from TestGen</text>
    </name>
    <questiontext format="html">
      <text><![CDATA[What is Go?]]></text>
    </questiontext>
    <single>true</single>
    <shuffleanswers>true</shuffleanswers>
    <answer fraction="100">
      <text>Programming language</text>
    </answer>
    <answer fraction="0">
      <text>Board game</text>
    </answer>
  </question>
</quiz>
```

### Примеры использования Moodle API

#### Получение списка курсов

```go
// internal/moodle/client.go
func (c *MoodleClient) GetCourses() ([]Course, error) {
    params := url.Values{}
    params.Add("wstoken", c.token)
    params.Add("wsfunction", "core_course_get_courses")
    params.Add("moodlewsrestformat", "json")

    resp, err := http.Get(c.baseURL + "/webservice/rest/server.php?" + params.Encode())
    // ... обработка ответа
}
```

#### Создание quiz в Moodle

```go
func (c *MoodleClient) CreateQuiz(courseID int, quiz Quiz) error {
    params := url.Values{}
    params.Add("wstoken", c.token)
    params.Add("wsfunction", "mod_quiz_add_instance")
    params.Add("course", strconv.Itoa(courseID))
    params.Add("name", quiz.Name)
    params.Add("timeopen", strconv.FormatInt(quiz.TimeOpen, 10))
    // ... остальные параметры
}
```

#### Отправка оценки

```go
func (c *MoodleClient) UpdateGrade(userID, quizID int, grade float64) error {
    params := url.Values{}
    params.Add("wstoken", c.token)
    params.Add("wsfunction", "core_grades_update_grades")
    params.Add("source", "mod/quiz")
    params.Add("itemname", fmt.Sprintf("quiz_%d", quizID))
    params.Add("grades[0][userid]", strconv.Itoa(userID))
    params.Add("grades[0][grade]", fmt.Sprintf("%.2f", grade))
    // ...
}
```

### Поддерживаемые функции Moodle Web Services

TestGen использует следующие функции Moodle Web Services:

**Курсы:**
- `core_course_get_courses` - получение списка курсов
- `core_course_get_contents` - получение содержимого курса
- `core_enrol_get_enrolled_users` - получение студентов курса

**Пользователи:**
- `core_user_get_users` - получение пользователей
- `core_user_get_users_by_field` - поиск пользователей

**Вопросы и тесты:**
- `mod_quiz_get_quizzes_by_courses` - получение тестов
- `core_question_update_flag` - обновление вопросов
- `mod_quiz_submit_quiz_attempt` - отправка попытки теста

**Оценки:**
- `core_grades_update_grades` - обновление оценок
- `gradereport_user_get_grade_items` - получение оценок студента

### Безопасность интеграции

1. **Токен хранится в переменных окружения**, не в коде
2. **HTTPS обязателен** для production окружения
3. **IP фильтрация** в настройках Moodle Web Services
4. **Логирование всех запросов** к Moodle API
5. **Валидация данных** перед отправкой в Moodle

### Troubleshooting Moodle интеграции

#### Ошибка: "Web services are not enabled"

Решение: Включите Web Services в Moodle (см. раздел "Настройка Moodle")

#### Ошибка: "Invalid token"

Решение:
1. Проверьте правильность токена в переменных окружения
2. Убедитесь, что токен не истек
3. Создайте новый токен в Moodle

#### Ошибка: "Access denied"

Решение: Проверьте права пользователя, для которого создан токен

#### Проверка подключения

```bash
# Проверка статуса подключения к Moodle
curl http://localhost/api/moodle/status \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Ответ:
{
  "status": "connected",
  "moodle_version": "4.1.0",
  "site_name": "Your Moodle Site"
}
```

## Разработка

### Сборка отдельных сервисов

```bash
# Все сервисы
make build

# Отдельные сервисы
make build-auth
make build-generation
make build-testing
make build-moodle
```

### Запуск тестов

```bash
# Все тесты
make test

# Тесты конкретного сервиса
make test-auth
make test-generation
make test-testing
make test-moodle
```

### Линтер

```bash
make lint
```

## Технологии

### Backend
- **Go 1.21+**
- **Gin** - HTTP framework
- **GORM** - ORM
- **go-redis** - Redis client
- **JWT** - Аутентификация

### Frontend
- **React 18**
- **Vite**
- **React Router**
- **Axios**

### Infrastructure
- **Docker & Docker Compose**
- **Nginx** - API Gateway
- **MariaDB 10.11** - База данных
- **Redis 7.2** - Кеш и очереди
- **Ollama** - Языковая модель

### Интеграция
- **Moodle Web Services API** - REST API
- **Moodle XML (GIFT)** - Формат экспорта вопросов

## Производительность

### Требования к железу

**Application Node:**
- CPU: 8 cores
- RAM: 16 GB
- SSD: 200 GB

**AI Node:**
- CPU: 16 cores
- RAM: 64 GB
- GPU: NVIDIA RTX 4090 / A100 (24 GB VRAM)
- SSD: 500 GB
- CUDA: 12.0+

## Схема базы данных

### users
```sql
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    role ENUM('admin', 'teacher', 'user') DEFAULT 'user',
    moodle_user_id INT NULL,  -- ID пользователя в Moodle
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### documents
```sql
CREATE TABLE documents (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    file_type ENUM('txt', 'md') NOT NULL,
    status ENUM('pending', 'processing', 'completed', 'failed') DEFAULT 'pending',
    uploaded_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE CASCADE
);
```

### questions
```sql
CREATE TABLE questions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    document_id INT,
    text TEXT NOT NULL,
    type ENUM('single_choice', 'multiple_choice') DEFAULT 'single_choice',
    explanation TEXT,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE SET NULL
);
```

### answers
```sql
CREATE TABLE answers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question_id INT NOT NULL,
    text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    order_num INT,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
);
```

### tests
```sql
CREATE TABLE tests (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    duration_minutes INT DEFAULT 30,
    passing_score INT DEFAULT 70,
    created_by INT NOT NULL,
    moodle_quiz_id INT NULL,  -- ID quiz в Moodle
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);
```

### test_results
```sql
CREATE TABLE test_results (
    id INT PRIMARY KEY AUTO_INCREMENT,
    test_id INT NOT NULL,
    user_id INT NOT NULL,
    score INT NOT NULL,
    passed BOOLEAN,
    synced_to_moodle BOOLEAN DEFAULT FALSE,  -- Синхронизировано в Moodle
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (test_id) REFERENCES tests(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### moodle_courses
```sql
CREATE TABLE moodle_courses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    moodle_course_id INT UNIQUE NOT NULL,
    fullname VARCHAR(255) NOT NULL,
    shortname VARCHAR(100) NOT NULL,
    category INT,
    last_sync_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### moodle_sync_log
```sql
CREATE TABLE moodle_sync_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    sync_type ENUM('users', 'courses', 'grades', 'tests') NOT NULL,
    status ENUM('success', 'failed') NOT NULL,
    records_synced INT DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Сценарии использования

### 1. Генерация и экспорт теста в Moodle

```
1. Teacher загружает документ → POST /api/documents
2. Generation Service генерирует вопросы через Ollama
3. Teacher проверяет и одобряет вопросы → POST /api/questions/{id}/approve
4. Teacher создает тест → POST /api/tests
5. Teacher экспортирует тест в Moodle → POST /api/moodle/export/test/{id}
6. Moodle Integration Service:
   - Конвертирует вопросы в Moodle XML
   - Создает quiz в Moodle через API
   - Связывает тест TestGen с quiz Moodle (сохраняет moodle_quiz_id)
```

### 2. Синхронизация студентов и оценок

```
1. Admin запускает синхронизацию курсов → POST /api/moodle/sync/courses
2. Импортируются курсы из Moodle → сохраняются в moodle_courses
3. Admin синхронизирует студентов → POST /api/moodle/sync/users
4. Студенты проходят тест в TestGen
5. Background Worker (каждые 5 минут):
   - Находит несинхронизированные результаты (synced_to_moodle=false)
   - Отправляет оценки в Moodle Gradebook
   - Помечает synced_to_moodle=true
```

## Troubleshooting

### Ollama не запускается

Убедитесь, что у вас установлены NVIDIA драйверы и Docker с поддержкой GPU:

```bash
# Проверить доступность GPU
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

### База данных не инициализируется

Проверьте логи MariaDB:

```bash
docker logs testgen-mariadb
```

### Сервисы не могут подключиться к БД

Убедитесь, что MariaDB полностью запустилась перед другими сервисами:

```bash
docker-compose restart
```

### Moodle интеграция не работает

Проверьте логи moodle-integration-service:

```bash
make logs-moodle
```

Проверьте статус подключения:

```bash
curl http://localhost/api/moodle/status -H "Authorization: Bearer TOKEN"
```

## Лицензия

MIT

## Контакты

Для вопросов и предложений создавайте issue в репозитории.