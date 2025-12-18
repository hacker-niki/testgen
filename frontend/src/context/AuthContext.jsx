import React, { createContext, useState, useContext, useEffect } from 'react'
import axios from 'axios'

const AuthContext = createContext(null)

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return context
}

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null)
  const [token, setToken] = useState(localStorage.getItem('token'))
  const [loading, setLoading] = useState(true)

  // Настройка axios interceptor для добавления токена к запросам
  useEffect(() => {
    if (token) {
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`
    } else {
      delete axios.defaults.headers.common['Authorization']
    }
  }, [token])

  // Загрузка данных пользователя при монтировании
  useEffect(() => {
    const loadUser = async () => {
      if (token) {
        try {
          const response = await axios.get('http://localhost:8000/api/auth/me')
          setUser(response.data)
        } catch (error) {
          console.error('Ошибка загрузки пользователя:', error)
          logout()
        }
      }
      setLoading(false)
    }

    loadUser()
  }, [token])

  const login = async (email) => {
    try {
      const response = await axios.post('http://localhost:8000/api/auth/login', {
        email
      })

      const { access_token, user: userData } = response.data

      setToken(access_token)
      setUser(userData)
      localStorage.setItem('token', access_token)

      return { success: true }
    } catch (error) {
      console.error('Ошибка авторизации:', error)
      return {
        success: false,
        error: error.response?.data?.detail || 'Ошибка авторизации'
      }
    }
  }

  const logout = () => {
    setUser(null)
    setToken(null)
    localStorage.removeItem('token')
    delete axios.defaults.headers.common['Authorization']
  }

  const value = {
    user,
    token,
    loading,
    login,
    logout,
    isAuthenticated: !!user
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}
