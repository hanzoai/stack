const { describe, it, expect, beforeAll, afterAll } = require('@jest/globals');
const pg = require('pg');
const redis = require('redis');
const { MongoClient } = require('mongodb');

describe('Basic Services - Real Tests', () => {
  describe('PostgreSQL', () => {
    let pgClient;

    beforeAll(async () => {
      pgClient = new pg.Client({
        host: 'localhost',
        port: 15432,
        user: 'hanzo',
        password: 'hanzo123',
        database: 'hanzo'
      });
      await pgClient.connect();
    });

    afterAll(async () => {
      if (pgClient) await pgClient.end();
    });

    it('should connect to PostgreSQL and run queries', async () => {
      const result = await pgClient.query('SELECT NOW() as current_time');
      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].current_time).toBeInstanceOf(Date);
    });

    it('should create and query a test table', async () => {
      const tableName = `test_table_${Date.now()}`;

      // Create table
      await pgClient.query(`
        CREATE TABLE IF NOT EXISTS ${tableName} (
          id SERIAL PRIMARY KEY,
          name VARCHAR(100),
          value INTEGER,
          created_at TIMESTAMP DEFAULT NOW()
        )
      `);

      // Insert data
      await pgClient.query(
        `INSERT INTO ${tableName} (name, value) VALUES ($1, $2)`,
        ['test_entry', 42]
      );

      // Query data
      const result = await pgClient.query(`SELECT * FROM ${tableName} WHERE name = $1`, ['test_entry']);
      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].name).toBe('test_entry');
      expect(result.rows[0].value).toBe(42);

      // Cleanup
      await pgClient.query(`DROP TABLE IF EXISTS ${tableName}`);
    });
  });

  describe('Redis', () => {
    let redisClient;

    beforeAll(async () => {
      redisClient = redis.createClient({
        url: 'redis://localhost:6379'
      });
      await redisClient.connect();
    });

    afterAll(async () => {
      if (redisClient) await redisClient.quit();
    });

    it('should connect to Redis and perform operations', async () => {
      const pong = await redisClient.ping();
      expect(pong).toBe('PONG');
    });

    it('should set and get values', async () => {
      const key = `test:key:${Date.now()}`;
      await redisClient.set(key, 'test_value');
      const value = await redisClient.get(key);
      expect(value).toBe('test_value');

      // Cleanup
      await redisClient.del(key);
    });

    it('should handle data structures', async () => {
      const listKey = `test:list:${Date.now()}`;

      // List operations
      await redisClient.rPush(listKey, ['item1', 'item2', 'item3']);
      const listLength = await redisClient.lLen(listKey);
      expect(listLength).toBe(3);

      const listItems = await redisClient.lRange(listKey, 0, -1);
      expect(listItems).toEqual(['item1', 'item2', 'item3']);

      // Cleanup
      await redisClient.del(listKey);
    });
  });

  describe('MongoDB', () => {
    let mongoClient;
    let db;

    beforeAll(async () => {
      mongoClient = new MongoClient('mongodb://hanzo:hanzo123@localhost:27017', {
        authSource: 'admin'
      });
      await mongoClient.connect();
      db = mongoClient.db('hanzo_test');
    });

    afterAll(async () => {
      if (mongoClient) await mongoClient.close();
    });

    it('should connect to MongoDB', async () => {
      const admin = mongoClient.db().admin();
      const result = await admin.ping();
      expect(result.ok).toBe(1);
    });

    it('should perform CRUD operations', async () => {
      const collectionName = `test_collection_${Date.now()}`;
      const collection = db.collection(collectionName);

      // Insert
      const insertResult = await collection.insertOne({
        name: 'test_document',
        value: 100,
        tags: ['test', 'integration'],
        created: new Date()
      });
      expect(insertResult.acknowledged).toBe(true);
      expect(insertResult.insertedId).toBeDefined();

      // Find
      const doc = await collection.findOne({ _id: insertResult.insertedId });
      expect(doc.name).toBe('test_document');
      expect(doc.value).toBe(100);

      // Update
      const updateResult = await collection.updateOne(
        { _id: insertResult.insertedId },
        { $set: { value: 200 }, $push: { tags: 'updated' } }
      );
      expect(updateResult.modifiedCount).toBe(1);

      // Verify update
      const updatedDoc = await collection.findOne({ _id: insertResult.insertedId });
      expect(updatedDoc.value).toBe(200);
      expect(updatedDoc.tags).toContain('updated');

      // Delete
      const deleteResult = await collection.deleteOne({ _id: insertResult.insertedId });
      expect(deleteResult.deletedCount).toBe(1);

      // Drop collection for cleanup
      await collection.drop();
    });

    it('should handle aggregation pipelines', async () => {
      const collection = db.collection(`aggregate_test_${Date.now()}`);

      // Insert test data
      await collection.insertMany([
        { category: 'A', value: 10 },
        { category: 'A', value: 20 },
        { category: 'B', value: 30 },
        { category: 'B', value: 40 }
      ]);

      // Aggregation
      const result = await collection.aggregate([
        { $group: { _id: '$category', total: { $sum: '$value' } } },
        { $sort: { _id: 1 } }
      ]).toArray();

      expect(result).toHaveLength(2);
      expect(result[0]).toEqual({ _id: 'A', total: 30 });
      expect(result[1]).toEqual({ _id: 'B', total: 70 });

      // Cleanup
      await collection.drop();
    });
  });
});