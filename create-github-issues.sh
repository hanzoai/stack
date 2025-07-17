#\!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Creating GitHub issues for Hanzo Stack development...${NC}"

# Get today's date
TODAY=$(date +%Y-%m-%d)

# Critical Infrastructure Issues (Start immediately)
echo -e "\n${YELLOW}Creating Critical Infrastructure issues...${NC}"

gh issue create --title "Fix Runtime service build errors" \
  --body "## Priority: CRITICAL
  
### Issues:
- Missing OpenTelemetry dependencies
- TypeScript compilation errors  
- Complex NX monorepo build

### Tasks:
- [ ] Fix package.json dependencies
- [ ] Resolve TypeScript errors in tracing.ts
- [ ] Create production-ready Dockerfile
- [ ] Add proper health checks
- [ ] Test with full stack

### Estimated Time: 4 days
### Due Date: $(date -d "$TODAY + 4 days" +%Y-%m-%d)" \
  --label "critical,backend,docker" \
  --assignee zeekay \
  --milestone "Stack Production Ready"

gh issue create --title "Optimize IAM service Docker build" \
  --body "## Priority: CRITICAL

### Issues:
- Long build times (frontend + backend)
- Multi-stage Docker build timeout
- Architecture-specific binaries

### Tasks:
- [ ] Optimize Docker build stages
- [ ] Use build cache effectively  
- [ ] Create CI/CD pipeline for pre-built images
- [ ] Document configuration

### Estimated Time: 2 days
### Due Date: $(date -d "$TODAY + 2 days" +%Y-%m-%d)" \
  --label "critical,devops,docker" \
  --assignee zeekay \
  --milestone "Stack Production Ready"

# Core Services Issues
echo -e "\n${YELLOW}Creating Core Services issues...${NC}"

gh issue create --title "Dockerize MCP service" \
  --body "## Priority: HIGH

### Issues:
- No Dockerfile exists
- Python package distribution
- Claude Desktop integration

### Tasks:
- [ ] Create multi-stage Dockerfile
- [ ] Package as standalone service
- [ ] Add gRPC/HTTP API layer
- [ ] Create health check endpoint
- [ ] Document MCP tool registration

### Estimated Time: 3 days
### Due Date: $(date -d "$TODAY + 5 days" +%Y-%m-%d)" \
  --label "high,python,docker" \
  --assignee zeekay \
  --milestone "Stack Production Ready"

gh issue create --title "Dockerize Agent service with orchestration" \
  --body "## Priority: HIGH

### Issues:
- No Dockerfile
- Complex orchestration logic
- Multi-agent coordination

### Tasks:
- [ ] Design service architecture
- [ ] Create Dockerfile with all dependencies
- [ ] Implement agent registry
- [ ] Add monitoring/logging
- [ ] Create example agents

### Estimated Time: 4 days
### Due Date: $(date -d "$TODAY + 9 days" +%Y-%m-%d)" \
  --label "high,ai-ml,docker" \
  --assignee zeekay \
  --milestone "Stack Production Ready"

gh issue create --title "Dockerize API service" \
  --body "## Priority: HIGH

### Issues:
- No Dockerfile
- FastAPI configuration
- Database migrations

### Tasks:
- [ ] Create FastAPI Dockerfile
- [ ] Set up Alembic migrations
- [ ] Add API documentation
- [ ] Implement auth middleware

### Estimated Time: 2 days
### Due Date: $(date -d "$TODAY + 3 days" +%Y-%m-%d)" \
  --label "high,backend,docker" \
  --assignee zeekay \
  --milestone "Stack Production Ready"

# UI Applications Issues
echo -e "\n${YELLOW}Creating UI Applications issues...${NC}"

gh issue create --title "Fix Search service build errors" \
  --body "## Priority: MEDIUM

### Issues:
- Next.js build configuration
- Missing environment variables
- Supabase integration

### Tasks:
- [ ] Fix Next.js config
- [ ] Document all env vars
- [ ] Create docker-compose override
- [ ] Add search provider configs

### Estimated Time: 2 days
### Due Date: $(date -d "$TODAY + 4 days" +%Y-%m-%d)" \
  --label "medium,frontend,docker" \
  --assignee zeekay \
  --milestone "Stack Production Ready"

gh issue create --title "Dockerize Flow service" \
  --body "## Priority: MEDIUM

### Issues:
- No Dockerfile
- Complex UI dependencies
- Workflow persistence

### Tasks:
- [ ] Create React app Dockerfile
- [ ] Set up workflow storage
- [ ] Implement API endpoints
- [ ] Add authentication
- [ ] Create demo workflows

### Estimated Time: 4 days
### Due Date: $(date -d "$TODAY + 10 days" +%Y-%m-%d)" \
  --label "medium,fullstack,docker" \
  --assignee zeekay \
  --milestone "Stack Production Ready"

gh issue create --title "Fix Cloud service build issues" \
  --body "## Priority: MEDIUM

### Issues:
- pnpm workspace errors
- Complex build process
- Missing configurations

### Tasks:
- [ ] Fix workspace configuration
- [ ] Create proper Dockerfile
- [ ] Set up service mesh
- [ ] Add monitoring dashboards

### Estimated Time: 3 days
### Due Date: $(date -d "$TODAY + 13 days" +%Y-%m-%d)" \
  --label "medium,cloud,docker" \
  --assignee zeekay \
  --milestone "Stack Production Ready"

# Integration and Testing Issues
echo -e "\n${YELLOW}Creating Integration issues...${NC}"

gh issue create --title "Full stack integration testing" \
  --body "## Priority: HIGH

### Tasks:
- [ ] Create integration test suite
- [ ] Test all service communications
- [ ] Verify health checks
- [ ] Load testing
- [ ] Security scanning

### Estimated Time: 2 days
### Due Date: $(date -d "$TODAY + 15 days" +%Y-%m-%d)" \
  --label "high,testing,integration" \
  --assignee zeekay \
  --milestone "Stack Production Ready"

gh issue create --title "Complete stack documentation" \
  --body "## Priority: HIGH

### Tasks:
- [ ] Document all environment variables
- [ ] Create deployment guide
- [ ] Write developer setup guide
- [ ] Add architecture diagrams
- [ ] Create troubleshooting guide

### Estimated Time: 2 days
### Due Date: $(date -d "$TODAY + 17 days" +%Y-%m-%d)" \
  --label "high,documentation" \
  --assignee zeekay \
  --milestone "Stack Production Ready"

gh issue create --title "Production deployment preparation" \
  --body "## Priority: HIGH

### Tasks:
- [ ] Set up CI/CD pipelines
- [ ] Configure monitoring/alerting
- [ ] Create backup procedures
- [ ] Set up staging environment
- [ ] Production deployment checklist

### Estimated Time: 3 days
### Due Date: $(date -d "$TODAY + 21 days" +%Y-%m-%d)" \
  --label "high,devops,production" \
  --assignee zeekay \
  --milestone "Stack Production Ready"

# Repository-specific cleanup issues
echo -e "\n${YELLOW}Creating Repository Cleanup issues...${NC}"

gh issue create --title "Clean up Router repository" \
  --body "## Tasks:
- [ ] Commit or stash uncommitted changes
- [ ] Update documentation
- [ ] Add provider configurations
- [ ] Implement rate limiting

### Due Date: $(date -d "$TODAY + 7 days" +%Y-%m-%d)" \
  --label "cleanup,router" \
  --assignee zeekay

gh issue create --title "Clean up Chat repository" \
  --body "## Tasks:
- [ ] Commit or stash uncommitted changes
- [ ] Update Hanzo branding
- [ ] Add custom plugins
- [ ] SSO integration

### Due Date: $(date -d "$TODAY + 7 days" +%Y-%m-%d)" \
  --label "cleanup,chat" \
  --assignee zeekay

gh issue create --title "Clean up IDE repository" \
  --body "## Tasks:
- [ ] Commit or stash uncommitted changes
- [ ] Add Hanzo extensions
- [ ] Create project templates
- [ ] Add debugging tools

### Due Date: $(date -d "$TODAY + 7 days" +%Y-%m-%d)" \
  --label "cleanup,ide" \
  --assignee zeekay

echo -e "\n${GREEN}✅ All issues created successfully\!${NC}"
echo -e "${GREEN}View all issues at: https://github.com/hanzoai/stack/issues${NC}"
