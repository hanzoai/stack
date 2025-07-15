const http = require('http');

const server = http.createServer((req, res) => {
  console.log(`[Runtime] ${req.method} ${req.url}`);
  
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }
  
  if (req.url === '/api/health' || req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ 
      status: 'ok', 
      service: 'hanzo-runtime',
      version: '1.0.0',
      timestamp: new Date().toISOString()
    }));
  } else if (req.url === '/api/sandboxes' && req.method === 'POST') {
    // Mock sandbox creation
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      id: 'sandbox-' + Date.now(),
      state: 'started',
      language: 'python',
      createdAt: new Date().toISOString()
    }));
  } else if (req.url.startsWith('/api/sandboxes/') && req.method === 'DELETE') {
    // Mock sandbox deletion
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ success: true }));
  } else if (req.url === '/api/execute' && req.method === 'POST') {
    // Mock code execution
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        const code = data.code || '';
        const language = data.language || 'python';
        console.log(`[Runtime] Executing ${language} code:`, code.substring(0, 50) + '...');
        
        let output = '';
        let exitCode = 0;
        
        // Simulate different outputs based on language and code
        if (language === 'python') {
          if (code.includes('print(')) {
            const match = code.match(/print\((.*?)\)/g);
            if (match) {
              output = match.map(m => {
                const content = m.match(/print\((.*?)\)/)[1];
                return eval(content);
              }).join('\n') + '\n';
            }
          }
          if (code.includes('2 + 2')) {
            output = '4\n';
          }
          if (code.includes('import sys')) {
            output += 'Python 3.11.0\n';
          }
          if (!output) {
            output = 'Hello from Hanzo Runtime!\n';
          }
        } else if (language === 'javascript') {
          if (code.includes('console.log(')) {
            const match = code.match(/console\.log\((.*?)\)/g);
            if (match) {
              output = match.map(m => {
                const content = m.match(/console\.log\((.*?)\)/)[1];
                return eval(content);
              }).join('\n') + '\n';
            }
          }
          if (code.includes('3 * 4')) {
            output = '12\n';
          }
          if (code.includes('process.version')) {
            output += 'v20.11.0\n';
          }
          if (!output) {
            output = 'Hello from JavaScript!\n';
          }
        }
        
        // Simulate errors
        if (code.includes('error')) {
          output = 'Error: Something went wrong\n';
          exitCode = 1;
        }
        
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          output: output,
          exitCode: exitCode,
          executionTime: Math.floor(Math.random() * 100) + 50,
          language: language,
          timestamp: new Date().toISOString()
        }));
      } catch (e) {
        console.error('[Runtime] Error:', e);
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid request', details: e.message }));
      }
    });
    return;
  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
  }
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Mock Hanzo Runtime API running on port ${PORT}`);
  console.log('Endpoints:');
  console.log('  GET  /api/health - Health check');
  console.log('  POST /api/execute - Execute code');
  console.log('  POST /api/sandboxes - Create sandbox');
  console.log('  DELETE /api/sandboxes/:id - Delete sandbox');
});