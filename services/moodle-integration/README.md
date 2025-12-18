# Moodle Integration Service

Микросервис для интеграции с Moodle LMS. Обеспечивает импорт вопросов из Moodle XML и экспорт вопросов в формат Moodle XML.

## Возможности

- Импорт вопросов с множественным выбором (один правильный ответ) из Moodle XML
- Экспорт вопросов в Moodle XML формат
- Поддержка всех метаданных Moodle (penalty, shuffle_answers, default_grade и т.д.)
- Работа с существующей БД MariaDB

## API Endpoints

### Health Check
```
GET /health
```

Проверка работоспособности сервиса.

**Ответ:**
```json
{
  "status": "ok",
  "service": "moodle-integration-service"
}
```

### Импорт вопросов из Moodle XML
```
POST /api/moodle/import
```

Загружает Moodle XML файл и импортирует вопросы в БД.

**Параметры:**
- `file` (form-data) - Moodle XML файл

**Пример:**
```bash
curl -X POST http://localhost:8004/api/moodle/import \
  -F "file=@/path/to/moodle_questions.xml"
```

**Ответ:**
```json
{
  "message": "questions imported successfully",
  "questions_count": 5,
  "questions": [
    {
      "id": 1,
      "question_text": "В каком году был основан МРТИ?",
      "is_approved": false,
      "answer_options": [
        {
          "id": 1,
          "answer_text": "1964",
          "is_correct": true,
          "option_order": 1
        },
        ...
      ]
    }
  ]
}
```

### Экспорт вопросов в Moodle XML (POST)
```
POST /api/moodle/export
```

Экспортирует указанные вопросы в Moodle XML формат.

**Body:**
```json
{
  "question_ids": [1, 2, 3]
}
```

**Пример:**
```bash
curl -X POST http://localhost:8004/api/moodle/export \
  -H "Content-Type: application/json" \
  -d '{"question_ids": [1, 2, 3]}' \
  -o questions.xml
```

**Ответ:** XML файл для скачивания

### Экспорт вопросов в Moodle XML (GET)
```
GET /api/moodle/export?ids=1,2,3
```

Экспортирует указанные вопросы в Moodle XML формат через GET запрос.

**Пример:**
```bash
curl -X GET "http://localhost:8004/api/moodle/export?ids=1,2,3" -o questions.xml
```

### Экспорт всех одобренных вопросов
```
GET /api/moodle/export/approved
```

Экспортирует все одобренные вопросы в Moodle XML формат.

**Пример:**
```bash
curl -X GET http://localhost:8004/api/moodle/export/approved -o approved_questions.xml
```

## Формат Moodle XML

Сервис поддерживает стандартный формат Moodle XML для вопросов с множественным выбором:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<quiz>
  <question type="multichoice">
    <name>
      <text>Основание МРТИ</text>
    </name>
    <questiontext format="html">
      <text>В каком году был основан Минский радиотехнический институт?</text>
    </questiontext>
    <generalfeedback format="html">
      <text></text>
    </generalfeedback>
    <defaultgrade>1.0000000</defaultgrade>
    <penalty>0.3333333</penalty>
    <hidden>0</hidden>
    <idnumber></idnumber>
    <single>true</single>
    <shuffleanswers>true</shuffleanswers>
    <answernumbering>none</answernumbering>
    <showstandardinstruction>1</showstandardinstruction>
    <correctfeedback format="html">
      <text></text>
    </correctfeedback>
    <partiallycorrectfeedback format="html">
      <text></text>
    </partiallycorrectfeedback>
    <incorrectfeedback format="html">
      <text></text>
    </incorrectfeedback>
    <answer fraction="100" format="html">
      <text>1964</text>
      <feedback format="html">
        <text></text>
      </feedback>
    </answer>
    <answer fraction="0" format="html">
      <text>1971</text>
      <feedback format="html">
        <text></text>
      </feedback>
    </answer>
  </question>
</quiz>
```

## Развертывание

### Docker Compose

Сервис включен в общий docker-compose.yml:

```bash
docker-compose up -d moodle-integration-service
```

### Переменные окружения

- `DB_HOST` - хост БД (по умолчанию: localhost)
- `DB_PORT` - порт БД (по умолчанию: 3306)
- `DB_USER` - пользователь БД (по умолчанию: testgen_user)
- `DB_PASSWORD` - пароль БД (по умолчанию: testgen_pass)
- `DB_NAME` - имя БД (по умолчанию: testgen)
- `PORT` - порт сервиса (по умолчанию: 8004)
- `DEBUG` - режим отладки (по умолчанию: false)

## Разработка

### Структура проекта

```
moodle-integration-service/
├── cmd/
│   └── main.go              # Точка входа
├── internal/
│   ├── database/
│   │   └── database.go      # Подключение к БД
│   ├── handlers/
│   │   └── moodle_handler.go # HTTP handlers
│   ├── models/
│   │   ├── question.go      # Модели БД
│   │   └── moodle_xml.go    # Модели Moodle XML
│   ├── moodle/
│   │   ├── parser.go        # Парсер Moodle XML
│   │   └── exporter.go      # Экспорт в Moodle XML
│   ├── repository/
│   │   └── question_repository.go # Работа с БД
│   └── service/
│       └── moodle_service.go # Бизнес-логика
├── Dockerfile
├── go.mod
├── go.sum
└── README.md
```

### Локальный запуск

```bash
# Установить зависимости
go mod download

# Запустить сервис
export DB_HOST=localhost
export DB_PORT=3306
export DB_USER=testgen_user
export DB_PASSWORD=testgen_password
export DB_NAME=testgen
go run cmd/main.go
```

### Сборка

```bash
go build -o moodle-service ./cmd/main.go
```

## Примеры использования

### 1. Импорт вопросов из Moodle

```bash
# Импортировать вопросы из XML файла
curl -X POST http://localhost:8004/api/moodle/import \
  -F "file=@moodle_questions.xml"
```

### 2. Экспорт вопросов в Moodle

```bash
# Экспортировать конкретные вопросы
curl -X POST http://localhost:8004/api/moodle/export \
  -H "Content-Type: application/json" \
  -d '{"question_ids": [1, 2, 3]}' \
  -o exported_questions.xml

# Экспортировать все одобренные вопросы
curl -X GET http://localhost:8004/api/moodle/export/approved \
  -o approved_questions.xml
```

### 3. Интеграция с frontend

```javascript
// Импорт вопросов
const formData = new FormData();
formData.append('file', fileInput.files[0]);

const response = await fetch('http://localhost:8004/api/moodle/import', {
  method: 'POST',
  body: formData
});

const result = await response.json();
console.log(`Imported ${result.questions_count} questions`);

// Экспорт вопросов
const exportResponse = await fetch('http://localhost:8004/api/moodle/export', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    question_ids: [1, 2, 3]
  })
});

const blob = await exportResponse.blob();
const url = window.URL.createObjectURL(blob);
const a = document.createElement('a');
a.href = url;
a.download = 'questions.xml';
a.click();
```

## Ограничения

Текущая версия поддерживает только вопросы с множественным выбором с одним правильным ответом (`single=true`). Другие типы вопросов (matching, numerical, shortanswer и т.д.) будут добавлены в будущих версиях.

## Лицензия

MIT