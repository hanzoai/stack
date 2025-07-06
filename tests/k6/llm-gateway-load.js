import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const responseTime = new Trend('response_time');

// Test configuration
export const options = {
  stages: [
    { duration: '30s', target: 10 },   // Ramp up to 10 users
    { duration: '1m', target: 50 },    // Ramp up to 50 users
    { duration: '2m', target: 100 },   // Stay at 100 users
    { duration: '30s', target: 0 },    // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'], // 95% of requests under 500ms
    errors: ['rate<0.1'],                            // Error rate under 10%
  },
};

const BASE_URL = 'http://llm-gateway:4000';

export default function () {
  // Test different endpoints and models
  const endpoints = [
    {
      url: `${BASE_URL}/v1/chat/completions`,
      payload: {
        model: 'gpt-3.5-turbo',
        messages: [{ role: 'user', content: 'Hello, this is a load test' }],
        max_tokens: 100,
        mock_response: true, // Use mock for load testing
      },
    },
    {
      url: `${BASE_URL}/v1/completions`,
      payload: {
        model: 'gpt-3.5-turbo-instruct',
        prompt: 'Complete this: The future of AI is',
        max_tokens: 50,
        mock_response: true,
      },
    },
    {
      url: `${BASE_URL}/v1/embeddings`,
      payload: {
        model: 'text-embedding-ada-002',
        input: 'This is a test embedding',
        mock_response: true,
      },
    },
  ];

  // Randomly select an endpoint
  const endpoint = endpoints[Math.floor(Math.random() * endpoints.length)];

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer test-key',
    },
  };

  const start = Date.now();
  const response = http.post(endpoint.url, JSON.stringify(endpoint.payload), params);
  const duration = Date.now() - start;

  // Record metrics
  responseTime.add(duration);
  errorRate.add(response.status !== 200);

  // Checks
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response has data': (r) => {
      const body = JSON.parse(r.body);
      return body && (body.choices || body.data || body.embedding);
    },
    'response time < 500ms': (r) => duration < 500,
  });

  // Simulate realistic user behavior
  sleep(Math.random() * 3 + 1); // Sleep 1-4 seconds
}

export function handleSummary(data) {
  return {
    'summary.json': JSON.stringify(data),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}

function textSummary(data, options) {
  return `
Load Test Summary
=================
Total Requests: ${data.metrics.http_reqs.values.count}
Success Rate: ${(100 - data.metrics.errors.values.rate * 100).toFixed(2)}%
Avg Response Time: ${data.metrics.response_time.values.avg.toFixed(2)}ms
P95 Response Time: ${data.metrics.response_time.values['p(95)'].toFixed(2)}ms
P99 Response Time: ${data.metrics.response_time.values['p(99)'].toFixed(2)}ms
`;
}