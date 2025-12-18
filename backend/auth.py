"""
Модуль авторизации для TestGen MVP.
Упрощенная авторизация без проверки пароля - только по email.
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timedelta
import os

from database import get_db
import models

# OAuth2 схема для токенов
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")

# Простой "токен" - для MVP используем просто email
# В production версии здесь должен быть JWT


class Token(BaseModel):
    """Модель токена авторизации"""
    access_token: str
    token_type: str = "bearer"
    user: Optional[dict] = None


class LoginRequest(BaseModel):
    """Запрос на авторизацию"""
    email: str


class UserResponse(BaseModel):
    """Модель ответа с данными пользователя"""
    id: int
    email: str
    full_name: str
    is_active: bool
    roles: list[str]

    class Config:
        from_attributes = True


def get_user_by_email(db: Session, email: str) -> Optional[models.User]:
    """
    Получить пользователя по email

    Args:
        db: Сессия базы данных
        email: Email пользователя

    Returns:
        User или None
    """
    return db.query(models.User).filter(models.User.email == email).first()


def get_user_roles(db: Session, user_id: int) -> list[str]:
    """
    Получить роли пользователя

    Args:
        db: Сессия базы данных
        user_id: ID пользователя

    Returns:
        Список названий ролей
    """
    user_roles = db.query(models.UserRole).filter(
        models.UserRole.user_id == user_id
    ).all()

    roles = []
    for ur in user_roles:
        role = db.query(models.Role).filter(models.Role.id == ur.role_id).first()
        if role:
            roles.append(role.name)

    return roles


async def login_user(email: str, db: Session) -> Token:
    """
    Авторизация пользователя только по email (без пароля для MVP)

    Args:
        email: Email пользователя
        db: Сессия базы данных

    Returns:
        Token с информацией о пользователе

    Raises:
        HTTPException: Если пользователь не найден или неактивен
    """
    user = get_user_by_email(db, email)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Пользователь не найден",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Пользователь неактивен",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Получаем роли пользователя
    roles = get_user_roles(db, user.id)

    # Для MVP используем email как токен
    # В production версии здесь должен быть JWT токен
    access_token = f"user_{user.id}_{user.email}"

    user_data = {
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "is_active": user.is_active,
        "roles": roles
    }

    return Token(
        access_token=access_token,
        user=user_data
    )


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> models.User:
    """
    Получить текущего авторизованного пользователя по токену

    Args:
        token: Токен авторизации
        db: Сессия базы данных

    Returns:
        User

    Raises:
        HTTPException: Если токен невалиден или пользователь не найден
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Не удалось проверить учетные данные",
        headers={"WWW-Authenticate": "Bearer"},
    )

    # Парсим токен (для MVP это просто "user_{id}_{email}")
    try:
        if not token.startswith("user_"):
            raise credentials_exception

        parts = token.split("_")
        if len(parts) < 3:
            raise credentials_exception

        user_id = int(parts[1])
        email = "_".join(parts[2:])  # На случай если в email есть _

        user = db.query(models.User).filter(
            models.User.id == user_id,
            models.User.email == email
        ).first()

        if not user:
            raise credentials_exception

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Пользователь неактивен"
            )

        return user

    except (ValueError, IndexError):
        raise credentials_exception


async def get_current_active_user(
    current_user: models.User = Depends(get_current_user)
) -> models.User:
    """
    Получить текущего активного пользователя

    Args:
        current_user: Текущий пользователь

    Returns:
        User

    Raises:
        HTTPException: Если пользователь неактивен
    """
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Пользователь неактивен"
        )
    return current_user


def check_user_role(user: models.User, required_role: str, db: Session) -> bool:
    """
    Проверить, есть ли у пользователя требуемая роль

    Args:
        user: Пользователь
        required_role: Требуемая роль (admin, teacher, student)
        db: Сессия базы данных

    Returns:
        True если роль есть, False иначе
    """
    roles = get_user_roles(db, user.id)
    return required_role in roles


async def require_role(
    required_role: str,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Dependency для проверки роли пользователя

    Args:
        required_role: Требуемая роль
        current_user: Текущий пользователь
        db: Сессия базы данных

    Raises:
        HTTPException: Если у пользователя нет требуемой роли
    """
    if not check_user_role(current_user, required_role, db):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Требуется роль: {required_role}"
        )
    return current_user
