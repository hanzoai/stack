# FanClub AI — general-purpose white-label application archetype

FanClub AI is a fictional demonstration brand for a **member-centric intelligence operating system**. The real reusable vertical is a configurable organization platform, not sport-specific software.

| Deployment | Person concept | Primary event | Decision | Human-approved action | Outcome |
|---|---|---|---|---|---|
| Sports club | Supporter | Ticket / visit / membership | Renewal, attendance, upgrade | Contact/offer | Incremental contribution |
| Arts institution | Patron | Visit / donation / membership | Return visit, giving, renewal | Invitation | Retention / donation margin |
| Association | Member | Dues / event / certification | Renewal, participation | Outreach task | Renewal / participation |
| Alumni | Alum | Donation / reunion / engagement | Participation, giving | Campaign draft | Engagement / gifts |
| Education | Learner | Enrollment / activity / support request | Support triage | Staff review | Completion / service quality |
| Workforce | Employee | Training / engagement / benefits | Help request routing | HR-reviewed action | Resolution time |
| Subscription commerce | Account | Payment / product use / renewal | Churn, next action | CS-reviewed intervention | Net contribution |

## Non-negotiable abstractions

1. Verified organization tenancy from IAM, not a frontend selector.
2. Record source attribution and human-facing consent/policy context.
3. Real evidence-driven decision contract with explicit failure/uncertainty state.
4. Human approval before side effects.
5. Idempotent execution and durable outcome record.
6. Experiment/holdout method for any claimed causal uplift.
7. Pinned model versions, datasets and licences.
8. Reversible, exportable and independently operable customer-specific application state.

## Minimum white-label configuration (illustrative only)

```ts
export const organization = {
  brand: 'Your Organization AI',
  personNoun: 'members',
  decisions: ['retention', 'engagement', 'membership-growth'],
  allowedActions: ['draft', 'ask-human', 'simulate'],
  privacy: { tenantIsolation: 'required', crossTenantLearning: 'off' },
  inference: { mode: 'private', externalFallback: false },
};
```

This is app-level configuration, **not** a claim these exact keys are accepted by `hanzo.config.ts` yet.

## Research / G1 opportunity

Specific organizational models should be chosen empirically, not licensed wholesale or named in the product pitch. Benchmark simple statistical methods against compact specialized models, and add optional language drafting only when justified by price and user experience. Cross-organization learning is a separate opt-in research program after contractual rights, secure aggregation and privacy-attack evaluation.