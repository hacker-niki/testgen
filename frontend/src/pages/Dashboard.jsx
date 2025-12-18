import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import axios from 'axios'
import { useAuth } from '../context/AuthContext'
import './Dashboard.css'

function Dashboard() {
  const { user } = useAuth()
  const userRole = user?.roles?.[0]

  // Рендер разных дашбордов в зависимости от роли
  if (userRole === 'admin') {
    return <AdminDashboard />
  } else if (userRole === 'teacher') {
    return <TeacherDashboard />
  } else if (userRole === 'student') {
    return <StudentDashboard />
  }

  return <DefaultDashboard />
}

// Dashboard для администратора
function AdminDashboard() {
  const [stats, setStats] = useState({
    totalQuestions: 0,
    approvedQuestions: 0,
    totalDocuments: 0,
    totalTests: 0,
    totalUsers: 0
  })

  useEffect(() => {
    fetchStats()
  }, [])

  const fetchStats = async () => {
    try {
      const [questionsRes, documentsRes, testsRes, usersRes] = await Promise.all([
        axios.get('/api/questions'),
        axios.get('/api/documents'),
        axios.get('/api/tests'),
        axios.get('/api/auth/users')
      ])

      setStats({
        totalQuestions: questionsRes.data.total || 0,
        approvedQuestions: questionsRes.data.questions?.filter(q => q.is_approved).length || 0,
        totalDocuments: documentsRes.data.total || 0,
        totalTests: testsRes.data.total || 0,
        totalUsers: usersRes.data.length || 0
      })
    } catch (error) {
      console.error('Ошибка загрузки статистики:', error)
    }
  }

  return (
    <div className="dashboard">
      <div className="page-header">
        <h1 className="page-title">Панель администратора</h1>
        <p className="page-subtitle">Управление системой тестирования</p>
      </div>

      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon">📝</div>
          <div className="stat-info">
            <div className="stat-value">{stats.totalQuestions}</div>
            <div className="stat-label">Всего вопросов</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon">✅</div>
          <div className="stat-info">
            <div className="stat-value">{stats.approvedQuestions}</div>
            <div className="stat-label">Одобренных вопросов</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon">📄</div>
          <div className="stat-info">
            <div className="stat-value">{stats.totalDocuments}</div>
            <div className="stat-label">Документов</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon">🎯</div>
          <div className="stat-info">
            <div className="stat-value">{stats.totalTests}</div>
            <div className="stat-label">Тестов</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon">👥</div>
          <div className="stat-info">
            <div className="stat-value">{stats.totalUsers}</div>
            <div className="stat-label">Пользователей</div>
          </div>
        </div>
      </div>

      <div className="card">
        <h2>Быстрые действия</h2>
        <div style={{ marginTop: '20px', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
          <Link to="/documents" className="btn btn-primary">Загрузить документ</Link>
          <Link to="/questions" className="btn btn-secondary">Проверить вопросы</Link>
          <Link to="/tests" className="btn btn-secondary">Управление тестами</Link>
        </div>
      </div>

      <div className="card">
        <h2>О системе</h2>
        <p style={{ lineHeight: '1.8', marginTop: '15px', color: 'var(--gray-700)' }}>
          Система автоматизированного тестирования TestGen позволяет создавать тесты на основе загруженных документов.
          Вопросы генерируются автоматически с использованием нейросети и могут быть проверены и одобрены.
        </p>
      </div>
    </div>
  )
}

// Dashboard для преподавателя
function TeacherDashboard() {
  const [stats, setStats] = useState({
    totalQuestions: 0,
    approvedQuestions: 0,
    totalDocuments: 0,
    myTests: 0
  })

  useEffect(() => {
    fetchStats()
  }, [])

  const fetchStats = async () => {
    try {
      const [questionsRes, documentsRes, testsRes] = await Promise.all([
        axios.get('/api/questions'),
        axios.get('/api/documents'),
        axios.get('/api/tests')
      ])

      setStats({
        totalQuestions: questionsRes.data.total || 0,
        approvedQuestions: questionsRes.data.questions?.filter(q => q.is_approved).length || 0,
        totalDocuments: documentsRes.data.total || 0,
        myTests: testsRes.data.total || 0
      })
    } catch (error) {
      console.error('Ошибка загрузки статистики:', error)
    }
  }

  return (
    <div className="dashboard">
      <div className="page-header">
        <h1 className="page-title">Панель преподавателя</h1>
        <p className="page-subtitle">Создание и управление тестами</p>
      </div>

      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon">📝</div>
          <div className="stat-info">
            <div className="stat-value">{stats.totalQuestions}</div>
            <div className="stat-label">Вопросов в базе</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon">✅</div>
          <div className="stat-info">
            <div className="stat-value">{stats.approvedQuestions}</div>
            <div className="stat-label">Одобренных вопросов</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon">📄</div>
          <div className="stat-info">
            <div className="stat-value">{stats.totalDocuments}</div>
            <div className="stat-label">Документов</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon">🎯</div>
          <div className="stat-info">
            <div className="stat-value">{stats.myTests}</div>
            <div className="stat-label">Созданных тестов</div>
          </div>
        </div>
      </div>

      <div className="card">
        <h2>Быстрые действия</h2>
        <div style={{ marginTop: '20px', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
          <Link to="/documents" className="btn btn-primary">Загрузить документ</Link>
          <Link to="/questions" className="btn btn-secondary">Проверить вопросы</Link>
          <Link to="/tests" className="btn btn-secondary">Мои тесты</Link>
        </div>
      </div>

      <div className="card">
        <h2>Создание тестов</h2>
        <p style={{ lineHeight: '1.8', marginTop: '15px', color: 'var(--gray-700)' }}>
          Загружайте документы, проверяйте автоматически сгенерированные вопросы и создавайте тесты для студентов.
          Система автоматически генерирует вопросы с использованием нейросети.
        </p>
      </div>
    </div>
  )
}

// Dashboard для студента
function StudentDashboard() {
  const [tests, setTests] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchAvailableTests()
  }, [])

  const fetchAvailableTests = async () => {
    try {
      const response = await axios.get('/api/tests')
      // Для студентов показываем только активные тесты
      const activeTests = response.data.tests?.filter(test => test.is_active !== false) || []
      setTests(activeTests)
    } catch (error) {
      console.error('Ошибка загрузки тестов:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="dashboard">
      <div className="page-header">
        <h1 className="page-title">Панель студента</h1>
        <p className="page-subtitle">Доступные тесты для прохождения</p>
      </div>

      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon">🎯</div>
          <div className="stat-info">
            <div className="stat-value">{tests.length}</div>
            <div className="stat-label">Доступных тестов</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon">✅</div>
          <div className="stat-info">
            <div className="stat-value">0</div>
            <div className="stat-label">Пройденных тестов</div>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon">⭐</div>
          <div className="stat-info">
            <div className="stat-value">-</div>
            <div className="stat-label">Средний балл</div>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="card">
          <p style={{ textAlign: 'center', color: 'var(--gray-700)' }}>Загрузка...</p>
        </div>
      ) : tests.length > 0 ? (
        <div className="card">
          <h2>Доступные тесты</h2>
          <div style={{ marginTop: '20px' }}>
            {tests.map(test => (
              <div key={test.id} className="test-item" style={{
                padding: '20px',
                border: '1px solid var(--gray-200)',
                borderRadius: '12px',
                marginBottom: '15px',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center'
              }}>
                <div>
                  <h3 style={{ margin: '0 0 8px 0', fontSize: '18px' }}>{test.title}</h3>
                  <p style={{ margin: 0, color: 'var(--gray-700)', fontSize: '14px' }}>
                    {test.description || 'Описание отсутствует'}
                  </p>
                  <div style={{ marginTop: '8px', fontSize: '13px', color: 'var(--gray-600)' }}>
                    {test.questions_count} вопросов
                    {test.time_limit && ` • ${test.time_limit} минут`}
                    {test.passing_score && ` • Проходной балл: ${test.passing_score}%`}
                  </div>
                </div>
                <Link to={`/tests/${test.id}/take`} className="btn btn-primary">
                  Начать тест
                </Link>
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div className="card">
          <div className="empty-state">
            <h3>Нет доступных тестов</h3>
            <p>В данный момент для вас нет доступных тестов</p>
          </div>
        </div>
      )}
    </div>
  )
}

// Dashboard по умолчанию (на случай неизвестной роли)
function DefaultDashboard() {
  return (
    <div className="dashboard">
      <div className="page-header">
        <h1 className="page-title">Главная панель</h1>
        <p className="page-subtitle">Добро пожаловать в систему автоматизированного тестирования</p>
      </div>

      <div className="card">
        <h2>Добро пожаловать!</h2>
        <p style={{ lineHeight: '1.8', marginTop: '15px', color: 'var(--gray-700)' }}>
          Система автоматизированного тестирования TestGen позволяет создавать тесты на основе загруженных документов.
        </p>
      </div>
    </div>
  )
}

export default Dashboard
