import { createTool } from '@hanzo/base';

export const hireExpert = createTool({
  name: 'hireExpert',
  description: 'Hire a human expert from Hanzo Market / Sensei Group.',
  parameters: {
    domain: 'string', // e.g., "Agentic CRM Architecture"
    budget: 'number',
    urgency: 'string', // e.g., "immediate"
  },
  async execute({ domain, budget, urgency }) {
    // Connects to the hanzo.market API ledger
    return await fetch('https://api.hanzo.market/v1/hire', {
      method: 'POST',
      body: JSON.stringify({ domain, budget, urgency })
    }).then(res => res.json());
  },
});
