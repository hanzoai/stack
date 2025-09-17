# Platform Compatibility Guide

## Overview
This guide addresses platform compatibility issues when running Hanzo Stack on different architectures.

## Known Issues

### 1. ARM64 Images on AMD64 Host
Several services are built for ARM64 but need to run on AMD64:
- Runtime
- Analytics
- IAM
- IDE

**Solution**: Use `docker-compose.amd64.yml` override:
```bash
docker compose -f compose.yml -f docker-compose.amd64.yml up -d
```

### 2. Chat Service Startup Script
The Chat service is missing the "backend" npm script.

**Temporary Fix**: Use the provided startup script:
```bash
docker exec hanzo-chat /app/scripts/fix-chat-startup.sh
```

## Platform Detection

Check your platform:
```bash
uname -m  # Shows machine architecture
docker version --format '{{.Server.Arch}}'  # Shows Docker architecture
```

## Multi-Platform Build

To build images for multiple platforms:
```bash
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -t image:tag --push .
```

## Environment-Specific Configurations

### For AMD64 (x86_64)
```bash
export DOCKER_DEFAULT_PLATFORM=linux/amd64
docker compose -f compose.yml -f docker-compose.amd64.yml up -d
```

### For ARM64 (Apple Silicon, ARM servers)
```bash
export DOCKER_DEFAULT_PLATFORM=linux/arm64
docker compose up -d
```

## CI/CD Considerations

GitHub Actions runs on AMD64 by default. Ensure your CI workflows specify:
```yaml
runs-on: ubuntu-latest  # AMD64
# or
runs-on: [self-hosted, linux, ARM64]  # For ARM64 runners
```

## Testing Across Platforms

Run platform-specific tests:
```bash
# Test on AMD64
docker run --platform linux/amd64 image:tag npm test

# Test on ARM64
docker run --platform linux/arm64 image:tag npm test
```

## Troubleshooting

### Error: "The requested image's platform does not match"
This warning can be ignored if the container runs successfully. To suppress:
```bash
export DOCKER_CLI_HINTS=false
```

### Performance Issues with Emulation
Running ARM64 images on AMD64 (or vice versa) uses QEMU emulation, which is slower. For production, use native platform images.

## Recommended Solution

Build and push multi-platform images to the registry:
```bash
# In each service directory
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/hanzoai/service:latest \
  --push .
```

This ensures native performance on all platforms.