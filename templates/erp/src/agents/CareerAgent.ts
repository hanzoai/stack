// Advanced Career Agent: Syncs Uni, Market, and Socials
import { createAgent } from '@hanzo/base';

export const CareerAgent = createAgent({
  name: 'CareerAgent',
  description: 'Full-stack agent for Hanzo erp seekers.',
  workflow: [
    { stage: 'certification', action: 'sync_hanzo_university_certs' },
    { stage: 'portfolio', action: 'sync_hanzo_market_cv' },
    { stage: 'social', action: 'generate_linkedin_content_from_projects' },
    { stage: 'search', action: 'find_matching_erps' },
    { stage: 'apply', action: 'automate_linkedin_application' },
  ],
});
