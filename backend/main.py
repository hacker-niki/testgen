"""
FastAPI приложение для системы TestGen.
Интегрировано с MariaDB через SQLAlchemy ORM.
"""

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import func

# Импорт модулей проекта
from database import get_db, check_db_connection
import models
import auth

app = FastAPI(
    title="TestGen MVP",
    description="Система автоматизированного тестирования с генерацией вопросов",
    version="1.0.0"
)

# CORS middleware для работы с React/Next.js
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =====================================================
# PYDANTIC МОДЕЛИ (DTO)
# =====================================================

class AnswerOptionResponse(BaseModel):
    """Модель ответа для варианта ответа"""
    id: int
    text: str
    is_correct: bool
    order: int

    class Config:
        from_attributes = True


class QuestionResponse(BaseModel):
    """Модель ответа для вопроса"""
    id: int
    question: str
    answers: List[AnswerOptionResponse]
    is_approved: bool

    class Config:
        from_attributes = True


class DocumentResponse(BaseModel):
    """Модель ответа для документа"""
    id: int
    name: str
    status: str
    uploaded_at: str
    questions_count: int

    class Config:
        from_attributes = True


class TestResponse(BaseModel):
    """Модель ответа для теста"""
    id: int
    title: str
    description: Optional[str]
    time_limit: Optional[int]
    passing_score: float
    questions_count: int
    created_at: str

    class Config:
        from_attributes = True


class TestDetailResponse(BaseModel):
    """Детальная информация о тесте"""
    id: int
    title: str
    description: Optional[str]
    time_limit: Optional[int]
    passing_score: float
    max_attempts: Optional[int]
    shuffle_questions: bool
    shuffle_answers: bool
    show_results: bool
    show_correct_answers: bool
    is_active: bool

    class Config:
        from_attributes = True


# =====================================================
# UTILITY ФУНКЦИИ
# =====================================================

def format_datetime(dt: Optional[datetime]) -> Optional[str]:
    """Форматирование datetime в строку"""
    if dt is None:
        return None
    return dt.strftime("%Y-%m-%d %H:%M:%S")


# =====================================================
# API ENDPOINTS
# =====================================================

@app.on_event("startup")
async def startup_event():
    """Проверка подключения к БД при старте приложения"""
    print("Starting TestGen API...")
    if check_db_connection():
        print("Database connection established successfully!")
    else:
        print("WARNING: Could not establish database connection!")


@app.get("/")
async def root():
    """Корневой endpoint с информацией об API"""
    return {
        "message": "TestGen MVP API",
        "version": "1.0.0",
        "database": "MariaDB with SQLAlchemy ORM",
        "endpoints": {
            "questions": "/api/questions",
            "documents": "/api/documents",
            "tests": "/api/tests",
            "health": "/health"
        }
    }


@app.get("/health")
async def health_check(db: Session = Depends(get_db)):
    """
    Health check endpoint для проверки состояния системы
    """
    try:
        # Проверка подключения к БД
        from sqlalchemy import text
        db.execute(text("SELECT 1"))

        # Получение статистики
        total_users = db.query(models.User).count()
        total_questions = db.query(models.Question).count()
        total_tests = db.query(models.Test).count()

        return {
            "status": "healthy",
            "database": "connected",
            "statistics": {
                "users": total_users,
                "questions": total_questions,
                "tests": total_tests
            }
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Service unavailable: {str(e)}")


# =====================================================
# АВТОРИЗАЦИЯ (AUTH)
# =====================================================

@app.post("/api/auth/login", response_model=auth.Token)
async def login(login_request: auth.LoginRequest, db: Session = Depends(get_db)):
    """
    Авторизация пользователя по email (без пароля для MVP)

    Args:
        login_request: Email пользователя
        db: Сессия БД

    Returns:
        Token с данными пользователя
    """
    return await auth.login_user(login_request.email, db)


@app.get("/api/auth/me", response_model=auth.UserResponse)
async def get_current_user_info(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Получить информацию о текущем пользователе

    Args:
        current_user: Текущий авторизованный пользователь
        db: Сессия БД

    Returns:
        Данные пользователя с ролями
    """
    roles = auth.get_user_roles(db, current_user.id)

    return auth.UserResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        is_active=current_user.is_active,
        roles=roles
    )


@app.get("/api/auth/users", response_model=list[auth.UserResponse])
async def get_all_users(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Получить список всех пользователей (требуется авторизация)

    Args:
        current_user: Текущий пользователь
        db: Сессия БД

    Returns:
        Список пользователей
    """
    users = db.query(models.User).all()

    result = []
    for user in users:
        roles = auth.get_user_roles(db, user.id)
        result.append(auth.UserResponse(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            is_active=user.is_active,
            roles=roles
        ))

    return result


# =====================================================
# ВОПРОСЫ (QUESTIONS)
# =====================================================

@app.get("/api/questions", response_model=dict)
async def get_questions(
    approved_only: bool = False,
    limit: int = 100,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """
    Получить список вопросов с фильтрацией

    Args:
        approved_only: Только одобренные вопросы
        limit: Максимальное количество вопросов
        offset: Смещение для пагинации
        db: Сессия БД
    """
    try:
        # Базовый запрос
        query = db.query(models.Question).join(models.AnswerOption)

        # Применение фильтров
        if approved_only:
            query = query.filter(models.Question.is_approved == True)

        # Получение общего количества
        total = query.count()

        # Пагинация
        questions_db = query.offset(offset).limit(limit).all()

        # Формирование ответа
        questions_list = []
        for q in questions_db:
            answers = [
                AnswerOptionResponse(
                    id=a.id,
                    text=a.answer_text,
                    is_correct=a.is_correct,
                    order=a.option_order
                )
                for a in q.answer_options
            ]

            questions_list.append({
                "id": q.id,
                "question": q.question_text,
                "answers": answers,
                "is_approved": q.is_approved
            })

        return {
            "questions": questions_list,
            "total": total,
            "limit": limit,
            "offset": offset
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching questions: {str(e)}")


@app.get("/api/questions/{question_id}", response_model=QuestionResponse)
async def get_question(question_id: int, db: Session = Depends(get_db)):
    """
    Получить конкретный вопрос по ID
    """
    question = db.query(models.Question).filter(models.Question.id == question_id).first()

    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    answers = [
        AnswerOptionResponse(
            id=a.id,
            text=a.answer_text,
            is_correct=a.is_correct,
            order=a.option_order
        )
        for a in question.answer_options
    ]

    return QuestionResponse(
        id=question.id,
        question=question.question_text,
        answers=answers,
        is_approved=question.is_approved,
        difficulty=question.difficulty.value if question.difficulty else None
    )


@app.post("/api/questions/{question_id}/approve")
async def approve_question(question_id: int, user_id: int = 1, db: Session = Depends(get_db)):
    """
    Одобрить вопрос

    NOTE: В MVP версии используем hardcoded user_id=1 (admin)
    В production версии user_id должен извлекаться из токена аутентификации
    """
    question = db.query(models.Question).filter(models.Question.id == question_id).first()

    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    # Обновление статуса одобрения
    question.is_approved = True
    question.approved_by = user_id
    question.approved_at = datetime.now()

    db.commit()
    db.refresh(question)

    return {
        "status": "success",
        "message": "Question approved successfully",
        "question_id": question_id
    }


@app.delete("/api/questions/{question_id}")
async def delete_question(question_id: int, db: Session = Depends(get_db)):
    """
    Удалить вопрос
    """
    question = db.query(models.Question).filter(models.Question.id == question_id).first()

    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    db.delete(question)
    db.commit()

    return {
        "status": "success",
        "message": "Question deleted successfully"
    }


# =====================================================
# ДОКУМЕНТЫ (DOCUMENTS)
# =====================================================

@app.get("/api/documents")
async def get_documents(
    status: Optional[str] = None,
    limit: int = 100,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """
    Получить список загруженных документов

    Args:
        status: Фильтр по статусу (pending, processing, completed, failed)
        limit: Максимальное количество документов
        offset: Смещение для пагинации
        db: Сессия БД
    """
    try:
        # Базовый запрос
        query = db.query(models.SourceDocument)

        # Фильтр по статусу
        if status:
            query = query.filter(models.SourceDocument.status == status)

        # Получение общего количества
        total = query.count()

        # Пагинация
        documents_db = query.order_by(models.SourceDocument.created_at.desc()).offset(offset).limit(limit).all()

        # Формирование ответа
        documents_list = []
        for doc in documents_db:
            # Подсчет вопросов для документа
            questions_count = db.query(models.Question).filter(
                models.Question.source_document_id == doc.id
            ).count()

            documents_list.append({
                "id": doc.id,
                "name": doc.filename,
                "status": doc.status.value if doc.status else "unknown",
                "uploaded_at": format_datetime(doc.created_at),
                "questions_count": questions_count
            })

        return {
            "documents": documents_list,
            "total": total,
            "limit": limit,
            "offset": offset
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching documents: {str(e)}")


# =====================================================
# ТЕСТЫ (TESTS)
# =====================================================

@app.get("/api/tests")
async def get_tests(
    active_only: bool = True,
    limit: int = 100,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """
    Получить список тестов

    Args:
        active_only: Только активные тесты
        limit: Максимальное количество тестов
        offset: Смещение для пагинации
        db: Сессия БД
    """
    try:
        # Базовый запрос
        query = db.query(models.Test)

        # Фильтр активных тестов
        if active_only:
            query = query.filter(models.Test.is_active == True)

        # Получение общего количества
        total = query.count()

        # Пагинация
        tests_db = query.order_by(models.Test.created_at.desc()).offset(offset).limit(limit).all()

        # Формирование ответа
        tests_list = []
        for test in tests_db:
            # Подсчет вопросов в тесте
            questions_count = db.query(models.TestQuestion).filter(
                models.TestQuestion.test_id == test.id
            ).count()

            tests_list.append({
                "id": test.id,
                "title": test.title,
                "description": test.description,
                "time_limit": test.time_limit_minutes,
                "passing_score": float(test.passing_score),
                "questions_count": questions_count,
                "created_at": format_datetime(test.created_at)
            })

        return {
            "tests": tests_list,
            "total": total,
            "limit": limit,
            "offset": offset
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching tests: {str(e)}")


@app.get("/api/tests/{test_id}")
async def get_test(test_id: int, db: Session = Depends(get_db)):
    """
    Получить детальную информацию о тесте
    """
    test = db.query(models.Test).filter(models.Test.id == test_id).first()

    if not test:
        raise HTTPException(status_code=404, detail="Test not found")

    # Подсчет вопросов
    questions_count = db.query(models.TestQuestion).filter(
        models.TestQuestion.test_id == test.id
    ).count()

    return {
        "id": test.id,
        "title": test.title,
        "description": test.description,
        "time_limit": test.time_limit_minutes,
        "passing_score": float(test.passing_score),
        "max_attempts": test.max_attempts,
        "shuffle_questions": test.shuffle_questions,
        "shuffle_answers": test.shuffle_answers,
        "show_results": test.show_results,
        "show_correct_answers": test.show_correct_answers,
        "is_active": test.is_active,
        "questions_count": questions_count,
        "created_at": format_datetime(test.created_at)
    }


@app.get("/api/tests/{test_id}/questions")
async def get_test_questions(test_id: int, db: Session = Depends(get_db)):
    """
    Получить вопросы для конкретного теста
    """
    # Проверка существования теста
    test = db.query(models.Test).filter(models.Test.id == test_id).first()
    if not test:
        raise HTTPException(status_code=404, detail="Test not found")

    # Получение вопросов теста через связующую таблицу
    test_questions = db.query(models.TestQuestion).filter(
        models.TestQuestion.test_id == test_id
    ).order_by(models.TestQuestion.question_order).all()

    questions_list = []
    for tq in test_questions:
        question = tq.question

        # Получение вариантов ответов
        answers = [
            {
                "id": a.id,
                "text": a.answer_text,
                "is_correct": a.is_correct if test.show_correct_answers else None,  # Скрываем правильные ответы если нужно
                "order": a.option_order
            }
            for a in question.answer_options
        ]

        questions_list.append({
            "id": question.id,
            "question": question.question_text,
            "answers": answers,
            "difficulty": question.difficulty.value if question.difficulty else None,
            "points": float(tq.points),
            "order": tq.question_order
        })

    return {
        "test_id": test_id,
        "test_title": test.title,
        "questions": questions_list,
        "total_questions": len(questions_list)
    }


# =====================================================
# СТАТИСТИКА И АНАЛИТИКА
# =====================================================

@app.get("/api/stats/overview")
async def get_stats_overview(db: Session = Depends(get_db)):
    """
    Получить общую статистику системы
    """
    try:
        stats = {
            "users": {
                "total": db.query(models.User).count(),
                "active": db.query(models.User).filter(models.User.is_active == True).count()
            },
            "questions": {
                "total": db.query(models.Question).count(),
                "approved": db.query(models.Question).filter(models.Question.is_approved == True).count(),
                "by_difficulty": {
                    "easy": db.query(models.Question).filter(models.Question.difficulty == "easy").count(),
                    "medium": db.query(models.Question).filter(models.Question.difficulty == "medium").count(),
                    "hard": db.query(models.Question).filter(models.Question.difficulty == "hard").count()
                }
            },
            "tests": {
                "total": db.query(models.Test).count(),
                "active": db.query(models.Test).filter(models.Test.is_active == True).count()
            },
            "sessions": {
                "total": db.query(models.TestSession).count(),
                "completed": db.query(models.TestSession).filter(
                    models.TestSession.status == "completed"
                ).count(),
                "in_progress": db.query(models.TestSession).filter(
                    models.TestSession.status == "in_progress"
                ).count()
            },
            "documents": {
                "total": db.query(models.SourceDocument).count(),
                "processed": db.query(models.SourceDocument).filter(
                    models.SourceDocument.status == "completed"
                ).count()
            }
        }

        return stats

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching statistics: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
