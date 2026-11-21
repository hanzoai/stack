# Hanzo Stack

OSS quickstart that runs the whole Hanzo platform locally from published `ghcr.io/hanzoai/*` images.

## Documentation
- `hanzo.ai/stack` — The core platform, HIPS (Hanzo OS Integration Standards), and services.
- `hanzo.ai/framework` — The Hanzo app framework and TypeScript SDK.
- `hanzo.ai/oss` — Browseable OSS catalog, including FanClub AI, TradeCRM, DeliveryERP, BlogCMS, LedgerAgent, and FormationAgent prototypes.

## Layout
- `compose.yml` — base stack.
- `hanzo.config.ts` — Production-standard application definition (HIPS-compliant).
- `examples/` — Industry-neutral reference prototypes (`fanclub-ai`, etc.).
- `services/` — Native platform service definitions.

## HIPS Standards
- Identity: `hanzo.iam` required.
- Storage: `hanzo.datastore` required.
- MCP: `hanzo.mcp` sandbox required for agentic actions.
- Models: Zen (Qwen3) inference via `hanzo.engine`.
- Ledger: `ledger-agent` for accrual-basis bookkeeping (HIP-05).
- Formation: `formation-agent` for Delaware C-Corp incorporation and RA (HIP-06).

## Commands
- All services: `docker compose up -d`
- Logs / nuke: `docker compose logs <svc>` · `docker compose down -v`

Full docs: README.md