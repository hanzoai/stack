#\!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Setting up GitHub labels and issues for Hanzo Stack...${NC}"

# Create labels first
echo -e "\n${YELLOW}Creating labels...${NC}"

# Priority labels
gh label create "priority:critical" --description "Critical priority - blocks production" --color "FF0000" 2>/dev/null || true
gh label create "priority:high" --description "High priority - needed soon" --color "FF6B6B" 2>/dev/null || true
gh label create "priority:medium" --description "Medium priority" --color "FFA500" 2>/dev/null || true
gh label create "priority:low" --description "Low priority" --color "90EE90" 2>/dev/null || true

# Type labels
gh label create "type:bug" --description "Something isn't working" --color "d73a4a" 2>/dev/null || true
gh label create "type:feature" --description "New feature or request" --color "0075ca" 2>/dev/null || true
gh label create "type:docker" --description "Docker/containerization related" --color "0052CC" 2>/dev/null || true
gh label create "type:infrastructure" --description "Infrastructure/DevOps" --color "5319E7" 2>/dev/null || true
gh label create "type:documentation" --description "Documentation improvements" --color "0052CC" 2>/dev/null || true

# Service labels
gh label create "service:runtime" --description "Runtime service" --color "FBCA04" 2>/dev/null || true
gh label create "service:iam" --description "IAM service" --color "FBCA04" 2>/dev/null || true
gh label create "service:mcp" --description "MCP service" --color "FBCA04" 2>/dev/null || true
gh label create "service:agent" --description "Agent service" --color "FBCA04" 2>/dev/null || true
gh label create "service:api" --description "API service" --color "FBCA04" 2>/dev/null || true
gh label create "service:search" --description "Search service" --color "FBCA04" 2>/dev/null || true
gh label create "service:flow" --description "Flow service" --color "FBCA04" 2>/dev/null || true
gh label create "service:cloud" --description "Cloud service" --color "FBCA04" 2>/dev/null || true

echo -e "${GREEN}✅ Labels created\!${NC}"

# Create milestone
echo -e "\n${YELLOW}Creating milestone...${NC}"
gh api repos/:owner/:repo/milestones -f title="Stack Production Ready" -f description="Get all Hanzo services production ready" -f due_on="2025-08-07T08:00:00Z" 2>/dev/null || true

# Now create issues
echo -e "\n${YELLOW}Creating issues...${NC}"

# Issue 1: Runtime Service
gh issue create --title "🚨 CRITICAL: Fix Runtime service build errors" \
  --body "## Priority: CRITICAL - Day 1-4

### Current Issues:
- Missing OpenTelemetry dependencies
- TypeScript compilation errors in \`apps/api/src/tracing.ts\`
- Complex NX monorepo build failing

### Tasks:
- [ ] Fix missing dependencies in package.json
- [ ] Resolve TypeScript errors
- [ ] Create production-ready Dockerfile
- [ ] Add proper health checks
- [ ] Test with full stack

### Error Details:
\`\`\`
Cannot find module '@opentelemetry/semantic-conventions/incubating'
Cannot find module '@opentelemetry/api'
Cannot find module 'node-forge'
\`\`\`

### Time Estimate: 4 days
### Blocks: All other services depend on Runtime" \
  --label "priority:critical,service:runtime,type:bug,type:docker" \
  --assignee zeekay

# Issue 2: IAM Service  
gh issue create --title "🚨 CRITICAL: Optimize IAM service Docker build" \
  --body "## Priority: CRITICAL - Day 1-2

### Current Issues:
- Build timeout due to complex frontend + backend build
- Multi-stage Docker build takes too long
- Architecture-specific binary issues

### Tasks:
- [ ] Optimize Docker build stages
- [ ] Implement proper build caching
- [ ] Consider using pre-built binaries
- [ ] Document configuration requirements
- [ ] Create CI/CD pipeline for automated builds

### Current Workaround:
Using official Casdoor image, but need custom build for Hanzo modifications

### Time Estimate: 2 days" \
  --label "priority:critical,service:iam,type:docker,type:infrastructure" \
  --assignee zeekay

# Issue 3: API Service
gh issue create --title "HIGH: Dockerize API service (FastAPI)" \
  --body "## Priority: HIGH - Day 2-3

### Current Status:
- No Dockerfile exists
- FastAPI application needs containerization
- Database migrations need setup

### Tasks:
- [ ] Create FastAPI Dockerfile
- [ ] Set up Alembic for database migrations
- [ ] Add OpenAPI documentation
- [ ] Implement auth middleware
- [ ] Create health check endpoint

### Dependencies:
- PostgreSQL connection
- Redis for caching

### Time Estimate: 2 days" \
  --label "priority:high,service:api,type:docker" \
  --assignee zeekay

# Issue 4: MCP Service
gh issue create --title "HIGH: Dockerize MCP service" \
  --body "## Priority: HIGH - Day 3-5

### Current Status:
- Python package only, no service wrapper
- Needs HTTP/gRPC API layer
- Claude Desktop integration working

### Tasks:
- [ ] Create multi-stage Python Dockerfile
- [ ] Package as standalone service
- [ ] Add FastAPI/gRPC API layer
- [ ] Create health check endpoint
- [ ] Document MCP tool registration
- [ ] Test with Chat service integration

### Time Estimate: 3 days" \
  --label "priority:high,service:mcp,type:docker,type:feature" \
  --assignee zeekay

# Issue 5: Search Service
gh issue create --title "MEDIUM: Fix Search service Next.js build" \
  --body "## Priority: MEDIUM - Day 3-4

### Current Issues:
- Next.js build configuration errors
- Missing environment variables
- Supabase integration issues

### Tasks:
- [ ] Fix Next.js configuration
- [ ] Document all required env variables
- [ ] Create docker-compose override
- [ ] Configure search providers (Tavily, SearXNG, etc.)
- [ ] Add example .env file

### Time Estimate: 2 days" \
  --label "priority:medium,service:search,type:bug,type:docker" \
  --assignee zeekay

# Issue 6: Agent Service
gh issue create --title "HIGH: Dockerize Agent service with orchestration" \
  --body "## Priority: HIGH - Day 6-9

### Current Status:
- No Dockerfile
- Complex multi-agent orchestration
- Needs service architecture design

### Tasks:
- [ ] Design service architecture
- [ ] Create comprehensive Dockerfile
- [ ] Implement agent registry
- [ ] Add monitoring and logging
- [ ] Create example agents
- [ ] Document agent creation process
- [ ] Test multi-agent workflows

### Dependencies:
- MCP service for tools
- Runtime for execution

### Time Estimate: 4 days" \
  --label "priority:high,service:agent,type:docker,type:feature" \
  --assignee zeekay

# Issue 7: Flow Service
gh issue create --title "MEDIUM: Dockerize Flow visual workflow builder" \
  --body "## Priority: MEDIUM - Day 7-10

### Current Status:
- No Dockerfile
- React-based UI application
- Workflow persistence needed

### Tasks:
- [ ] Create React app Dockerfile
- [ ] Set up workflow storage (PostgreSQL)
- [ ] Implement API endpoints
- [ ] Add authentication integration
- [ ] Create demo workflows
- [ ] Document workflow format

### Time Estimate: 4 days" \
  --label "priority:medium,service:flow,type:docker,type:feature" \
  --assignee zeekay

# Issue 8: Cloud Service
gh issue create --title "MEDIUM: Fix Cloud service pnpm workspace issues" \
  --body "## Priority: MEDIUM - Day 11-13

### Current Issues:
- pnpm workspace configuration errors
- Complex build process failing
- Missing service configurations

### Tasks:
- [ ] Fix pnpm workspace configuration
- [ ] Create proper Dockerfile
- [ ] Set up service mesh configuration
- [ ] Add monitoring dashboards
- [ ] Document cloud management features

### Time Estimate: 3 days" \
  --label "priority:medium,service:cloud,type:bug,type:docker" \
  --assignee zeekay

# Issue 9: Integration Testing
gh issue create --title "HIGH: Full stack integration testing" \
  --body "## Priority: HIGH - Day 14-15

### Tasks:
- [ ] Create integration test suite
- [ ] Test all service communications
- [ ] Verify health checks across stack
- [ ] Perform load testing
- [ ] Run security scanning
- [ ] Document test procedures

### Success Criteria:
- All services communicate properly
- Health checks pass 100%
- No security vulnerabilities
- Performance meets requirements

### Time Estimate: 2 days" \
  --label "priority:high,type:infrastructure" \
  --assignee zeekay

# Issue 10: Documentation
gh issue create --title "HIGH: Complete stack documentation" \
  --body "## Priority: HIGH - Day 16-17

### Tasks:
- [ ] Document ALL environment variables
- [ ] Create comprehensive deployment guide
- [ ] Write developer setup guide
- [ ] Add architecture diagrams
- [ ] Create troubleshooting guide
- [ ] Document backup/restore procedures
- [ ] Add performance tuning guide

### Deliverables:
- README.md updates
- DEPLOYMENT.md
- DEVELOPMENT.md
- TROUBLESHOOTING.md
- Architecture diagrams

### Time Estimate: 2 days" \
  --label "priority:high,type:documentation" \
  --assignee zeekay

# Issue 11: Production Deployment
gh issue create --title "HIGH: Production deployment preparation" \
  --body "## Priority: HIGH - Day 18-21

### Tasks:
- [ ] Set up GitHub Actions CI/CD
- [ ] Configure Prometheus/Grafana monitoring
- [ ] Create backup and restore procedures
- [ ] Set up staging environment
- [ ] Create production deployment checklist
- [ ] Configure auto-scaling
- [ ] Set up alerting

### Deliverables:
- CI/CD pipelines
- Monitoring dashboards
- Deployment procedures
- Disaster recovery plan

### Time Estimate: 3 days" \
  --label "priority:high,type:infrastructure" \
  --assignee zeekay

# Repository cleanup issues
gh issue create --title "Clean up Router repository uncommitted changes" \
  --body "## Tasks:
- [ ] Review and commit/stash uncommitted changes
- [ ] Update documentation
- [ ] Add more provider configurations
- [ ] Implement rate limiting features

Due: End of Week 1" \
  --label "priority:medium" \
  --assignee zeekay

gh issue create --title "Clean up Chat repository uncommitted changes" \
  --body "## Tasks:
- [ ] Review and commit/stash uncommitted changes  
- [ ] Complete Hanzo branding updates
- [ ] Add custom plugins
- [ ] Implement SSO integration

Due: End of Week 1" \
  --label "priority:medium" \
  --assignee zeekay

gh issue create --title "Clean up IDE repository uncommitted changes" \
  --body "## Tasks:
- [ ] Review and commit/stash uncommitted changes
- [ ] Add Hanzo-specific extensions
- [ ] Create project templates
- [ ] Add debugging tools integration

Due: End of Week 1" \
  --label "priority:medium" \
  --assignee zeekay

echo -e "\n${GREEN}✅ All issues created successfully\!${NC}"
echo -e "${GREEN}View project board at: https://github.com/hanzoai/stack/issues${NC}"
echo -e "${GREEN}Total timeline: 21 days to production${NC}"
