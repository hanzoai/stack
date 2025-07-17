-- Create analytics database and user
CREATE USER analytics WITH PASSWORD 'analytics123';
CREATE DATABASE analytics OWNER analytics;
GRANT ALL PRIVILEGES ON DATABASE analytics TO analytics;

-- Connect to analytics database
\c analytics;

-- Grant schema permissions
GRANT ALL ON SCHEMA public TO analytics;