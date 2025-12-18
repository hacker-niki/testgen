import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import './Login.css'

function Login() {
  const [email, setEmail] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const { login } = useAuth()
  const navigate = useNavigate()

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    if (!email) {
      setError('Введите email')
      setLoading(false)
      return
    }

    const result = await login(email)

    if (result.success) {
      navigate('/')
    } else {
      setError(result.error)
    }

    setLoading(false)
  }

  const testUsers = [
    { email: 'admin@testgen.com', role: 'Администратор' },
    { email: 'teacher@testgen.com', role: 'Преподаватель' },
    { email: 'student1@testgen.com', role: 'Студент 1' },
    { email: 'student2@testgen.com', role: 'Студент 2' }
  ]

  return (
    <div className="login-container">
      <div className="login-card">
        <div className="login-header">
          <h1>📝 TestGen</h1>
          <p>Система автоматизированного тестирования</p>
        </div>

        <form onSubmit={handleSubmit} className="login-form">
          <div className="form-group">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Введите ваш email"
              disabled={loading}
              autoFocus
            />
          </div>

          {error && (
            <div className="error-message">
              {error}
            </div>
          )}

          <button
            type="submit"
            className="login-button"
            disabled={loading}
          >
            {loading ? 'Вход...' : 'Войти'}
          </button>
        </form>

        <div className="test-users">
          <p className="test-users-title">Тестовые пользователи:</p>
          <div className="test-users-list">
            {testUsers.map((user) => (
              <button
                key={user.email}
                className="test-user-button"
                onClick={() => setEmail(user.email)}
                disabled={loading}
              >
                <span className="test-user-role">{user.role}</span>
                <span className="test-user-email">{user.email}</span>
              </button>
            ))}
          </div>
        </div>

        <div className="login-info">
          <p>
            <strong>MVP версия:</strong> Авторизация только по email без пароля
          </p>
        </div>
      </div>
    </div>
  )
}

export default Login
