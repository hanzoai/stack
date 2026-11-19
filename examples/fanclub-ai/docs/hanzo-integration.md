# Hanzo OS integration contracts — FanClub AI

This is a migration plan, not a claim that all integrations are deployed or that this prototype constitutes the canonical Hanzo OS runtime.

## Authoritative vertical slice

```text
hanzo up                          (UDE lifecycle — target, version-verify)
  hanzo.config.ts                  (one app manifest — contract in reconciliation)
    Hanzo Cloud                    (authoritative host/API surface)
      ├── IAM identity              (validated org + principal)
      ├── Framework / Base          (tenant-scoped DocTypes and durable records)
      ├── Engine                    (private model serving + eval interfaces)
      ├── MCP tools                 (typed permissions, no arbitrary execution)
      └── Agent sandbox            (event-triggered, bounded, durable invocation)
        └── FanClub AI UI          (member/approval/playbooks interface)
```

Local prototype currently uses HTTP + Node's SQLite to demonstrate behavior; that **must be replaced**, not expanded into a parallel datastore, before canonical production integration.

## Required data contracts

| Concept | Candidate DocType | Fields | Controller |
|---|---|---|---|
| Organization | `fc.organization` | ID, industry, configuration, locale, permitted actions | IAM / authoritative config |
| Person | `fc.person` | ID, tenant, membership, identity refs, consent, status | Framework/Base |
| Engagement | `fc.engagement` | person ID, event type, occurrence, source, legal basis | Framework/Base |
| Decision | `fc.decision` | program, evidence references, version, result, confidence | decision service |
| Proposal | `fc.proposal` | recommended action, policy, person, approver, status | Framework/Base |
| Action | `fc.action` | authorized operation, idempotency key, execution receipt | MCP / sandbox |
| Outcome | `fc.outcome` | intervention, control group, result, value, cost | Framework/Base / Insights |
| Model | `fc.model_artifact` | base rights, dataset lineage, hash, revision, evaluation, deployment | model registry |

Production APIs must use canonical versioned Hanzo Cloud routes. Do **not** assume `/v1/framework` details until confirmed by the Cloud host and OpenAPI contract. Avoid exposing a new standalone public port per service.

## Tool/action contract

1. The agent may *propose* an action as structured data, with evidence references and permitted scope.
2. A verified IAM actor must grant human approval for side effects.
3. A typed MCP call with allowed target, tenancy, input schema and idempotency token is evaluated.
4. A short-lived, isolated sandbox runs the call and terminates.
5. Receipt + status + provenance become authoritative records. Retries cannot duplicate the external effect.
6. Measurement and exception handling proceed through separate durable events.

No permanently running bot processes; event-driven invocation only.

## Customer-owned private AI

Baseline first: deterministic policy, logistic regression or compact tree model as applicable. Evaluate specialized training only where real labels and customer data rights permit it.

For an actual fine-tuning/model-development lifecycle:
1. Data-authority assessment and protected dataset ingestion.
2. Reproducible train/validation/temporal holdout splits.
3. Versioned training run using supported `hanzoai/ml` or `hanzoai/engine` capabilities.
4. Real saved checkpoint or PEFT adapter, with source/base model licence recorded.
5. Hardware profile, eval and shadow-mode qualification.
6. Signed model artifact/registry and tenant-approved promotion to Engine.
7. Rollback, drift inspection and recovery tests.

An adapter to a base with restricted rights is **not** automatically an independent customer-owned model. Customer model ownership and custody must be in the agreement.

## Runtime architecture / HIPs

- HIP-0006: Personalized adaptation is a proposal/standard, not per-tenant fine-tuning proof.
- HIP-0043: Hanzo Engine inference standard.
- HIP-0117: Cloud-in-a-Box; local/cluster profile.
- HIP-0130: Open-core ownership and tenancy split.
- HIP-0134: Internal process/socket/identity boundaries.
- HIP-0300: Unified MCP.

Treat `hanzo.config.ts`, Dockerless `hanzo up`, full local Kubernetes readiness, GPU fine-tuning and 8 GB Mac fit as qualification targets until proven in one integrated build. Official repo contracts take precedence over illustrative examples.

## FC-1 / FC-2

Prior agent reports mention FC-1 and FC-2, but their formal acceptance specifications were not locatable in the accessible public repository. Do not silently redefine those specs. Map this demo's persistence/approval and inference/tool loops against the actual FC-1/FC-2 contracts when those documents or code branches are available.

## Progressive delivery

- **Reference v0.1, implemented:** synthetic app, 3 fictional tenants, local SQLite, decision rules, approvals, audit, local-engine optional connector, unit/integration tests.
- **FC integration milestone:** authoritative Cloud/Framework DocTypes and verified IAM identity, replacing demo SQLite and user-selected tenant scopes.
- **Private AI milestone:** Engine inference through sanctioned Cloud routing, real model evaluation/registry, explicit train-to-serve acceptance.
- **Enterprise milestone:** authorized MCP tools, short-lived sandbox, tenant isolation, regional deploy, recovery, egress tests, per-tenant costs.

## Evidence gates

No claim is 'done' without executed tests and records of: repository SHA, sample fixtures, command outputs, platform/driver, model SHA, latency, resource budget, private-mode egress, auth negative tests, rollback and signoff.