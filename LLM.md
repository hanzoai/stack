# Hanzo Stack

OSS quickstart that runs the whole Hanzo platform locally from published `ghcr.io/hanzoai/*` images — `docker compose up -d`, no source/build. Quickstart only: for service development use `hanzoai/universe` (the mono), for production k8s use `hanzoai/operator`, for PaaS use platform.hanzo.ai.

## Layout
- `compose.yml` — base stack (Postgres/Redis/DocDB/MinIO/Meilisearch/Qdrant/Temporal + LLM gateway, chat, MCP, agent, runtime, search, IAM, cloud, commerce, console, base).
- Overlays: `compose.override.yml`, `compose.amd64.yml`, `compose.emulation.yml`, `compose.adnexus.yml`.
- `config/`, `env.example`, `env.core.example` — copy env to `.env`; only LLM API keys (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`) typically need setting.
- `Makefile` — convenience targets.

## Commands
- All services: `docker compose up -d`
- Logs / nuke: `docker compose logs <svc>` · `docker compose down -v`

Defaults to `:latest`; pin via your own `compose.override.yml`.

Full docs: README.md
