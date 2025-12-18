"""
SQLAlchemy модели для системы TestGen.
Соответствуют структуре таблиц в БД MariaDB.
"""

from sqlalchemy import (
    Column, Integer, BigInteger, String, Text, Boolean,
    TIMESTAMP, Enum, DECIMAL, ForeignKey, Index, CheckConstraint,
    func
)
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime
import enum


# =====================================================
# ENUM-типы
# =====================================================

class DocumentStatus(str, enum.Enum):
    """Статусы обработки документов"""
    pending = "pending"
    processing = "processing"
    completed = "completed"
    failed = "failed"


class Difficulty(str, enum.Enum):
    """Уровни сложности вопросов"""
    easy = "easy"
    medium = "medium"
    hard = "hard"


class SessionStatus(str, enum.Enum):
    """Статусы сессий тестирования"""
    in_progress = "in_progress"
    completed = "completed"
    abandoned = "abandoned"


class AuditOperationType(str, enum.Enum):
    """Типы операций в журнале аудита"""
    INSERT = "INSERT"
    UPDATE = "UPDATE"
    DELETE = "DELETE"


# =====================================================
# ОСНОВНЫЕ МОДЕЛИ
# =====================================================

class Role(Base):
    """Модель роли пользователя"""
    __tablename__ = "roles"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(50), unique=True, nullable=False, comment="Название роли")
    description = Column(String(255), comment="Описание роли")
    created_at = Column(TIMESTAMP, nullable=False, server_default=func.current_timestamp())

    # Relationships
    user_roles = relationship("UserRole", back_populates="role", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Role(id={self.id}, name='{self.name}')>"


class User(Base):
    """Модель пользователя системы"""
    __tablename__ = "users"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    full_name = Column(String(255), nullable=False, comment="Полное имя пользователя")
    email = Column(String(255), unique=True, nullable=False, comment="Email для входа")
    password_hash = Column(String(255), nullable=False, comment="Хэш пароля (bcrypt)")
    is_active = Column(Boolean, nullable=False, default=True, comment="Активен ли аккаунт")
    created_at = Column(TIMESTAMP, nullable=False, server_default=func.current_timestamp())
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=func.current_timestamp(),
        onupdate=func.current_timestamp()
    )

    # Relationships
    user_roles = relationship("UserRole", back_populates="user", cascade="all, delete-orphan")
    user_groups = relationship("UserGroup", back_populates="user", cascade="all, delete-orphan")
    created_groups = relationship("Group", back_populates="creator", foreign_keys="Group.created_by")
    uploaded_documents = relationship("SourceDocument", back_populates="uploader")
    created_questions = relationship("Question", back_populates="creator", foreign_keys="Question.creator_id")
    approved_questions = relationship("Question", back_populates="approver", foreign_keys="Question.approved_by")
    created_tests = relationship("Test", back_populates="creator")
    assigned_tests_by = relationship("TestAssignment", back_populates="assigner", foreign_keys="TestAssignment.assigned_by")
    test_sessions = relationship("TestSession", back_populates="user")
    audit_logs = relationship("AuditLog", back_populates="user")

    __table_args__ = (
        Index('idx_email', 'email'),
        Index('idx_is_active', 'is_active'),
    )

    def __repr__(self):
        return f"<User(id={self.id}, email='{self.email}', name='{self.full_name}')>"


class UserRole(Base):
    """Связь пользователей и ролей (многие ко многим)"""
    __tablename__ = "user_roles"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    user_id = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    role_id = Column(Integer, ForeignKey("roles.id", ondelete="CASCADE"), nullable=False)
    assigned_at = Column(TIMESTAMP, nullable=False, server_default=func.current_timestamp())

    # Relationships
    user = relationship("User", back_populates="user_roles")
    role = relationship("Role", back_populates="user_roles")

    __table_args__ = (
        Index('idx_user_id', 'user_id'),
        Index('idx_role_id', 'role_id'),
        Index('unique_user_role', 'user_id', 'role_id', unique=True),
    )


class Group(Base):
    """Модель группы пользователей"""
    __tablename__ = "groups"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False, comment="Название группы/отдела")
    description = Column(Text, comment="Описание группы")
    created_by = Column(BigInteger, ForeignKey("users.id", ondelete="SET NULL"), comment="Кто создал группу")
    created_at = Column(TIMESTAMP, nullable=False, server_default=func.current_timestamp())
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=func.current_timestamp(),
        onupdate=func.current_timestamp()
    )

    # Relationships
    creator = relationship("User", back_populates="created_groups", foreign_keys=[created_by])
    user_groups = relationship("UserGroup", back_populates="group", cascade="all, delete-orphan")
    test_assignments = relationship("TestAssignment", back_populates="group")

    __table_args__ = (
        Index('idx_name', 'name'),
        Index('idx_created_by', 'created_by'),
    )

    def __repr__(self):
        return f"<Group(id={self.id}, name='{self.name}')>"


class UserGroup(Base):
    """Связь пользователей и групп (многие ко многим)"""
    __tablename__ = "user_groups"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    user_id = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    group_id = Column(BigInteger, ForeignKey("groups.id", ondelete="CASCADE"), nullable=False)
    joined_at = Column(TIMESTAMP, nullable=False, server_default=func.current_timestamp())

    # Relationships
    user = relationship("User", back_populates="user_groups")
    group = relationship("Group", back_populates="user_groups")

    __table_args__ = (
        Index('idx_user_id', 'user_id'),
        Index('idx_group_id', 'group_id'),
        Index('unique_user_group', 'user_id', 'group_id', unique=True),
    )


class SourceDocument(Base):
    """Модель исходного документа для генерации вопросов"""
    __tablename__ = "source_documents"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    filename = Column(String(255), nullable=False, comment="Оригинальное имя файла")
    file_path = Column(String(500), comment="Путь к файлу на сервере")
    file_size = Column(BigInteger, comment="Размер файла в байтах")
    mime_type = Column(String(100), comment="MIME-тип файла")
    status = Column(
        Enum(DocumentStatus),
        nullable=False,
        default=DocumentStatus.pending,
        comment="Статус обработки"
    )
    error_message = Column(Text, comment="Сообщение об ошибке при обработке")
    uploader_id = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(TIMESTAMP, nullable=False, server_default=func.current_timestamp())
    processed_at = Column(TIMESTAMP, comment="Время завершения обработки")

    # Relationships
    uploader = relationship("User", back_populates="uploaded_documents")
    questions = relationship("Question", back_populates="source_document")

    __table_args__ = (
        Index('idx_status', 'status'),
        Index('idx_uploader_id', 'uploader_id'),
        Index('idx_created_at', 'created_at'),
    )

    def __repr__(self):
        return f"<SourceDocument(id={self.id}, filename='{self.filename}', status='{self.status}')>"


class Question(Base):
    """Модель вопроса"""
    __tablename__ = "questions"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    question_text = Column(Text, nullable=False, comment="Текст вопроса")
    source_document_id = Column(
        BigInteger,
        ForeignKey("source_documents.id", ondelete="SET NULL"),
        comment="Ссылка на документ (NULL для ручного создания)"
    )
    creator_id = Column(
        BigInteger,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        comment="Кто создал/инициировал генерацию вопроса"
    )
    is_approved = Column(Boolean, nullable=False, default=False, comment="Одобрен ли вопрос")
    approved_by = Column(BigInteger, ForeignKey("users.id", ondelete="SET NULL"), comment="Кто одобрил вопрос")
    approved_at = Column(TIMESTAMP, comment="Когда одобрен")

    # Moodle интеграция
    moodle_name = Column(String(255), comment="Название вопроса в Moodle")
    moodle_question_id = Column(BigInteger, comment="ID вопроса в Moodle")
    default_grade = Column(DECIMAL(10, 7), default=1.0, comment="Оценка по умолчанию")
    penalty = Column(DECIMAL(10, 7), default=0.3333333, comment="Штраф за неправильный ответ")
    shuffle_answers = Column(Boolean, default=True, comment="Перемешивать ответы")

    created_at = Column(TIMESTAMP, nullable=False, server_default=func.current_timestamp())
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=func.current_timestamp(),
        onupdate=func.current_timestamp()
    )

    # Relationships
    source_document = relationship("SourceDocument", back_populates="questions")
    creator = relationship("User", back_populates="created_questions", foreign_keys=[creator_id])
    approver = relationship("User", back_populates="approved_questions", foreign_keys=[approved_by])
    answer_options = relationship("AnswerOption", back_populates="question", cascade="all, delete-orphan")
    test_questions = relationship("TestQuestion", back_populates="question")
    user_answers = relationship("UserAnswer", back_populates="question")

    __table_args__ = (
        Index('idx_source_document_id', 'source_document_id'),
        Index('idx_creator_id', 'creator_id'),
        Index('idx_is_approved', 'is_approved'),
    )

    def __repr__(self):
        return f"<Question(id={self.id}, approved={self.is_approved})>"


class AnswerOption(Base):
    """Модель варианта ответа на вопрос"""
    __tablename__ = "answer_options"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    question_id = Column(
        BigInteger,
        ForeignKey("questions.id", ondelete="CASCADE"),
        nullable=False,
        comment="Вопрос, к которому относится ответ"
    )
    answer_text = Column(Text, nullable=False, comment="Текст варианта ответа")
    is_correct = Column(Boolean, nullable=False, default=False, comment="Является ли ответ правильным")
    option_order = Column(Integer, nullable=False, comment="Порядок отображения (1-5)")
    created_at = Column(TIMESTAMP, nullable=False, server_default=func.current_timestamp())

    # Relationships
    question = relationship("Question", back_populates="answer_options")
    user_answers = relationship("UserAnswer", back_populates="selected_option")

    __table_args__ = (
        Index('idx_question_id', 'question_id'),
        Index('idx_is_correct', 'is_correct'),
    )

    def __repr__(self):
        return f"<AnswerOption(id={self.id}, question_id={self.question_id}, is_correct={self.is_correct})>"


class Test(Base):
    """Модель теста"""
    __tablename__ = "tests"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    title = Column(String(255), nullable=False, comment="Название теста")
    description = Column(Text, comment="Описание теста")
    time_limit_minutes = Column(Integer, comment="Ограничение по времени в минутах")
    passing_score = Column(DECIMAL(5, 2), nullable=False, default=70.00, comment="Проходной балл в процентах")
    max_attempts = Column(Integer, comment="Максимальное количество попыток (NULL = без ограничений)")
    shuffle_questions = Column(Boolean, nullable=False, default=True, comment="Перемешивать вопросы")
    shuffle_answers = Column(Boolean, nullable=False, default=True, comment="Перемешивать варианты ответов")
    show_results = Column(Boolean, nullable=False, default=True, comment="Показывать результаты сразу")
    show_correct_answers = Column(Boolean, nullable=False, default=False, comment="Показывать правильные ответы")
    is_active = Column(Boolean, nullable=False, default=True, comment="Активен ли тест")
    creator_id = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(TIMESTAMP, nullable=False, server_default=func.current_timestamp())
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=func.current_timestamp(),
        onupdate=func.current_timestamp()
    )

    # Relationships
    creator = relationship("User", back_populates="created_tests")
    test_questions = relationship("TestQuestion", back_populates="test", cascade="all, delete-orphan")
    test_assignments = relationship("TestAssignment", back_populates="test")
    test_sessions = relationship("TestSession", back_populates="test")

    __table_args__ = (
        Index('idx_is_active', 'is_active'),
        Index('idx_creator_id', 'creator_id'),
        Index('idx_created_at', 'created_at'),
    )

    def __repr__(self):
        return f"<Test(id={self.id}, title='{self.title}', active={self.is_active})>"


class TestQuestion(Base):
    """Связь тестов и вопросов (многие ко многим)"""
    __tablename__ = "test_questions"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    test_id = Column(BigInteger, ForeignKey("tests.id", ondelete="CASCADE"), nullable=False)
    question_id = Column(BigInteger, ForeignKey("questions.id", ondelete="CASCADE"), nullable=False)
    question_order = Column(Integer, nullable=False, comment="Порядок вопроса в тесте")
    points = Column(DECIMAL(5, 2), nullable=False, default=1.00, comment="Баллы за правильный ответ")

    # Relationships
    test = relationship("Test", back_populates="test_questions")
    question = relationship("Question", back_populates="test_questions")

    __table_args__ = (
        Index('idx_test_id', 'test_id'),
        Index('idx_question_id', 'question_id'),
        Index('unique_test_question', 'test_id', 'question_id', unique=True),
    )


class TestAssignment(Base):
    """Модель назначения теста пользователю или группе"""
    __tablename__ = "test_assignments"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    test_id = Column(BigInteger, ForeignKey("tests.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(
        BigInteger,
        ForeignKey("users.id", ondelete="CASCADE"),
        comment="Назначение конкретному пользователю"
    )
    group_id = Column(
        BigInteger,
        ForeignKey("groups.id", ondelete="CASCADE"),
        comment="Назначение группе"
    )
    assigned_by = Column(
        BigInteger,
        ForeignKey("users.id", ondelete="SET NULL"),
        comment="Кто назначил тест"
    )
    assigned_at = Column(TIMESTAMP, nullable=False, server_default=func.current_timestamp())
    deadline = Column(TIMESTAMP, comment="Крайний срок прохождения")
    is_completed = Column(Boolean, nullable=False, default=False, comment="Завершено ли назначение")

    # Relationships
    test = relationship("Test", back_populates="test_assignments")
    assigner = relationship("User", back_populates="assigned_tests_by", foreign_keys=[assigned_by])
    group = relationship("Group", back_populates="test_assignments")
    test_sessions = relationship("TestSession", back_populates="assignment")

    __table_args__ = (
        Index('idx_test_id', 'test_id'),
        Index('idx_user_id', 'user_id'),
        Index('idx_group_id', 'group_id'),
        Index('idx_deadline', 'deadline'),
        CheckConstraint('(user_id IS NOT NULL) OR (group_id IS NOT NULL)', name='chk_assignment_target'),
    )


class TestSession(Base):
    """Модель сессии прохождения теста"""
    __tablename__ = "test_sessions"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    test_id = Column(BigInteger, ForeignKey("tests.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    assignment_id = Column(
        BigInteger,
        ForeignKey("test_assignments.id", ondelete="SET NULL"),
        comment="Связь с назначением теста"
    )
    status = Column(
        Enum(SessionStatus),
        nullable=False,
        default=SessionStatus.in_progress
    )
    started_at = Column(TIMESTAMP, nullable=False, server_default=func.current_timestamp())
    completed_at = Column(TIMESTAMP)
    time_spent_seconds = Column(Integer, comment="Время прохождения в секундах")
    score = Column(DECIMAL(5, 2), comment="Итоговый балл в процентах")
    total_questions = Column(Integer, nullable=False, comment="Общее количество вопросов")
    correct_answers = Column(Integer, default=0, comment="Количество правильных ответов")
    is_passed = Column(Boolean, comment="Пройден ли тест")

    # Relationships
    test = relationship("Test", back_populates="test_sessions")
    user = relationship("User", back_populates="test_sessions")
    assignment = relationship("TestAssignment", back_populates="test_sessions")
    user_answers = relationship("UserAnswer", back_populates="test_session", cascade="all, delete-orphan")

    __table_args__ = (
        Index('idx_test_id', 'test_id'),
        Index('idx_user_id', 'user_id'),
        Index('idx_status', 'status'),
        Index('idx_started_at', 'started_at'),
    )

    def __repr__(self):
        return f"<TestSession(id={self.id}, test_id={self.test_id}, user_id={self.user_id}, status='{self.status}')>"


class UserAnswer(Base):
    """Модель ответа пользователя на вопрос"""
    __tablename__ = "user_answers"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    test_session_id = Column(
        BigInteger,
        ForeignKey("test_sessions.id", ondelete="CASCADE"),
        nullable=False,
        comment="Сессия тестирования"
    )
    question_id = Column(
        BigInteger,
        ForeignKey("questions.id", ondelete="CASCADE"),
        nullable=False,
        comment="Вопрос"
    )
    selected_option_id = Column(
        BigInteger,
        ForeignKey("answer_options.id", ondelete="CASCADE"),
        nullable=False,
        comment="Выбранный вариант ответа"
    )
    is_correct = Column(Boolean, nullable=False, comment="Правильный ли ответ")
    answered_at = Column(TIMESTAMP, nullable=False, server_default=func.current_timestamp())

    # Relationships
    test_session = relationship("TestSession", back_populates="user_answers")
    question = relationship("Question", back_populates="user_answers")
    selected_option = relationship("AnswerOption", back_populates="user_answers")

    __table_args__ = (
        Index('idx_test_session_id', 'test_session_id'),
        Index('idx_question_id', 'question_id'),
        Index('idx_selected_option_id', 'selected_option_id'),
        Index('unique_session_question', 'test_session_id', 'question_id', unique=True),
    )


# =====================================================
# СИСТЕМА АУДИТА
# =====================================================

class AuditLog(Base):
    """Модель журнала аудита"""
    __tablename__ = "audit_log"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    table_name = Column(String(64), nullable=False, comment="Название таблицы")
    operation_type = Column(Enum(AuditOperationType), nullable=False, comment="Тип операции")
    record_id = Column(BigInteger, nullable=False, comment="ID измененной записи")
    old_values = Column(Text, comment="Старые значения (JSON)")
    new_values = Column(Text, comment="Новые значения (JSON)")
    user_id = Column(BigInteger, ForeignKey("users.id", ondelete="SET NULL"), comment="Пользователь")
    changed_at = Column(TIMESTAMP, nullable=False, server_default=func.current_timestamp())

    # Relationships
    user = relationship("User", back_populates="audit_logs")

    __table_args__ = (
        Index('idx_table_record', 'table_name', 'record_id'),
        Index('idx_operation_date', 'operation_type', 'changed_at'),
        Index('idx_user', 'user_id'),
    )

    def __repr__(self):
        return f"<AuditLog(id={self.id}, table='{self.table_name}', operation='{self.operation_type}')>"
