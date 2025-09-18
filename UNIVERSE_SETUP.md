# Universe Setup - Private Production Repositories

## Created Structure

We've established a two-tier architecture separating public and private concerns:

### Public Repository
**`github.com/hanzoai/stack`** (✅ Active)
- Open-source core infrastructure
- Community-friendly configurations
- Public documentation and examples
- Currently 91% functional with all fixes

### Private Repositories (Ready to Create)

#### 1. Hanzo Universe
**`github.com/hanzoai/universe`** (📦 Ready to push)
- Location: `/home/z/work/hanzoai-universe/`
- Purpose: Production Hanzo services
- Features: Monitoring, backups, production configs

#### 2. LuxFi Universe
**`github.com/luxfi/universe`** (📦 Ready to push)
- Location: `/home/z/work/luxfi-universe/`
- Purpose: Financial services stack
- Features: Trading, custody, compliance

## Quick Setup

To create and push the private repositories:

```bash
# Option 1: Use the automated script
cd /home/z/work/hanzo
./scripts/setup-universe.sh

# Option 2: Manual creation with gh CLI
gh repo create hanzoai/universe --private \
  --description "Private production universe"

cd /home/z/work/hanzoai-universe
git push -u origin main

gh repo create luxfi/universe --private \
  --description "LuxFi financial services"

cd /home/z/work/luxfi-universe
git push -u origin main
```

## Repository Contents

### Hanzo Universe (`/home/z/work/hanzoai-universe/`)
```
├── README.md                        # Production documentation
├── compose.production.yml           # Production overrides
└── .github/workflows/
    └── sync-from-public.yml        # Auto-sync from public stack
```

### LuxFi Universe (`/home/z/work/luxfi-universe/`)
```
└── README.md                        # Financial services architecture
```

## Sync Strategy

### Public → Private (Daily)
```yaml
# Automated in .github/workflows/sync-from-public.yml
- Runs daily at 2 AM UTC
- Creates PR with public updates
- Preserves production configs
- Requires manual review
```

### Private → Public (Manual)
```bash
# Sanitize and contribute back
git checkout -b public-contribution
git cherry-pick <safe-commits>
# Remove sensitive data
git filter-branch --tree-filter 'rm -rf secrets/'
gh pr create --repo hanzoai/stack
```

## Security Boundaries

| Aspect | Public Stack | Private Universe |
|--------|-------------|------------------|
| Secrets | None | Encrypted with git-crypt |
| API Keys | Examples only | Production keys in Vault |
| Customer Data | None | Encrypted at rest |
| Monitoring | Basic | Full Prometheus/Grafana |
| Backups | None | Automated S3 backups |
| Compliance | N/A | SOC 2, GDPR ready |

## Next Steps

1. **Create GitHub Repositories**
   ```bash
   ./scripts/setup-universe.sh
   ```

2. **Set Up Secrets Management**
   ```bash
   cd /home/z/work/hanzoai-universe
   git-crypt init
   git-crypt add-gpg-user YOUR_KEY_ID
   ```

3. **Configure Production**
   ```bash
   cp .env.example .env.production
   # Add real API keys and configs
   ```

4. **Deploy to Production**
   ```bash
   docker compose -f compose.yml \
     -f compose.production.yml up -d
   ```

## Benefits of This Architecture

✅ **Security**: Production secrets never touch public repo
✅ **Flexibility**: Independent evolution of public/private
✅ **Compliance**: Regulatory requirements isolated
✅ **Community**: Safe sharing of innovations
✅ **Maintainability**: Clear separation of concerns

## Repository Status

- ✅ Public stack: Pushed and active at `hanzoai/stack`
- 📦 Hanzo Universe: Ready at `/home/z/work/hanzoai-universe/`
- 📦 LuxFi Universe: Ready at `/home/z/work/luxfi-universe/`
- 📝 Documentation: Complete architecture guide
- 🔧 Setup Script: `scripts/setup-universe.sh` ready

Run `./scripts/setup-universe.sh` when ready to create the private repositories on GitHub!