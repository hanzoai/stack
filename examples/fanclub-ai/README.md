# FanClub AI · Hanzo OS reference application

**A fictional, multi-industry demonstration of privately operated organization intelligence.** FanClub AI is a **product concept**, not an existing customer, an announced spin-off, a live football deployment or a production-certified Hanzo OS installation.

**Hanzo AI** is the technology and engineering partner. **Hanzo OS** is the open-source framework and standards. This application is an optional demonstration of the desired product experience, not a new replacement for Hanzo Cloud, Framework, Base, IAM, Engine or MCP.

## Run the prototype

Requires Node.js 22.13+; no npm packages, Docker or cloud account required.

```bash
cd examples/fanclub-ai    # if checked out in hanzoai/stack
npm start
# http://127.0.0.1:4377
```

Or extract the standalone ZIP and run `npm start` from its root. The prototype binds to **127.0.0.1 only**. It contains no production login and must **never** be exposed to the public Internet or loaded with personal data.

```bash
npm run check
npm test
```

The app stores persistent synthetic records in `.data/fanclub.sqlite` using Node's built-in SQLite. To reset the fictional workspace, stop the app and remove `.data/fanclub.sqlite*`.

## What you can actually do

- Switch between **Northstar United** (club), **Solstice Museum** (arts organization) and **Harbor Alliance** (member association).
- Inspect a real read/write SQLite database with **90 reproducible fictional members per tenant**. Member names, marketing consents, engagement, value and outcomes are synthetic.
- Run an explicit **deterministic risk-scoring baseline** and view its actually computed synthetic holdout precision/recall/accuracy. This is neither trained AI nor measured real-world uplift.
- Create approval proposals from three reusable journeys: Renewal Radar, Second Visit, Membership Growth.
- Approve or reject actions; approval writes an auditable **simulation event only**. The code has no email, payment, advertising or price-change side effects.
- Ask the AI Studio questions: the default is openly labeled deterministic rules. Set `HANZO_ENGINE_URL` and `HANZO_ENGINE_MODEL` to connect a **real local OpenAI-compatible Hanzo Engine** for summary generation. Only fictional aggregate metrics, not individual member records, are sent to it.
- Inspect a component-readiness view that clearly labels **local adapter**, **configured integration**, and **unimplemented production gate**.

## Supported inference configuration

```bash
# Start Hanzo Engine using the verified version-specific command and local model.
# Only then configure the reference app:
HANZO_ENGINE_URL=http://127.0.0.1:36900 \
HANZO_ENGINE_MODEL=zen6-nano npm start
```

The actual Engine installation and model selection must be verified against the checked-out Hanzo version and local hardware. This app sends `POST /v1/chat/completions` with non-sensitive aggregate synthetic metrics; if the configured Engine is unavailable, it shows an explicit error rather than silently claiming AI ran.

## Hanzo OS integration plan

This prototype does **not** duplicate or claim completion of the authoritative Hanzo stack. Read [docs/hanzo-integration.md](docs/hanzo-integration.md) for the exact replacement boundaries: Hanzo Cloud/Framework for authoritative records, IAM for authenticated tenancy, Engine for private inference, MCP for authorized actions, event-driven sandbox for agent execution, and native `hanzo up` orchestration.

The implementation in this folder intentionally has **no live integration with a FanGrowth project, real club systems, or real user accounts**. It is a self-contained first vertical slice while the unified `hanzo up` manifest/API and FC-1/FC-2 formal acceptance contracts are reconciled.

## Rebrand it for any industry

See [docs/white-label.md](docs/white-label.md). The same `Member → Engagement → Decision → Approval → Outcome` data contract can become an association, alumni, museum, nonprofit, workforce, education or loyalty reference system. Change a single tenant's noun, business events, workstreams and policies without forking the infrastructure.

## Safety, licensing and ownership

- All fixture names and metrics are invented. Do not use them as customer claims.
- Current local tenant switching is for a demonstration only and **not** tenant security. Production must derive `org` from a verified IAM principal; never trust a browser-selected tenant identifier.
- Current `.data/` is not encrypted, append-only or tamper-evident; production requires approved storage and audit controls.
- There is no integrated training, fine-tuning, AI registry, backup/restore, production DPA, or external action connector. Such capabilities are roadmap/integration gates, not present features.
- The framework is composed of independently licensed repositories. Verify LICENSE, dependencies, model-weight rights, deployment permissions and exact revisions prior to use.

**Reference code for review; do not infer any production endorsement or customer agreement.**