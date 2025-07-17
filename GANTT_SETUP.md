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
