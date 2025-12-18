import React, { useState, useEffect } from 'react'
import axios from 'axios'
import './Questions.css'

function Questions() {
  const [questions, setQuestions] = useState([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('pending') // 'pending' or 'approved'

  useEffect(() => {
    fetchQuestions()
  }, [filter])

  const fetchQuestions = async () => {
    try {
      const response = await axios.get(`/api/questions?approved_only=${filter === 'approved'}`)
      setQuestions(response.data.questions)
    } catch (error) {
      console.error('Ошибка загрузки вопросов:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleApprove = async (questionId) => {
    try {
      await axios.post(`/api/questions/${questionId}/approve`)
      fetchQuestions()
    } catch (error) {
      console.error('Ошибка одобрения вопроса:', error)
    }
  }

  const handleDelete = async (questionId) => {
    if (!window.confirm('Вы уверены, что хотите удалить этот вопрос?')) return

    try {
      await axios.delete(`/api/questions/${questionId}`)
      fetchQuestions()
    } catch (error) {
      console.error('Ошибка удаления вопроса:', error)
    }
  }

  return (
    <div className="questions-page">
      <div className="page-header">
        <h1 className="page-title">Вопросы</h1>
        <p className="page-subtitle">Проверка и одобрение сгенерированных вопросов</p>
      </div>

      <div className="filter-tabs">
        <button
          className={`filter-tab ${filter === 'pending' ? 'active' : ''}`}
          onClick={() => setFilter('pending')}
        >
          На проверке
        </button>
        <button
          className={`filter-tab ${filter === 'approved' ? 'active' : ''}`}
          onClick={() => setFilter('approved')}
        >
          Одобренные
        </button>
      </div>

      {loading ? (
        <div className="loading">Загрузка вопросов...</div>
      ) : questions.length === 0 ? (
        <div className="empty-state">
          <h3>Нет вопросов</h3>
          <p>В этой категории пока нет вопросов</p>
        </div>
      ) : (
        <div className="questions-list">
          {questions.map((question, index) => (
            <div key={question.id} className="question-card">
              <div className="question-header">
                <span className="question-number">Вопрос {index + 1}</span>
                {question.is_approved && (
                  <span className="status-badge processed">Одобрен</span>
                )}
              </div>

              <div className="question-text">{question.question}</div>

              <div className="answers-list">
                {question.answers.map((answer, idx) => (
                  <div
                    key={idx}
                    className={`answer-item ${answer.is_correct ? 'correct' : ''}`}
                  >
                    <span className="answer-label">
                      {answer.is_correct && '✓ '}
                      {String.fromCharCode(65 + idx)}.
                    </span>
                    <span className="answer-text">{answer.text}</span>
                  </div>
                ))}
              </div>

              <div className="question-actions">
                {!question.is_approved && (
                  <button
                    className="btn btn-success"
                    onClick={() => handleApprove(question.id)}
                  >
                    Одобрить
                  </button>
                )}
                <button
                  className="btn btn-danger"
                  onClick={() => handleDelete(question.id)}
                >
                  Удалить
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default Questions
