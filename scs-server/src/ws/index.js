// src/ws/index.js
const WebSocket = require('ws');
const { EventEmitter } = require('events');

const wsEvents = new EventEmitter();
let wss = null;

function initWebSocket(server) {
  wss = new WebSocket.Server({ server });

  wss.on('connection', ws => {
    console.log('🔗 WebSocket verbunden');

    ws.on('message', msg => {
      console.log('🌐 WS-Message:', msg);
      wsEvents.emit('incoming', { ws, message: msg });
    });

    ws.on('close', () => {
      console.log('❌ WS getrennt');
    });
  });
}

function broadcastToDashboards(data) {
  if (!wss) return;
  const str = typeof data === 'string' ? data : JSON.stringify(data);

  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(str);
    }
  });
}

module.exports = {
  initWebSocket,
  broadcastToDashboards,
  wsEvents
};
