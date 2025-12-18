import React, { useState, useEffect } from 'react'
import axios from 'axios'
import './Documents.css'

function Documents() {
  const [documents, setDocuments] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchDocuments()
  }, [])

  const fetchDocuments = async () => {
    try {
      const response = await axios.get('/api/documents')
      setDocuments(response.data.documents)
    } catch (error) {
      console.error('Ошибка загрузки документов:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="documents-page">
      <div className="page-header">
        <h1 className="page-title">Документы</h1>
        <p className="page-subtitle">Управление загруженными документами</p>
      </div>

      <div className="card" style={{ marginBottom: '30px' }}>
        <h3 style={{ marginBottom: '15px' }}>Загрузить новый документ</h3>
        <div style={{ display: 'flex', gap: '15px', alignItems: 'center' }}>
          <input type="file" style={{ flex: 1 }} disabled />
          <button className="btn btn-primary" disabled>
            Загрузить
          </button>
        </div>
        <p style={{ marginTop: '10px', fontSize: '0.9rem', color: 'var(--gray-700)' }}>
          (MVP версия - функционал загрузки отключен)
        </p>
      </div>

      {loading ? (
        <div className="loading">Загрузка...</div>
      ) : (
        <div className="documents-list">
          {documents.map(doc => (
            <div key={doc.id} className="document-card">
              <div className="doc-icon">📄</div>
              <div className="doc-info">
                <div className="doc-name">{doc.name}</div>
                <div className="doc-meta">
                  <span className={`status-badge ${doc.status}`}>
                    {doc.status === 'processed' ? 'Обработан' : 'Обрабатывается'}
                  </span>
                  <span style={{ color: 'var(--gray-700)' }}>
                    {doc.questions_count} вопросов
                  </span>
                </div>
                <div className="doc-date">
                  Загружен: {new Date(doc.uploaded_at).toLocaleString('ru-RU')}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default Documents
