#!/bin/bash
# Verify Chat login is working

echo "=== Verifying Hanzo Chat Login ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if user exists in database
echo -e "${BLUE}1. Checking demo user in database...${NC}"
USER_EXISTS=$(docker exec hanzo-mongodb mongosh -u hanzo -p hanzo123 --authenticationDatabase admin --quiet --eval "
use hanzo;
var user = db.users.findOne({ email: 'hattori@hanzo.ai' });
if (user) {
  print('found');
} else {
  print('not found');
}
" 2>/dev/null | grep -v "Using a password" | tail -1)

if [[ "$USER_EXISTS" == *"found"* ]]; then
  echo -e "${GREEN}✓${NC} Demo user exists in database"
  
  # Show user details
  docker exec hanzo-mongodb mongosh -u hanzo -p hanzo123 --authenticationDatabase admin --quiet --eval "
  use hanzo;
  var user = db.users.findOne({ email: 'hattori@hanzo.ai' });
  print('  Email: ' + user.email);
  print('  Name: ' + user.name);
  print('  Role: ' + user.role);
  print('  Active: ' + user.active);
  print('  Verified: ' + user.verified);
  " 2>/dev/null | grep -v "Using a password"
else
  echo -e "${RED}✗${NC} Demo user not found in database"
  echo "  Running user creation script..."
  bash /Users/z/work/hanzo/stack/scripts/create-demo-user.sh
fi

echo ""
echo -e "${BLUE}2. Testing Chat UI accessibility...${NC}"
CHAT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3081)
if [ "$CHAT_STATUS" == "200" ]; then
  echo -e "${GREEN}✓${NC} Chat UI is accessible at http://localhost:3081"
else
  echo -e "${RED}✗${NC} Chat UI returned status code: $CHAT_STATUS"
fi

echo ""
echo -e "${BLUE}3. Checking branding configuration...${NC}"
docker exec hanzo-chat env | grep BRAND | while read line; do
  echo "  $line"
done

echo ""
echo -e "${BLUE}4. Login Information:${NC}"
echo "  URL: http://localhost:3081"
echo "  Email: hattori@hanzo.ai"
echo "  Password: hanzo123"
echo ""
echo "If login still fails, check the logs:"
echo "  docker logs hanzo-chat --tail 50"
echo ""
echo "To see all users in database:"
echo "  docker exec hanzo-mongodb mongosh -u hanzo -p hanzo123 --authenticationDatabase admin --eval 'use hanzo; db.users.find().pretty()'"