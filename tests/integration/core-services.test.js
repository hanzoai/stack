const { describe, it, expect, beforeAll, afterAll } = require('@jest/globals');
const pg = require('pg');
const redis = require('redis');
const { MongoClient } = require('mongodb');
// const { S3Client, ListBucketsCommand } = require('@aws-sdk/client-s3');
// const { MeiliSearch } = require('meilisearch');
const testConfig = require('../test-config');

describe('Core Infrastructure Services', () => {
  describe('PostgreSQL', () => {
    let pgClient

    beforeAll(() => {
      pgClient = new pg.Client(testConfig.postgres)
    })

    afterAll(async () => {
      await pgClient.end()
    })

    it('should connect to PostgreSQL', async () => {
      await pgClient.connect()
      const result = await pgClient.query('SELECT NOW()')
      expect(result.rows).toHaveLength(1)
      expect(result.rows[0].now).toBeInstanceOf(Date)
    })

    it('should create and query a test table', async () => {
      await pgClient.query(`
        CREATE TABLE IF NOT EXISTS test_table (
          id SERIAL PRIMARY KEY,
          name VARCHAR(100),
          created_at TIMESTAMP DEFAULT NOW()
        )
      `)
      
      await pgClient.query('INSERT INTO test_table (name) VALUES ($1)', ['test_entry'])
      const result = await pgClient.query('SELECT * FROM test_table WHERE name = $1', ['test_entry'])
      
      expect(result.rows).toHaveLength(1)
      expect(result.rows[0].name).toBe('test_entry')
      
      // Cleanup
      await pgClient.query('DROP TABLE test_table')
    })
  })

  describe('Redis', () => {
    let redisClient

    beforeAll(async () => {
      redisClient = createClient({
        url: 'redis://:hanzo123@localhost:6379'
      })
      await redisClient.connect()
    })

    afterAll(async () => {
      await redisClient.quit()
    })

    it('should connect to Redis', async () => {
      const pong = await redisClient.ping()
      expect(pong).toBe('PONG')
    })

    it('should set and get values', async () => {
      await redisClient.set('test:key', 'test_value')
      const value = await redisClient.get('test:key')
      expect(value).toBe('test_value')
      
      // Cleanup
      await redisClient.del('test:key')
    })

    it('should handle expiration', async () => {
      await redisClient.setEx('test:expiring', 1, 'will_expire')
      const value1 = await redisClient.get('test:expiring')
      expect(value1).toBe('will_expire')
      
      // Wait for expiration
      await new Promise(resolve => setTimeout(resolve, 1500))
      const value2 = await redisClient.get('test:expiring')
      expect(value2).toBeNull()
    }, 10000)
  })

  describe('MongoDB', () => {
    let mongoClient
    let db

    beforeAll(async () => {
      mongoClient = new MongoClient('mongodb://hanzo:hanzo123@localhost:27017')
      await mongoClient.connect()
      db = mongoClient.db('hanzo')
    })

    afterAll(async () => {
      await mongoClient.close()
    })

    it('should connect to MongoDB', async () => {
      const admin = mongoClient.db().admin()
      const result = await admin.ping()
      expect(result).toEqual({ ok: 1 })
    })

    it('should perform CRUD operations', async () => {
      const collection = db.collection('test_collection')
      
      // Create
      const insertResult = await collection.insertOne({ 
        name: 'test_document', 
        timestamp: new Date() 
      })
      expect(insertResult.acknowledged).toBe(true)
      
      // Read
      const doc = await collection.findOne({ _id: insertResult.insertedId })
      expect(doc.name).toBe('test_document')
      
      // Update
      await collection.updateOne(
        { _id: insertResult.insertedId },
        { $set: { updated: true } }
      )
      const updatedDoc = await collection.findOne({ _id: insertResult.insertedId })
      expect(updatedDoc.updated).toBe(true)
      
      // Delete
      await collection.deleteOne({ _id: insertResult.insertedId })
      const deletedDoc = await collection.findOne({ _id: insertResult.insertedId })
      expect(deletedDoc).toBeNull()
    })
  })

  describe.skip('MinIO (S3)', () => {
    let s3Client

    beforeAll(() => {
      s3Client = new S3Client({
        endpoint: 'http://localhost:9000',
        region: 'us-east-1',
        credentials: {
          accessKeyId: 'minioadmin',
          secretAccessKey: 'minioadmin'
        },
        forcePathStyle: true
      })
    })

    it('should connect to MinIO', async () => {
      const command = new ListBucketsCommand({})
      const response = await s3Client.send(command)
      expect(response.$metadata.httpStatusCode).toBe(200)
      expect(response.Buckets).toBeDefined()
    })
  })

  describe.skip('Meilisearch', () => {
    let meiliClient

    beforeAll(() => {
      meiliClient = new MeiliSearch({
        host: 'http://localhost:7700',
        apiKey: 'hanzo-meili-master'
      })
    })

    it('should connect to Meilisearch', async () => {
      const health = await meiliClient.health()
      expect(health.status).toBe('available')
    })

    it('should create index and add documents', async () => {
      const indexName = 'test_index'
      const index = meiliClient.index(indexName)
      
      // Add documents
      const documents = [
        { id: 1, title: 'Test Document 1', content: 'This is a test' },
        { id: 2, title: 'Test Document 2', content: 'Another test document' }
      ]
      
      const addTask = await index.addDocuments(documents)
      
      // Wait for indexing to complete
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      // Search
      const searchResult = await index.search('test')
      expect(searchResult.hits.length).toBeGreaterThan(0)
      
      // Cleanup
      await index.delete()
    })
  })
})