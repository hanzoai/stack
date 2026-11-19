// Illustrative future UDE declaration. NOT yet an accepted CLI schema.
// The canonical hanzo.config.ts API must be reconciled with Hanzo CLI + HIPs.
export default {
  name: 'fanclub-ai-reference',
  runtime: { private: true, mode: 'local' },
  cloud: { enabled: true },
  framework: { module: 'fc' },
  engine: { enabled: true, models: ['select-after-hardware-qualification'] },
  iam: { enabled: true },
  mcp: { enabled: true },
  agents: { lifecycle: 'event-driven', sandboxed: true, network: 'deny' },
  app: { source: './public' },
};
