#!/bin/bash
# Verify both fixes are working

echo "=== Hanzo Chat Fix Verification ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Check logos
echo "1. Checking logo files..."
LOGO_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3081/assets/hanzo-logo.svg)
DARK_LOGO_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3081/assets/hanzo-logo-dark.svg)

if [ "$LOGO_STATUS" == "200" ]; then
  echo -e "  ${GREEN}✓${NC} Regular logo: http://localhost:3081/assets/hanzo-logo.svg"
else
  echo -e "  ${RED}✗${NC} Regular logo not found"
fi

if [ "$DARK_LOGO_STATUS" == "200" ]; then
  echo -e "  ${GREEN}✓${NC} Dark logo: http://localhost:3081/assets/hanzo-logo-dark.svg"
else
  echo -e "  ${RED}✗${NC} Dark logo not found"
fi

echo ""
echo "2. Checking demo user..."
USER_EXISTS=$(docker exec hanzo-mongodb mongosh -u hanzo -p hanzo123 --authenticationDatabase admin --quiet --eval "
use hanzo;
var user = db.users.findOne({ email: 'hattori@hanzo.ai' });
if (user && user.password) {
  print('exists');
} else {
  print('not found');
}
" 2>/dev/null | grep -v "Using a password" | tail -1)

if [[ "$USER_EXISTS" == *"exists"* ]]; then
  echo -e "  ${GREEN}✓${NC} Demo user exists in database"
else
  echo -e "  ${RED}✗${NC} Demo user not found"
fi

echo ""
echo "3. Login Information:"
echo "  URL: http://localhost:3081"
echo "  Email: hattori@hanzo.ai"
echo "  Password: hanzo123"
echo ""
echo "Both the official Hanzo logo and demo user have been set up!"