// src/index.js

// 1. Module und Umgebungsvariablen laden
require('dotenv').config();
const express = require('express');
const http = require('http');
const { Sequelize } = require('sequelize');
const socketIo = require('socket.io');
const path = require('path');
const bcrypt = require('bcrypt');
const { User } = require('./models');

// 2. Express-App initialisieren
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: { origin: '*' }  // In Entwicklung: alle Ursprünge zulassen
});
// io für Controller verfügbar machen
  app.set('io', io);

// WebSocket-Service: Subscription-Handling
  require('./services/wsService')(io);

// 3. Middleware
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

// Auth-Routen
  const authRoutes = require('./routes/auth');
  app.use('/api/v1/auth', authRoutes);

// User-Management (nur für Admins)
  const userRoutes = require('./routes/user');
  app.use('/api/v1/users', userRoutes);

// SensorData-Management
  const sensorDataRoutes = require('./routes/sensorData');
  app.use(
    '/api/v1/devices/:deviceId/data',
    sensorDataRoutes
  );

// Log-Management
  const logRoutes = require('./routes/log');
  app.use(
    '/api/v1/devices/:deviceId/logs',
    logRoutes
  );

// Command-Manegement
//  const commandRoutes = require('./routes/command');
//  app.use('/api/v1/devices/:deviceId/losg', commandRoutes);

// Device-Management
  const deviceRoutes = require('./routes/device');
  app.use('/api/v1/devices', deviceRoutes);

// Rule-Management
  const ruleRoutes = require('./routes/rule');
  app.use('/api/v1/rules', ruleRoutes);

// 4. Datenbankverbindung initialisieren
const sequelize = new Sequelize(
  process.env.DB_NAME, 
  process.env.DB_USER, 
  process.env.DB_PASS, {
    host: process.env.DB_HOST,
    dialect: 'mysql',
    logging: false
});

// 5. Einfacher Health-Check-Endpunkt
app.get('/api/v1/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date() });
});

// 6. WebSocket-Basis (Beispiel)
io.on('connection', (socket) => {
  console.log(`Client connected: ${socket.id}`);
  socket.on('disconnect', () => {
    console.log(`Client disconnected: ${socket.id}`);
  });
});

// 7. Server starten
const PORT = process.env.PORT || 3000;
server.listen(PORT, async () => {
  try {
    // Datenbankverbindung testen
    await sequelize.authenticate();
    console.log('Datenbankverbindung erfolgreich.');

    // Firmware-Benutzer sicherstellen
    const fwUser = await User.findOne({ where: { username: 'scs_firmware' } });
    if (!fwUser) {
      const passwordHash = await bcrypt.hash('wow1234wl', 10);
      await User.create({
        username: 'scs_firmware',
        passwordHash,
        role: 'user'
      });
      console.log('Standard-Firmwarebenutzer angelegt.');
    }

    // Regel-Engine initialisieren
    const io = app.get('io');
    const { scheduleAllRules } = require('./services/ruleEngine');
    await scheduleAllRules(io);

  } catch (err) {
    console.error('Datenbankverbindung fehlgeschlagen:', err);
  }
  console.log(`Server läuft auf Port ${PORT}`);
});
