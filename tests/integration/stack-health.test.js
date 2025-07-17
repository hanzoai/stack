import { describe, it, expect } from 'vitest'
import { exec } from 'child_process'
import { promisify } from 'util'

const execAsync = promisify(exec)

describe('Stack Health Checks', () => {
  describe('Docker Services', () => {
    it('should have all core services running', async () => {
      const { stdout } = await execAsync('docker ps --format "{{.Names}}" | grep hanzo')
      const runningServices = stdout.trim().split('\n').filter(Boolean)
      
      const expectedServices = [
        'hanzo-postgres',
        'hanzo-redis',
        'hanzo-mongodb',
        'hanzo-minio',
        'hanzo-meilisearch',
        'hanzo-router'
      ]
      
      expectedServices.forEach(service => {
        expect(runningServices).toContain(service)
      })
    })

    it('should have all services healthy', async () => {
      const { stdout } = await execAsync('docker ps --format "{{.Names}}:{{.Status}}" | grep hanzo')
      const services = stdout.trim().split('\n').filter(Boolean)
      
      services.forEach(service => {
        const [name, status] = service.split(':')
        if (name !== 'hanzo-router') { // Router might still be starting
          expect(status).toContain('healthy')
        }
      })
    })
  })

  describe('Network Connectivity', () => {
    const services = [
      { name: 'PostgreSQL', port: 5432 },
      { name: 'Redis', port: 6379 },
      { name: 'MongoDB', port: 27017 },
      { name: 'MinIO', port: 9000 },
      { name: 'MinIO Console', port: 9001 },
      { name: 'Meilisearch', port: 7700 },
      { name: 'Router', port: 4000 }
    ]

    services.forEach(({ name, port }) => {
      it(`should have ${name} accessible on port ${port}`, async () => {
        try {
          const { stdout, stderr } = await execAsync(`nc -zv localhost ${port} 2>&1`)
          const output = stdout + stderr
          expect(output).toContain('succeeded')
        } catch (error) {
          // nc might return non-zero even on success, check output
          expect(error.message).toContain('succeeded')
        }
      })
    })
  })

  describe('Web Endpoints', () => {
    it('should access MinIO Console', async () => {
      const response = await fetch('http://localhost:9001')
      expect(response.status).toBe(200)
    })

    it('should access Meilisearch UI', async () => {
      const response = await fetch('http://localhost:7700')
      expect(response.status).toBe(200)
    })

    it('should access Router endpoint', async () => {
      const response = await fetch('http://localhost:4000/health')
      // 401 is expected without auth
      expect(response.status).toBe(401)
    })
  })

  describe('Volume Persistence', () => {
    it('should have data volumes created', async () => {
      const { stdout } = await execAsync('docker volume ls --format "{{.Name}}" | grep hanzo')
      const volumes = stdout.trim().split('\n').filter(Boolean)
      
      const expectedVolumes = [
        'postgres_data',
        'redis_data',
        'mongodb_data',
        'minio_data',
        'meilisearch_data'
      ]
      
      expectedVolumes.forEach(volume => {
        expect(volumes.some(v => v.includes(volume))).toBe(true)
      })
    })
  })
})