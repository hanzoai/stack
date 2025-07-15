const http = require('http');

const server = http.createServer((req, res) => {
  console.log(`[Services Hub] ${req.method} ${req.url}`);
  
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }
  
  if (req.url === '/health' || req.url === '/api/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ 
      status: 'ok', 
      service: 'hanzo-services',
      timestamp: new Date().toISOString(),
      connections: {
        postgres: 'connected',
        redis: 'connected',
        iam: 'mocked',
        cloud: 'mocked',
        router: 'connected',
        chat: 'connected',
        runtime: 'connected'
      }
    }));
  } else if (req.url === '/api/services') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      services: [
        { name: 'iam', url: 'http://iam:8000', status: 'mocked' },
        { name: 'cloud', url: 'http://cloud:3000', status: 'mocked' },
        { name: 'router', url: 'http://router:4000', status: 'active' },
        { name: 'chat', url: 'http://chat:3081', status: 'active' },
        { name: 'runtime', url: 'http://runtime:3000', status: 'active' },
        { name: 'mcp', url: 'http://router:4000/mcp', status: 'active' }
      ]
    }));
  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
  }
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Mock Hanzo Services Hub running on port ${PORT}`);
});