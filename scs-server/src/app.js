// src/app.js
require('dotenv').config();

const { mqttEvents, sendMqtt } = require('./mqtt');
const http = require('http');
const { initWebSocket, wsEvents, broadcastToDashboards } = require('./ws');
const express   = require('express');
const { Sequelize } = require('sequelize');

const app = express();
app.use(express.json());

// DB-Instanz laden
const db = new Sequelize({
  dialect: process.env.DB_DIALECT,
  storage: process.env.DB_STORAGE
});

// Testverbindung ➡️ Konsole
(async () => {
  try {
    await db.authenticate();
    console.log('✅ Datenbank verbunden');
  } catch (err) {
    console.error('❌ DB-Fehler:', err);
  }
})();

// Beispiel: Reaktion auf MQTT-Nachrichten
mqttEvents.on('incoming', ({ topic, message }) => {
  // TODO: z. B. Speichern in DB, Weitergabe an Dashboard über WebSocket
  console.log('📨 Interne MQTT-Verarbeitung:', topic, message);
});

// HTTP-Server erzeugen
const server = http.createServer(app);

// WebSocket starten
initWebSocket(server);

// Weiterleitung von MQTT → WebSocket
mqttEvents.on('incoming', ({ topic, message }) => {
  broadcastToDashboards({ topic, message });
});

// --- Routen (Minimal) ---
app.get('/api/v1/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Platzhalter für weitere Routen
// ✅ hier später Controller-Routen einbinden

// Serverstart
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 Server mit WS läuft auf Port ${PORT}`);
});
