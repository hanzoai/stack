// Simple agent definition for health wellness lead automation
import { createAgent } from '@hanzo/base';

export const HealthAgent = createAgent({
  name: 'HealthAgent',
  description: 'Automates health wellness lead follow-up and status progression.',
  workflow: [
    { stage: 'enquiry', action: 'send_sms_greeting' },
    { stage: 'contacted', action: 'schedule_consultation' },
  ],
});