#\!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${PURPLE}Creating comprehensive issues across ALL Hanzo repositories...${NC}"

# Get today's date in ISO format
TODAY=$(date +%Y-%m-%d)

# Function to add days to date (macOS compatible)
add_days() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        date -j -v +"$1"d -f "%Y-%m-%d" "$2" "+%Y-%m-%d"
    else
        date -d "$2 + $1 days" +%Y-%m-%d
    fi
}

# Analytics Repository Detailed Issues
echo -e "\n${YELLOW}=== ANALYTICS REPOSITORY ===${NC}"

gh issue create --repo hanzoai/analytics \
  --title "Set up multi-tenant analytics isolation" \
  --body "## Priority: HIGH
## Start Date: $TODAY
## Due Date: $(add_days 3 $TODAY)
## Depends On: None

### Tasks:
- [ ] Implement tenant ID filtering
- [ ] Create tenant-specific dashboards
- [ ] Add data access controls
- [ ] Test isolation between tenants
- [ ] Document multi-tenant setup

### Acceptance Criteria:
- Each tenant can only see their own data
- Super admin can see all tenants
- Performance not degraded with filtering" \
  --assignee zeekay

gh issue create --repo hanzoai/analytics \
  --title "Implement real-time analytics streaming" \
  --body "## Priority: MEDIUM
## Start Date: $(add_days 4 $TODAY)
## Due Date: $(add_days 7 $TODAY)
## Depends On: Multi-tenant isolation

### Tasks:
- [ ] Set up WebSocket connections
- [ ] Implement event streaming
- [ ] Create real-time dashboards
- [ ] Add rate limiting
- [ ] Test with high volume

### Tech Stack:
- Socket.io for WebSockets
- Redis Pub/Sub
- Server-Sent Events fallback" \
  --assignee zeekay

gh issue create --repo hanzoai/analytics \
  --title "Add custom event tracking API" \
  --body "## Priority: HIGH
## Start Date: $(add_days 2 $TODAY)
## Due Date: $(add_days 5 $TODAY)
## Depends On: None

### Tasks:
- [ ] Design event schema
- [ ] Create REST API endpoints
- [ ] Add event validation
- [ ] Implement batching
- [ ] Create SDK methods
- [ ] Write API documentation

### Event Types:
- LLM requests/responses
- User actions
- System events
- Custom business events" \
  --assignee zeekay

# IAM Repository Detailed Issues
echo -e "\n${YELLOW}=== IAM REPOSITORY ===${NC}"

gh issue create --repo hanzoai/iam \
  --title "Implement fine-grained permissions system" \
  --body "## Priority: CRITICAL
## Start Date: $TODAY
## Due Date: $(add_days 5 $TODAY)
## Depends On: None

### Tasks:
- [ ] Design permission model
- [ ] Create permission API
- [ ] Implement resource-based permissions
- [ ] Add permission inheritance
- [ ] Create permission UI
- [ ] Test edge cases

### Permission Types:
- Service access
- API endpoints
- Data resources
- Feature flags
- Cost limits" \
  --assignee zeekay

gh issue create --repo hanzoai/iam \
  --title "Add API key management system" \
  --body "## Priority: HIGH
## Start Date: $(add_days 3 $TODAY)
## Due Date: $(add_days 6 $TODAY)
## Depends On: Permissions system

### Tasks:
- [ ] API key generation
- [ ] Key rotation system
- [ ] Scope management
- [ ] Usage tracking
- [ ] Revocation system
- [ ] Audit logging

### Features:
- Multiple keys per user
- Expiration dates
- IP restrictions
- Rate limits per key" \
  --assignee zeekay

gh issue create --repo hanzoai/iam \
  --title "Implement team and organization hierarchy" \
  --body "## Priority: HIGH
## Start Date: $(add_days 6 $TODAY)
## Due Date: $(add_days 10 $TODAY)
## Depends On: Permissions system

### Tasks:
- [ ] Create org/team models
- [ ] Implement invitation system
- [ ] Add role templates
- [ ] Create management UI
- [ ] Add billing integration
- [ ] Test permission inheritance

### Hierarchy:
- Organizations
- Teams within orgs
- Projects within teams
- Users with multiple roles" \
  --assignee zeekay

# Cloud Repository Detailed Issues
echo -e "\n${YELLOW}=== CLOUD REPOSITORY ===${NC}"

gh issue create --repo hanzoai/cloud \
  --title "Create infrastructure as code templates" \
  --body "## Priority: HIGH
## Start Date: $(add_days 2 $TODAY)
## Due Date: $(add_days 7 $TODAY)
## Depends On: None

### Tasks:
- [ ] Terraform modules for AWS
- [ ] Terraform modules for GCP
- [ ] Terraform modules for Azure
- [ ] Kubernetes manifests
- [ ] Helm charts
- [ ] CI/CD templates

### Templates:
- Single-region deployment
- Multi-region deployment
- Edge deployment
- Development environment
- Disaster recovery" \
  --assignee zeekay

gh issue create --repo hanzoai/cloud \
  --title "Implement automated scaling policies" \
  --body "## Priority: HIGH
## Start Date: $(add_days 8 $TODAY)
## Due Date: $(add_days 12 $TODAY)
## Depends On: IaC templates

### Tasks:
- [ ] Define scaling metrics
- [ ] Create HPA configs
- [ ] Implement VPA
- [ ] Add cluster autoscaling
- [ ] Create cost controls
- [ ] Test scaling scenarios

### Scaling Triggers:
- Request rate
- Response time
- Queue depth
- Cost thresholds
- Time-based" \
  --assignee zeekay

gh issue create --repo hanzoai/cloud \
  --title "Build cloud cost optimization system" \
  --body "## Priority: MEDIUM
## Start Date: $(add_days 13 $TODAY)
## Due Date: $(add_days 18 $TODAY)
## Depends On: Scaling policies

### Tasks:
- [ ] Cost monitoring setup
- [ ] Spot instance integration
- [ ] Reserved instance planning
- [ ] Resource rightsizing
- [ ] Unused resource cleanup
- [ ] Cost anomaly detection

### Deliverables:
- Cost dashboards
- Optimization reports
- Automated actions
- Budget alerts" \
  --assignee zeekay

# Python SDK Repository Issues
echo -e "\n${YELLOW}=== PYTHON SDK REPOSITORY ===${NC}"

gh issue create --repo hanzoai/hanzoai-python \
  --title "Implement async client support" \
  --body "## Priority: HIGH
## Start Date: $(add_days 1 $TODAY)
## Due Date: $(add_days 4 $TODAY)
## Depends On: None

### Tasks:
- [ ] Create async client class
- [ ] Implement async methods
- [ ] Add connection pooling
- [ ] Create async examples
- [ ] Update documentation
- [ ] Test performance

### Features:
- Async/await support
- Concurrent requests
- Streaming responses
- WebSocket support" \
  --assignee zeekay

gh issue create --repo hanzoai/hanzoai-python \
  --title "Add comprehensive retry logic" \
  --body "## Priority: MEDIUM
## Start Date: $(add_days 5 $TODAY)
## Due Date: $(add_days 8 $TODAY)
## Depends On: Async client

### Tasks:
- [ ] Implement retry strategies
- [ ] Add exponential backoff
- [ ] Handle rate limits
- [ ] Add circuit breaker
- [ ] Create retry configs
- [ ] Test failure scenarios

### Retry Scenarios:
- Network errors
- Rate limits
- Service errors
- Timeout handling" \
  --assignee zeekay

# JavaScript SDK Repository Issues
echo -e "\n${YELLOW}=== JAVASCRIPT SDK REPOSITORY ===${NC}"

gh issue create --repo hanzoai/js-sdk \
  --title "Add TypeScript types generation" \
  --body "## Priority: HIGH
## Start Date: $(add_days 2 $TODAY)
## Due Date: $(add_days 5 $TODAY)
## Depends On: None

### Tasks:
- [ ] Generate types from OpenAPI
- [ ] Add type tests
- [ ] Create type utilities
- [ ] Add JSDoc comments
- [ ] Publish type definitions
- [ ] Update examples

### Deliverables:
- Complete type coverage
- Type generation script
- Type documentation" \
  --assignee zeekay

gh issue create --repo hanzoai/js-sdk \
  --title "Implement browser SDK bundle" \
  --body "## Priority: MEDIUM
## Start Date: $(add_days 6 $TODAY)
## Due Date: $(add_days 9 $TODAY)
## Depends On: TypeScript types

### Tasks:
- [ ] Create browser build
- [ ] Minimize bundle size
- [ ] Add polyfills
- [ ] CORS handling
- [ ] Create CDN version
- [ ] Test compatibility

### Target Browsers:
- Chrome/Edge 90+
- Firefox 90+
- Safari 14+
- Mobile browsers" \
  --assignee zeekay

# Go SDK Repository Issues
echo -e "\n${YELLOW}=== GO SDK REPOSITORY ===${NC}"

gh issue create --repo hanzoai/go-sdk \
  --title "Implement SDK code generation" \
  --body "## Priority: HIGH
## Start Date: $(add_days 3 $TODAY)
## Due Date: $(add_days 7 $TODAY)
## Depends On: None

### Tasks:
- [ ] OpenAPI to Go generator
- [ ] Custom templates
- [ ] Generate tests
- [ ] Add examples
- [ ] Create Makefile
- [ ] CI/CD integration

### Generated Code:
- Client methods
- Request/response types
- Error types
- Constants" \
  --assignee zeekay

# Platform Repository Issues
echo -e "\n${YELLOW}=== PLATFORM REPOSITORY ===${NC}"

gh issue create --repo hanzoai/platform \
  --title "Create application deployment wizard" \
  --body "## Priority: HIGH
## Start Date: $(add_days 4 $TODAY)
## Due Date: $(add_days 9 $TODAY)
## Depends On: None

### Tasks:
- [ ] Design wizard UI
- [ ] Git integration
- [ ] Build detection
- [ ] Resource sizing
- [ ] Deploy pipeline
- [ ] Progress tracking

### Supported Apps:
- Node.js
- Python
- Go
- Static sites
- Containers" \
  --assignee zeekay

gh issue create --repo hanzoai/platform \
  --title "Implement environment management" \
  --body "## Priority: HIGH
## Start Date: $(add_days 10 $TODAY)
## Due Date: $(add_days 14 $TODAY)
## Depends On: Deployment wizard

### Tasks:
- [ ] Environment creation
- [ ] Variable management
- [ ] Secret handling
- [ ] Environment cloning
- [ ] Promotion system
- [ ] Rollback capability

### Environments:
- Development
- Staging
- Production
- Preview/PR" \
  --assignee zeekay

# Blog Repository Issues
echo -e "\n${YELLOW}=== BLOG REPOSITORY ===${NC}"

gh issue create --repo hanzoai/blog \
  --title "Create technical blog series" \
  --body "## Priority: MEDIUM
## Start Date: $(add_days 7 $TODAY)
## Due Date: $(add_days 21 $TODAY)
## Depends On: None

### Content Calendar:
- [ ] Week 1: Intro to Hanzo AI Stack
- [ ] Week 2: Building with MCP
- [ ] Week 3: Multi-agent systems
- [ ] Week 4: Production deployment
- [ ] Week 5: Performance optimization
- [ ] Week 6: Security best practices

### Each Post:
- 2000+ words
- Code examples
- Diagrams
- Video walkthrough" \
  --assignee zeekay

# Team Repository Issues
echo -e "\n${YELLOW}=== TEAM REPOSITORY ===${NC}"

gh issue create --repo hanzoai/team \
  --title "Implement AI-powered project management" \
  --body "## Priority: MEDIUM
## Start Date: $(add_days 8 $TODAY)
## Due Date: $(add_days 15 $TODAY)
## Depends On: None

### AI Features:
- [ ] Smart task assignment
- [ ] Effort estimation
- [ ] Risk prediction
- [ ] Progress insights
- [ ] Bottleneck detection
- [ ] Resource optimization

### Integration:
- GitHub issues
- Time tracking
- Communication tools" \
  --assignee zeekay

# Site Repository Issues
echo -e "\n${YELLOW}=== SITE REPOSITORY ===${NC}"

gh issue create --repo hanzoai/site \
  --title "Redesign developer portal" \
  --body "## Priority: HIGH
## Start Date: $(add_days 5 $TODAY)
## Due Date: $(add_days 12 $TODAY)
## Depends On: None

### Sections:
- [ ] Getting started
- [ ] API reference
- [ ] SDKs & tools
- [ ] Tutorials
- [ ] Community
- [ ] Pricing

### Features:
- Interactive demos
- Code playground
- Search functionality
- User accounts" \
  --assignee zeekay

# Create Meta Issue in Stack Repository
echo -e "\n${YELLOW}=== CREATING META TRACKING ISSUE ===${NC}"

gh issue create --repo hanzoai/stack \
  --title "🎯 MASTER: Cross-Repository Development Tracking" \
  --body "## Master Tracking Issue for All Hanzo Repositories

This issue tracks all development work across the Hanzo ecosystem.

### Repository Status Overview

| Repository | Issues | Status | Priority | Timeline |
|------------|--------|--------|----------|----------|
| analytics | 3 | 🟡 In Progress | HIGH | Days 1-7 |
| iam | 3 | 🔴 Critical | CRITICAL | Days 1-10 |
| cloud | 3 | 🟡 In Progress | HIGH | Days 2-18 |
| python-sdk | 2 | 🟡 In Progress | HIGH | Days 1-8 |
| js-sdk | 2 | 🟡 In Progress | HIGH | Days 2-9 |
| go-sdk | 1 | 🟡 Planned | HIGH | Days 3-7 |
| platform | 2 | 🟡 Planned | HIGH | Days 4-14 |
| blog | 1 | 🟢 Planned | MEDIUM | Days 7-21 |
| team | 1 | 🟢 Planned | MEDIUM | Days 8-15 |
| site | 1 | 🟡 In Progress | HIGH | Days 5-12 |

### Gantt Chart Visualization

Since GitHub doesn't have native Gantt support, use these tools:

1. **GitHub Projects Timeline View**:
   - Go to: https://github.com/orgs/hanzoai/projects/32
   - Click 'New view' → 'Timeline'
   - Group by Repository
   - Set date fields

2. **External Gantt Tools**:
   - **TeamGantt**: Import from GitHub
   - **GanttLab**: Chrome extension for GitHub
   - **ZenHub**: Has Gantt charts
   - **Mermaid Gantt**: See below

### Mermaid Gantt Chart

\`\`\`mermaid
gantt
    title Hanzo AI Complete Development Timeline
    dateFormat YYYY-MM-DD
    
    section Core Infrastructure
    Runtime Fix           :crit, 2025-07-17, 4d
    IAM Fix              :crit, 2025-07-17, 2d
    IAM Permissions      :crit, 2025-07-17, 5d
    
    section Analytics
    Multi-tenant         :2025-07-17, 3d
    Custom Events        :2025-07-19, 3d
    Real-time           :2025-07-21, 3d
    
    section Cloud Platform
    IaC Templates        :2025-07-19, 5d
    Auto-scaling        :2025-07-25, 4d
    Cost Optimization   :2025-07-30, 5d
    
    section SDKs
    Python Async        :2025-07-18, 3d
    Python Retry        :2025-07-22, 3d
    JS TypeScript       :2025-07-19, 3d
    JS Browser          :2025-07-23, 3d
    Go Generation       :2025-07-20, 4d
    
    section Platform
    Deploy Wizard       :2025-07-21, 5d
    Environments        :2025-07-27, 4d
    
    section Content
    Blog Series         :2025-07-24, 14d
    Dev Portal          :2025-07-22, 7d
    
    section Team Tools
    AI Project Mgmt     :2025-07-25, 7d
\`\`\`

### Dependencies Graph

\`\`\`mermaid
graph TD
    A[Runtime Fix] --> B[MCP Service]
    A --> C[Agent Service]
    
    D[IAM Permissions] --> E[API Keys]
    D --> F[Team Hierarchy]
    D --> G[Multi-tenant Analytics]
    
    H[IaC Templates] --> I[Auto-scaling]
    I --> J[Cost Optimization]
    
    K[Python Async] --> L[Python Retry]
    M[JS TypeScript] --> N[JS Browser]
    
    O[Deploy Wizard] --> P[Environments]
\`\`\`

### Weekly Milestones

**Week 1 (Days 1-7)**
- ✅ Core infrastructure operational
- ✅ IAM system secure
- ✅ Analytics multi-tenant
- ✅ SDK foundations

**Week 2 (Days 8-14)**
- 🎯 Cloud automation ready
- 🎯 Platform deployment working
- 🎯 All SDKs published

**Week 3 (Days 15-21)**
- 🎯 Cost optimization active
- 🎯 Blog series started
- 🎯 Team tools integrated

### Tracking Instructions

1. **Update this issue daily** with progress
2. **Link all PRs** to their respective issues
3. **Use labels** consistently:
   - \`blocked\` - Waiting on dependency
   - \`in-progress\` - Active work
   - \`review\` - PR submitted
   - \`done\` - Completed

4. **Report blockers** immediately

### Success Metrics

- 📊 All critical issues resolved by Day 5
- 📊 SDK coverage at 100% by Day 10
- 📊 Platform fully automated by Day 15
- 📊 Documentation complete by Day 21

---

cc: @zeekay 
Track in Project: https://github.com/orgs/hanzoai/projects/32" \
  --label "tracking,meta" \
  --assignee zeekay

echo -e "\n${GREEN}✅ Created detailed issues across all repositories\!${NC}"
echo -e "${BLUE}📊 Summary:${NC}"
echo -e "- Analytics: 3 issues"
echo -e "- IAM: 3 issues" 
echo -e "- Cloud: 3 issues"
echo -e "- Python SDK: 2 issues"
echo -e "- JS SDK: 2 issues"
echo -e "- Go SDK: 1 issue"
echo -e "- Platform: 2 issues"
echo -e "- Blog: 1 issue"
echo -e "- Team: 1 issue"
echo -e "- Site: 1 issue"
echo -e "- Stack (Meta): 1 issue"
echo -e "${GREEN}Total: 20 new issues${NC}"

echo -e "\n${PURPLE}📈 Setting up Gantt visualization...${NC}"
echo -e "1. Install GanttLab Chrome extension"
echo -e "2. Or use GitHub Projects Timeline view"
echo -e "3. Or copy Mermaid charts to visualizer"
