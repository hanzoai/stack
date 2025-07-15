// MongoDB script to create demo user
use hanzo;

// Delete any existing demo users
db.users.deleteMany({ email: "hattori@hanzo.ai" });

// Create new demo user with bcrypt hash for "hanzo123"
var result = db.users.insertOne({
  email: "hattori@hanzo.ai",
  username: "hattori",
  name: "Hattori Hanzo",
  password: "$2a$10$mEod/hbjeWSQ.sTjLEmDFO/XDGzTC94HyG37ehE5KEnjNnEbcdmB.",
  role: "USER",
  emailVerified: true,
  verified: true,
  active: true,
  provider: "local",
  createdAt: new Date(),
  updatedAt: new Date()
});

print("User creation result: " + JSON.stringify(result));

// Verify user was created
var user = db.users.findOne({ email: "hattori@hanzo.ai" });
if (user) {
  print("Demo user created successfully!");
  print("Email: " + user.email);
  print("Name: " + user.name);
} else {
  print("Failed to create demo user!");
}