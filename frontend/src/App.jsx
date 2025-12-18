import React from 'react'
import { BrowserRouter as Router, Routes, Route, Link, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import ProtectedRoute from './components/ProtectedRoute'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Documents from './pages/Documents'
import Questions from './pages/Questions'
import Tests from './pages/Tests'
import TakeTest from './pages/TakeTest'
import './App.css'

function App() {
  return (
    <Router>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/*" element={
            <ProtectedRoute>
              <AuthenticatedApp />
            </ProtectedRoute>
          } />
        </Routes>
      </AuthProvider>
    </Router>
  )
}

function AuthenticatedApp() {
  return (
    <div className="app">
      <Sidebar />
      <div className="main-content">
        <Routes>
          <Route path="/" element={<Dashboard />} />

          {/* Документы - только для admin и teacher */}
          <Route path="/documents" element={
            <ProtectedRoute allowedRoles={['admin', 'teacher']}>
              <Documents />
            </ProtectedRoute>
          } />

          {/* Вопросы - только для admin и teacher */}
          <Route path="/questions" element={
            <ProtectedRoute allowedRoles={['admin', 'teacher']}>
              <Questions />
            </ProtectedRoute>
          } />

          {/* Тесты - доступны всем */}
          <Route path="/tests" element={<Tests />} />
          <Route path="/tests/:id/take" element={<TakeTest />} />
        </Routes>
      </div>
    </div>
  )
}

function Sidebar() {
  const { user, logout } = useAuth()
  const userRole = user?.roles?.[0]

  // Проверка доступа к разделам
  const canAccessDocuments = userRole === 'admin' || userRole === 'teacher'
  const canAccessQuestions = userRole === 'admin' || userRole === 'teacher'

  return (
    <div className="sidebar">
      <div className="logo">📝 TestGen</div>

      {user && (
        <div className="user-info">
          <div className="user-avatar">
            {user.full_name?.charAt(0) || user.email.charAt(0).toUpperCase()}
          </div>
          <div className="user-details">
            <div className="user-name">{user.full_name || user.email}</div>
            <div className="user-role">{user.roles?.[0] || 'user'}</div>
          </div>
        </div>
      )}

      <nav className="nav">
        <Link to="/" className="nav-item">
          <span>🏠</span> Главная
        </Link>

        {canAccessDocuments && (
          <Link to="/documents" className="nav-item">
            <span>📄</span> Документы
          </Link>
        )}

        {canAccessQuestions && (
          <Link to="/questions" className="nav-item">
            <span>❓</span> Вопросы
          </Link>
        )}

        <Link to="/tests" className="nav-item">
          <span>📝</span> Тесты
        </Link>
      </nav>

      <button className="logout-button" onClick={logout}>
        <span>🚪</span> Выйти
      </button>
    </div>
  )
}

export default App
