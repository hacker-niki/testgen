import React from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

function ProtectedRoute({ children, allowedRoles }) {
  const { isAuthenticated, loading, user } = useAuth()

  if (loading) {
    return (
      <div style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        height: '100vh',
        fontSize: '18px',
        color: '#666'
      }}>
        Загрузка...
      </div>
    )
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  // Проверка ролей, если указаны allowedRoles
  if (allowedRoles && allowedRoles.length > 0) {
    const userRoles = user?.roles || []
    const hasRequiredRole = allowedRoles.some(role => userRoles.includes(role))

    if (!hasRequiredRole) {
      // Если у пользователя нет нужной роли, редирект на главную
      return <Navigate to="/" replace />
    }
  }

  return children
}

export default ProtectedRoute
