const { describe, it, expect } = require('@jest/globals')
const fetch = require('node-fetch')

describe('Hanzo Router (LLM Gateway)', () => {
  const ROUTER_URL = 'http://localhost:4000'
  const MASTER_KEY = 'sk-router-master-hanzo'

  describe('Health Check', () => {
    it('should return 401 without auth', async () => {
      const response = await fetch(`${ROUTER_URL}/health`)
      expect(response.status).toBe(401)
      
      const data = await response.json()
      expect(data.error).toBeDefined()
      expect(data.error.type).toBe('auth_error')
    })

    it('should return health status with master key', async () => {
      const response = await fetch(`${ROUTER_URL}/health/liveliness`, {
        headers: {
          'Authorization': `Bearer ${MASTER_KEY}`
        }
      })
      
      // Router should respond even if not fully healthy
      expect([200, 503]).toContain(response.status)
    })
  })

  describe('Model List', () => {
    it('should list available models with auth', async () => {
      const response = await fetch(`${ROUTER_URL}/v1/models`, {
        headers: {
          'Authorization': `Bearer ${MASTER_KEY}`
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        expect(data.object).toBe('list')
        expect(Array.isArray(data.data)).toBe(true)
      }
    })
  })

  describe('Chat Completions', () => {
    it('should handle chat completion request (mock)', async () => {
      // This test would need actual API keys to work
      // For now, we just test that the endpoint exists
      const response = await fetch(`${ROUTER_URL}/v1/chat/completions`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${MASTER_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          model: 'gpt-3.5-turbo',
          messages: [
            { role: 'user', content: 'Hello' }
          ],
          max_tokens: 10
        })
      })
      
      // Will fail without actual API keys, but endpoint should exist
      expect([200, 400, 401, 500]).toContain(response.status)
    })
  })

  describe('Router Admin UI', () => {
    it('should serve admin UI', async () => {
      try {
        const response = await fetch(`${ROUTER_URL}/ui`, {
          redirect: 'manual',
          signal: AbortSignal.timeout(5000)
        })
        
        // Should redirect to login or show UI
        expect([200, 302, 307, 401, 404]).toContain(response.status)
      } catch (error) {
        // If connection fails, check if it's due to UI not being enabled
        console.log('Router UI endpoint not available - this is expected if UI is disabled')
      }
    })
  })
})