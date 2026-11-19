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


## Optional demo: FanClub AI

- `examples/fanclub-ai/` is a **fictional, industry-neutral** reference product with three organizations (sports, culture, association), not a real FanGrowth deployment.
- Start with `examples/fanclub-ai/README.md`, `docs/hanzo-integration.md` and `docs/white-label.md`; use `npm start` and `npm test` from the demo directory.
- The demo server's Node SQLite adapter and tenant selector are *not* authoritative Hanzo Base/Framework or IAM; NEVER claim production tenancy or customer data isolation from this proof of concept.
- Inference defaults to a disclosed deterministic baseline; `HANZO_ENGINE_URL` configures optional real local text inference with aggregate synthetic metrics.
- A human approval records only a simulated action; no outbound CRM messages or commerce payments are emitted.
- Reuse Cloud, Framework, Base, IAM, Engine and MCP to implement real FC-1 / FC-2 integration; do not invent duplicate production backend or train-to-serve claims.
- `hanzo.config.example.ts` illustrates the target UDE only; it is NOT a tested current CLI manifest.
- The `/stack`, `/framework`, `/oss` site paths are **website routes**, not GitHub directories. Do not claim this repository change deploys those routes.
