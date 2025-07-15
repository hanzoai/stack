const bcrypt = require('bcryptjs');

async function createDemoUser() {
  const password = 'hanzo123';
  const hash = await bcrypt.hash(password, 10);
  
  console.log(`
// Run this in MongoDB to create the demo user
use hanzo;
db.users.deleteMany({ email: "hattori@hanzo.ai" });
db.users.insertOne({
  email: "hattori@hanzo.ai",
  username: "hattori",
  name: "Hattori Hanzo",
  password: "${hash}",
  role: "USER",
  emailVerified: true,
  verified: true,
  active: true,
  provider: "local",
  createdAt: new Date(),
  updatedAt: new Date()
});
print("Demo user created with password: hanzo123");
  `);
}

createDemoUser();
EOF < /dev/null