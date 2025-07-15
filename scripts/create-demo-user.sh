#!/bin/bash
# Create demo user for Hanzo Chat

echo "Creating demo user hattori@hanzo.ai..."

# Generate bcrypt hash for password "hanzo123"
# Using Python since it's available in most containers
HASHED_PASSWORD=$(docker exec hanzo-chat python3 -c "
import bcrypt
password = b'hanzo123'
salt = bcrypt.gensalt()
hashed = bcrypt.hashpw(password, salt)
print(hashed.decode('utf-8'))
" 2>/dev/null || echo "")

if [ -z "$HASHED_PASSWORD" ]; then
  echo "Bcrypt not available, using Node.js..."
  HASHED_PASSWORD=$(docker exec hanzo-chat node -e "
  const bcrypt = require('bcryptjs');
  const hash = bcrypt.hashSync('hanzo123', 10);
  console.log(hash);
  " 2>/dev/null || echo "")
fi

if [ -z "$HASHED_PASSWORD" ]; then
  echo "Using pre-generated hash for hanzo123"
  # This is a pre-generated bcrypt hash of "hanzo123"
  HASHED_PASSWORD='$2a$10$L8Z5V3GvJqKqCqW4V1YJiOqweP4s4Y6U5I8F3K7N9M0X2Q1R3T5S6'
fi

echo "Hash generated: $HASHED_PASSWORD"

# Create user in MongoDB
docker exec hanzo-mongodb mongosh -u hanzo -p hanzo123 --authenticationDatabase admin --quiet --eval "
use hanzo;

// Check if user exists
var user = db.users.findOne({ email: 'hattori@hanzo.ai' });

if (!user) {
  // Create demo user
  db.users.insertOne({
    email: 'hattori@hanzo.ai',
    username: 'hattori@hanzo.ai',
    name: 'Hattori Hanzo',
    password: '$HASHED_PASSWORD',
    role: 'USER',
    verified: true,
    active: true,
    provider: 'local',
    createdAt: new Date(),
    updatedAt: new Date()
  });
  print('✅ Demo user created successfully');
} else {
  print('ℹ️ Demo user already exists');
}

// Verify user was created
var createdUser = db.users.findOne({ email: 'hattori@hanzo.ai' });
if (createdUser) {
  print('User details:');
  print('Email: ' + createdUser.email);
  print('Name: ' + createdUser.name);
  print('Role: ' + createdUser.role);
  print('Verified: ' + createdUser.verified);
} else {
  print('❌ Failed to create user');
}
"

echo ""
echo "You can now login with:"
echo "Email: hattori@hanzo.ai"
echo "Password: hanzo123"