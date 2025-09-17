// Test configuration for real services
module.exports = {
  postgres: {
    host: 'localhost',
    port: 5432,
    user: 'hanzo',
    password: 'hanzo123',
    database: 'hanzo'
  },
  redis: {
    host: 'localhost',
    port: 6379,
    password: 'hanzo123'
  },
  mongodb: {
    url: 'mongodb://hanzo:hanzo123@localhost:27017/hanzo'
  },
  minio: {
    endpoint: 'localhost',
    port: 9000,
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