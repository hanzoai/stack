# Hanzo Stack Setup Summary

## Changes Made

### 1. **Rebranded and Updated Build Service**
- The `app-builder` service has been renamed to `build` (Hanzo Build - OpenHands fork)
- Updated in both `compose.yml` and `compose.dev.yml`
- Service runs on port 3002 (mapped from internal port 3000)
- Added proper environment variables for workspace mounting and sandbox configuration
- Added `build_workspace` volume for persistent workspace data

### 2. **Fixed Chat Service**
- Created `Dockerfile.librechat` for proper LibreChat deployment
- The chat directory contains LiteLLM proxy, not LibreChat itself
- Updated both compose files to use the new Dockerfile
- Chat service configured to work with Hanzo branding

### 3. **Fixed Cloud Service**
- Verified the Cloud service Dockerfile is correct
- Multi-stage build with development and production targets
- Properly configured for Next.js application

### 4. **Added IAM Service (Casdoor)**
- Added IAM service to both `compose.yml` and `compose.dev.yml`
- Uses Casdoor for unified authentication
- Configured to use PostgreSQL backend
- Runs on port 8000
- Added `iam_data` volume for persistent configuration

### 5. **Updated Docker Compose Files**

#### compose.yml (Production)
- Updated app-builder → build service
- Added IAM service configuration
- Added volumes: `build_workspace`, `iam_data`
- All services properly networked via `hanzo-network`

#### compose.dev.yml (Development)
- Updated app-builder → build service with development mode
- Added IAM service with development configuration
- Added volume mounts for hot-reloading
- Added `build_logs` volume for development logging

## Service Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Hanzo Build   │     │   Hanzo Chat   │     │   Hanzo Cloud   │
│   (OpenHands)   │     │   (LibreChat)   │     │  (Next.js App)  │
│   Port: 3002    │     │   Port: 3081    │     │   Port: 3001    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │                       │
         └───────────────────────┴───────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │      Hanzo IAM          │
                    │     (Casdoor SSO)       │
                    │      Port: 8000         │
                    └─────────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   PostgreSQL    │     │     MongoDB     │     │      Redis      │
│   Port: 5432    │     │   Port: 27017   │     │   Port: 6379    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## Next Steps

1. **Start the Stack**:
   ```bash
   cd /Users/z/work/hanzo/stack
   docker compose up -d
   ```

2. **For Development**:
   ```bash
   docker compose -f compose.yml -f compose.dev.yml up
   ```

3. **Access Services**:
   - Build (OpenHands): http://localhost:3002
   - Chat (LibreChat): http://localhost:3081
   - Cloud: http://localhost:3001
   - IAM (Casdoor): http://localhost:8000
   - Router (LiteLLM): http://localhost:4000

4. **Configure IAM Integration**:
   - Set up OAuth applications in Casdoor for each service
   - Update environment variables with OAuth credentials
   - Enable SSO across all services

## Remaining Tasks

1. **Sync Latest OpenHands Changes** (Low Priority):
   - Review changes in `/Users/z/work/allhands/OpenHands`
   - Cherry-pick relevant updates while preserving Hanzo customizations
   - Test thoroughly after syncing

2. **Configure Unified Authentication**:
   - Set up Casdoor applications for each service
   - Configure OAuth2/OIDC integration
   - Test single sign-on functionality

3. **Production Deployment**:
   - Update environment variables for production
   - Configure SSL/TLS certificates
   - Set up proper domain names
   - Enable production security features