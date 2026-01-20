// Test configuration for real services
const isCI = process.env.CI === 'true';

module.exports = {
  postgres: {
    host: 'localhost',
    port: isCI ? 15432 : (process.env.POSTGRES_PORT || 5433), // CI uses 15432, local uses 5433 or env var
    user: 'hanzo',
    password: 'hanzo123',
    database: 'hanzo'
  },
  redis: {
    host: 'localhost',
    port: isCI ? 6379 : (process.env.REDIS_PORT || 6380), // CI uses 6379, local uses 6380 or env var
    password: isCI ? undefined : 'hanzo123' // CI Redis doesn't use password
  },
  mongodb: {
    url: 'mongodb://hanzo:hanzo123@localhost:27017/hanzo'
  },
  minio: {
    endpoint: 'localhost',
    port: isCI ? 9000 : (process.env.MINIO_PORT || 9002), // CI uses 9000, local uses 9002 or env var
    accessKey: 'minioadmin',
    secretKey: 'minioadmin',
    useSSL: false
  },
  meilisearch: {
    host: 'http://localhost:7700',
    apiKey: 'masterKey'
  },
  services: {
    router: 'http://localhost:4000',
    chat: 'http://localhost:3081',
    cloud: 'http://localhost:3001',
    search: 'http://localhost:3000',
    runtime: 'http://localhost:3003',
    platform: 'http://localhost:3006',
    build: 'http://localhost:3002'
  }
};