import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import axios from 'axios'
import './Tests.css'

function Tests() {
  const [tests, setTests] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchTests()
  }, [])

  const fetchTests = async () => {
    try {
      const response = await axios.get('/api/tests')
      setTests(response.data.tests)
    } catch (error) {
      console.error('Ошибка загрузки тестов:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="tests-page">
      <div className="page-header">
        <h1 className="page-title">Тесты</h1>
        <p className="page-subtitle">Доступные тесты для прохождения</p>
      </div>

      {loading ? (
        <div className="loading">Загрузка тестов...</div>
      ) : (
        <div className="tests-grid">
          {tests.map(test => (
            <div key={test.id} className="test-card">
              <div className="test-header">
                <h3>{test.title}</h3>
              </div>

              <p className="test-description">{test.description}</p>

              <div className="test-stats">
                <div className="test-stat">
                  <span className="stat-icon">❓</span>
                  <span>{test.questions_count} вопросов</span>
                </div>
                <div className="test-stat">
                  <span className="stat-icon">⏱️</span>
                  <span>{test.time_limit} минут</span>
                </div>
                <div className="test-stat">
                  <span className="stat-icon">🎯</span>
                  <span>Проходной балл: {test.passing_score}%</span>
                </div>
              </div>

              <div className="test-footer">
                <span className="test-date">
                  Создан: {new Date(test.created_at).toLocaleDateString('ru-RU')}
                </span>
                <Link to={`/tests/${test.id}/take`} className="btn btn-primary">
                  Начать тест
                </Link>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default Tests
