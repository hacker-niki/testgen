import React, { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import axios from 'axios'
import './TakeTest.css'

function TakeTest() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [test, setTest] = useState(null)
  const [questions, setQuestions] = useState([])
  const [currentQuestion, setCurrentQuestion] = useState(0)
  const [answers, setAnswers] = useState({})
  const [timeLeft, setTimeLeft] = useState(0)
  const [showResult, setShowResult] = useState(false)
  const [score, setScore] = useState(0)

  useEffect(() => {
    fetchTest()
  }, [id])

  useEffect(() => {
    if (timeLeft > 0 && !showResult) {
      const timer = setTimeout(() => setTimeLeft(timeLeft - 1), 1000)
      return () => clearTimeout(timer)
    } else if (timeLeft === 0 && test && !showResult) {
      handleSubmit()
    }
  }, [timeLeft, showResult])

  const fetchTest = async () => {
    try {
      const [testRes, questionsRes] = await Promise.all([
        axios.get(`/api/tests/${id}`),
        axios.get(`/api/tests/${id}/questions`)
      ])

      setTest(testRes.data)
      setQuestions(questionsRes.data.questions)
      setTimeLeft(testRes.data.time_limit * 60) // Конвертируем минуты в секунды
    } catch (error) {
      console.error('Ошибка загрузки теста:', error)
    }
  }

  const handleAnswer = (questionId, answerIndex) => {
    setAnswers({ ...answers, [questionId]: answerIndex })
  }

  const handleNext = () => {
    if (currentQuestion < questions.length - 1) {
      setCurrentQuestion(currentQuestion + 1)
    }
  }

  const handlePrev = () => {
    if (currentQuestion > 0) {
      setCurrentQuestion(currentQuestion - 1)
    }
  }

  const handleSubmit = () => {
    // Подсчитываем результат
    let correctAnswers = 0
    questions.forEach((question) => {
      const userAnswer = answers[question.id]
      const correctAnswerIndex = question.answers.findIndex(a => a.is_correct)

      if (userAnswer === correctAnswerIndex) {
        correctAnswers++
      }
    })

    const scorePercentage = Math.round((correctAnswers / questions.length) * 100)
    setScore(scorePercentage)
    setShowResult(true)
  }

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }

  if (!test || questions.length === 0) {
    return <div className="loading">Загрузка теста...</div>
  }

  if (showResult) {
    const passed = score >= test.passing_score

    return (
      <div className="test-result">
        <div className="result-card">
          <div className={`result-icon ${passed ? 'success' : 'fail'}`}>
            {passed ? '🎉' : '😔'}
          </div>
          <h1 className="result-title">
            {passed ? 'Поздравляем!' : 'Тест не пройден'}
          </h1>
          <div className="result-score">
            <div className="score-value">{score}%</div>
            <div className="score-label">
              Правильных ответов: {Math.round(questions.length * score / 100)} из {questions.length}
            </div>
          </div>
          <div className="result-info">
            <p>Проходной балл: {test.passing_score}%</p>
            {passed ? (
              <p>Вы успешно прошли тест!</p>
            ) : (
              <p>Для прохождения теста необходимо набрать минимум {test.passing_score}%</p>
            )}
          </div>
          <button className="btn btn-primary" onClick={() => navigate('/tests')}>
            Вернуться к тестам
          </button>
        </div>
      </div>
    )
  }

  const question = questions[currentQuestion]
  const progress = ((currentQuestion + 1) / questions.length) * 100

  return (
    <div className="take-test">
      <div className="test-header">
        <div className="test-title">
          {test.title} - Вопрос {currentQuestion + 1} из {questions.length}
        </div>
        <div className="timer">
          <span style={{ color: 'var(--gray-700)' }}>Осталось времени:</span>
          <span className="timer-value">⏱️ {formatTime(timeLeft)}</span>
        </div>
      </div>

      <div className="progress-bar">
        <div className="progress-fill" style={{ width: `${progress}%` }}></div>
      </div>

      <div className="container">
        <div className="question-card">
          <div className="question-number">Вопрос {currentQuestion + 1}</div>
          <div className="question-text">{question.question}</div>

          <div className="options">
            {question.answers.map((answer, idx) => (
              <label key={idx} className="option">
                <input
                  type="radio"
                  name={`q${question.id}`}
                  checked={answers[question.id] === idx}
                  onChange={() => handleAnswer(question.id, idx)}
                />
                <span className="option-text">{answer.text}</span>
              </label>
            ))}
          </div>
        </div>

        <div className="nav-buttons">
          <button
            className="btn btn-secondary"
            onClick={handlePrev}
            disabled={currentQuestion === 0}
          >
            ← Предыдущий
          </button>
          {currentQuestion === questions.length - 1 ? (
            <button className="btn btn-primary" onClick={handleSubmit}>
              Завершить тест
            </button>
          ) : (
            <button className="btn btn-primary" onClick={handleNext}>
              Следующий →
            </button>
          )}
        </div>

        <div className="question-nav">
          {questions.map((q, idx) => (
            <div
              key={q.id}
              className={`q-num ${answers[q.id] !== undefined ? 'answered' : ''} ${
                idx === currentQuestion ? 'current' : ''
              }`}
              onClick={() => setCurrentQuestion(idx)}
            >
              {idx + 1}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

export default TakeTest
