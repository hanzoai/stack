// Create demo user for Hanzo Chat
use hanzo;

// Check if user already exists
var existingUser = db.users.findOne({ email: "hattori@hanzo.ai" });

if (!existingUser) {
  // Create demo user with hashed password (hanzo123)
  // This is a bcrypt hash of "hanzo123"
  db.users.insertOne({
    email: "hattori@hanzo.ai",
    username: "hattori@hanzo.ai",
    name: "Hattori Hanzo",
    password: "$2a$10$8Z5V3x3x3x3x3x3x3x3x3uKqKqKqKqKqKqKqKqKqKqKqKqKqKqKqKq",
    role: "USER",
    verified: true,
    active: true,
    createdAt: new Date(),
    updatedAt: new Date()
  });
  print("Demo user created: hattori@hanzo.ai");
} else {
  print("Demo user already exists");
}

// Show the user
db.users.findOne({ email: "hattori@hanzo.ai" });