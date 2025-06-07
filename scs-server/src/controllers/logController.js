'use strict';

const { Log, Device } = require('../models');

// GET /api/v1/devices/:deviceId/logs
exports.listLogs = async (req, res) => {
  try {
    const { deviceId } = req.params;
    // prüfen, ob Gerät existiert
    const device = await Device.findByPk(deviceId);
    if (!device) {
      return res.status(404).json({ message: 'Gerät nicht gefunden.' });
    }
    const logs = await Log.findAll({
      where: { deviceId: device.id },
      attributes: ['id','timestamp','message','createdAt']
    });
    return res.json(logs);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Laden der Logs.' });
  }
};

// GET /api/v1/devices/:deviceId/logs/:id
exports.getLog = async (req, res) => {
  try {
    const { deviceId, id } = req.params;
    const log = await Log.findOne({
      where: { id, deviceId },
      attributes: ['id','timestamp','message','createdAt']
    });
    if (!log) {
      return res.status(404).json({ message: 'Log-Eintrag nicht gefunden.' });
    }
    return res.json(log);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Laden des Log-Eintrags.' });
  }
};

// POST /api/v1/devices/:deviceId/logs
exports.createLog = async (req, res) => {
  try {
    const { deviceId } = req.params;
    const { timestamp, message } = req.body;
    const device = await Device.findByPk(deviceId);
    if (!device) {
      return res.status(404).json({ message: 'Gerät nicht gefunden.' });
    }
    if (!message) {
      return res.status(400).json({ message: 'message im Body erforderlich.' });
    }
    const log = await Log.create({
      deviceId: device.id,
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      message
    });
    // WebSocket-Event: neuer Log-Eintrag
    const io = req.app.get('io');
    io.to(`device_${device.id}`).emit('logCreated', log);
    return res.status(201).json(log);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Erstellen des Logs.' });
  }
};

// DELETE /api/v1/devices/:deviceId/logs/:id
exports.deleteLog = async (req, res) => {
  try {
    const { deviceId, id } = req.params;
    const count = await Log.destroy({ where: { id, deviceId } });
    if (count === 0) {
      return res.status(404).json({ message: 'Log-Eintrag nicht gefunden.' });
    }
    // WebSocket-Event: Log-Eintrag gelöscht
    const io = req.app.get('io');
    io.to(`device_${deviceId}`).emit('logDeleted', { id });
    return res.json({ message: 'Log-Eintrag gelöscht.' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Löschen des Logs.' });
  }
};
