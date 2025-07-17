#\!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Adding all issues to Hanzo AI Project #32...${NC}"

# Get project ID
PROJECT_ID="PVT_kwDOFySR0s4Alz-B"  # This is project 32

# Function to add issue to project
add_to_project() {
    local issue_url=$1
    local repo=$(echo $issue_url | cut -d'/' -f4-5)
    local issue_num=$(echo $issue_url | cut -d'/' -f7)
    
    echo "Adding $repo#$issue_num to project..."
    
    # Get issue node ID
    ISSUE_ID=$(gh api repos/$repo/issues/$issue_num --jq .node_id 2>/dev/null)
    
    if [ \! -z "$ISSUE_ID" ]; then
        # Add to project
        gh api graphql -f query='
        mutation($project: ID\!, $item: ID\!) {
          addProjectV2ItemById(input: {projectId: $project, contentId: $item}) {
            item {
              id
            }
          }
        }' -f project="$PROJECT_ID" -f item="$ISSUE_ID" >/dev/null 2>&1
        
        echo -e "${GREEN}✓ Added${NC}"
    else
        echo -e "${RED}✗ Failed to get issue ID${NC}"
    fi
}

# List of all repositories to check
REPOS=(
    "hanzoai/stack"
    "hanzoai/router"
    "hanzoai/chat"
    "hanzoai/ide"
    "hanzoai/mcp"
    "hanzoai/agent"
    "hanzoai/analytics"
    "hanzoai/runtime"
    "hanzo-io/iam"
    "hanzoai/search"
    "hanzoai/flow"
    "hanzoai/cloud"
    "hanzoai/python-sdk"
    "hanzoai/js-sdk"
    "hanzoai/go-sdk"
    "hanzo-io/platform"
    "hanzoai/team"
    "hanzoai/hanzo.ai"
)

# Get recent issues from each repo and add to project
for repo in "${REPOS[@]}"; do
    echo -e "\n${YELLOW}Processing $repo...${NC}"
    
    # Get issues created today
    ISSUES=$(gh issue list --repo $repo --state open --limit 50 --json number,createdAt,url --jq '.[] | select(.createdAt | startswith("2025-07-17")) | .url' 2>/dev/null)
    
    if [ \! -z "$ISSUES" ]; then
        while IFS= read -r issue_url; do
            add_to_project "$issue_url"
        done <<< "$ISSUES"
    fi
done

echo -e "\n${GREEN}✅ Finished adding issues to project\!${NC}"
echo -e "${GREEN}View project at: https://github.com/orgs/hanzoai/projects/32${NC}"

# Create Gantt visualization guide
cat > GANTT_SETUP.md << 'EOG'
# Setting Up Gantt Chart for GitHub Project

## Option 1: GitHub Projects Timeline View (Native)

1. Go to https://github.com/orgs/hanzoai/projects/32
2. Click the dropdown next to "Table" view
3. Select "New view"
4. Choose "Timeline" layout
5. Configure:
   - Group by: Repository
   - Date field: Due Date (or custom date field)
   - Sort by: Start date

## Option 2: Browser Extensions

### GanttLab (Recommended)
1. Install: https://chrome.google.com/webstore/detail/ganttlab
2. Navigate to project
3. Click GanttLab icon
4. Configure date fields

### ZenHub
1. Install: https://www.zenhub.com/
2. Provides native Gantt charts
3. Free for public repos

## Option 3: External Tools

### Mermaid Live Editor
1. Go to: https://mermaid.live/
2. Paste the Gantt chart from the meta issue
3. Export as PNG/SVG

### TeamGantt
1. Import from GitHub: https://www.teamgantt.com/
2. Sync with GitHub issues
3. Real-time updates

## Option 4: Custom Fields Setup

To enable better Gantt visualization, add these fields to your project:

1. In project settings, add fields:
   - Start Date (Date type)
   - Due Date (Date type)
   - Duration (Number type)
   - Depends On (Text type)
   - Progress (Number type, 0-100)

2. Update issues with date information

3. Use Timeline view with these fields

## Automation

Set up GitHub Actions to automatically:
- Add issues to project
- Set dates based on labels
- Update progress based on PR status

Example workflow available at: hanzoai/stack/.github/workflows/project-automation.yml
EOG

echo -e "\n${YELLOW}📊 Created GANTT_SETUP.md with detailed instructions${NC}"
