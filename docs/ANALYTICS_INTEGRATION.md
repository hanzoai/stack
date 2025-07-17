# Hanzo Stack Analytics Integration

## Overview

The Hanzo Stack includes comprehensive analytics tracking across all user-facing services using a self-hosted, privacy-focused analytics platform.

## Architecture

### Analytics Service
- **Host**: https://a.hanzo.ai (production)
- **Local**: http://localhost:3090 (development)
- **Tracking Script**: `hanzo.js`
- **Database**: PostgreSQL with dedicated analytics database

### Integration Methods

#### 1. Nginx Proxy Injection (Primary Method)
All user-facing services have analytics automatically injected via nginx reverse proxy:
- Chat (chat.hanzo.ai)
- IDE (ide.hanzo.ai)
- Search (search.hanzo.ai)
- Flow (flow.hanzo.ai)
- Cloud (cloud.hanzo.ai)
- App (app.hanzo.ai)

#### 2. Direct Script Integration (Alternative)
For services that bypass nginx or need custom tracking:
```html
<script async defer 
  data-website-id="your-service-id" 
  src="https://a.hanzo.ai/hanzo.js" 
  data-host-url="https://a.hanzo.ai">
</script>
```

#### 3. Custom Tracker Script
Use the provided `scripts/analytics-tracker.js` for advanced integration:
```html
<script src="/analytics-tracker.js"></script>
```

## Website IDs

Each service has a unique website ID for tracking:

| Service | Production ID | Development ID |
|---------|--------------|----------------|
| Chat | chat-hanzo-ai | chat-hanzo-ai-dev |
| IDE | ide-hanzo-ai | ide-hanzo-ai-dev |
| Search | search-hanzo-ai | search-hanzo-ai-dev |
| Flow | flow-hanzo-ai | flow-hanzo-ai-dev |
| Cloud | cloud-hanzo-ai | cloud-hanzo-ai-dev |
| App | app-hanzo-ai | app-hanzo-ai-dev |

## Custom Event Tracking

Use the `hanzoTrack` function for custom events:

```javascript
// Track a custom event
hanzoTrack('button-click', {
  button: 'submit',
  page: 'checkout'
});

// Track user actions
hanzoTrack('feature-used', {
  feature: 'ai-completion',
  model: 'gpt-4'
});
```

## Environment Variables

```bash
# Analytics Service Configuration
ANALYTICS_PORT=3090
ANALYTICS_DATABASE_URL=postgresql://analytics:analytics123@postgres:5432/analytics
ANALYTICS_SECRET=your-secret-key
ANALYTICS_TRACKER_SCRIPT=hanzo.js
ANALYTICS_DISABLE_BOT_CHECK=false
ANALYTICS_PRIVATE_MODE=false

# Enable/Disable Analytics
ENABLE_ANALYTICS=true  # Set to false to disable all tracking
```

## Privacy & Compliance

- No cookies used by default
- GDPR compliant
- Respects Do Not Track headers
- No personal data collection
- IP anonymization enabled
- Data stored in self-hosted infrastructure

## Testing Analytics

1. Start the stack with analytics enabled:
```bash
docker compose up -d
```

2. Access the analytics dashboard:
```
http://localhost:3090
```

3. Visit any service and verify tracking:
- http://chat.localhost
- http://ide.localhost
- http://search.localhost

4. Check real-time data in the analytics dashboard

## Troubleshooting

### Analytics Not Tracking
1. Check if nginx is running: `docker ps | grep nginx`
2. Verify analytics service is healthy: `docker logs hanzo-analytics`
3. Check browser console for errors
4. Ensure `ENABLE_ANALYTICS=true` in environment

### Custom Events Not Working
1. Verify `hanzoTrack` function is available in console
2. Check if umami script is loaded
3. Look for queued events in `window._hanzoEventQueue`

### Development Setup
For local development without nginx:
1. Add analytics script directly to your HTML
2. Use development website IDs
3. Point to local analytics instance

## Adding Analytics to New Services

1. Create nginx configuration:
```nginx
server {
    listen 80;
    server_name newservice.localhost;
    
    location / {
        proxy_pass http://newservice:PORT;
        # ... proxy headers ...
        
        # Inject analytics
        sub_filter '</head>' '<script async defer data-website-id="newservice-hanzo-ai" src="https://a.hanzo.ai/hanzo.js" data-host-url="https://a.hanzo.ai"></script></head>';
        sub_filter_once on;
        sub_filter_types text/html;
    }
}
```

2. Add to compose.yml nginx volumes:
```yaml
volumes:
  - ./nginx/newservice-analytics.conf:/etc/nginx/conf.d/newservice.conf:ro
```

3. Register website ID in analytics dashboard

## API Usage

Track events server-side:
```bash
curl -X POST https://a.hanzo.ai/api/send \
  -H "Content-Type: application/json" \
  -d '{
    "type": "event",
    "payload": {
      "website": "your-website-id",
      "name": "api-call",
      "data": {"endpoint": "/v1/chat", "status": 200}
    }
  }'
```