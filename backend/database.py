"""
Модуль для настройки подключения к базе данных MariaDB.
Использует SQLAlchemy для ORM и работы с БД.
"""

import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from typing import Generator

# Получение параметров подключения из переменных окружения
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_USER = os.getenv("DB_USER", "testgen_user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "testgen_pass")
DB_NAME = os.getenv("DB_NAME", "testgen")

# Формирование строки подключения для MariaDB
# Используем pymysql драйвер для работы с MariaDB
DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}?charset=utf8mb4"

# Создание движка SQLAlchemy
# echo=True включает логирование SQL-запросов (полезно для отладки)
# pool_pre_ping=True проверяет соединение перед использованием
# pool_recycle=3600 пересоздает соединения каждый час
engine = create_engine(
    DATABASE_URL,
    echo=True,  # Для продакшена поменять на False
    pool_pre_ping=True,
    pool_recycle=3600,
    pool_size=10,
    max_overflow=20
)

# Создание фабрики сессий
# autocommit=False - транзакции должны коммититься явно
# autoflush=False - не делать автоматический flush перед каждым запросом
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# Базовый класс для всех моделей SQLAlchemy
Base = declarative_base()


def get_db() -> Generator:
    """
    Генератор для получения сессии базы данных.

    Используется как dependency в FastAPI endpoints.
    Автоматически закрывает сессию после использования.

    Yields:
        Session: Сессия SQLAlchemy для работы с БД

    Example:
        @app.get("/items")
        def get_items(db: Session = Depends(get_db)):
            return db.query(Item).all()
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """
    Инициализация базы данных.

    Создает все таблицы, определенные в моделях SQLAlchemy.
    ВНИМАНИЕ: Это не заменяет миграции!
    Для продакшена используйте Alembic для управления миграциями.
    """
    # Импортируем все модели, чтобы они были зарегистрированы в Base
    import models  # noqa

    # Создаем все таблицы
    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully!")


def check_db_connection() -> bool:
    """
    Проверка подключения к базе данных.

    Returns:
        bool: True если подключение успешно, False в противном случае
    """
    try:
        with engine.connect() as connection:
            connection.execute("SELECT 1")
        print("Database connection successful!")
        return True
    except Exception as e:
        print(f"Database connection failed: {e}")
        return False
