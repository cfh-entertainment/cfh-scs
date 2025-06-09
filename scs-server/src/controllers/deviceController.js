'use strict';

const { Device, Command } = require('../models');
const { Op } = require('sequelize');

// GET /api/v1/devices/:id/commands
exports.getCommands = async (req, res) => {
  try {
    const { id } = req.params;
    // Beispiel: array von Objekten { pin: 4, value: 1 }
    // später aus DB oder Regel-Engine generieren
    const commands = await Command.findAll({ where: { deviceId: id } });
    return res.json(commands.map(c => ({
      pin:   c.pinId,
      value: c.value
    })));
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Laden der Befehle.' });
  }
};

// GET /api/v1/devices
exports.listDevices = async (req, res) => {
  try {
    const devices = await Device.findAll({
      attributes: ['id','deviceId','type','lastSeen','configJson','createdAt','updatedAt']
    });
    return res.json(devices);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Laden der Geräte.' });
  }
};

// GET /api/v1/devices/:id
exports.getDevice = async (req, res) => {
  try {
    const id = req.params.id;
    const device = await Device.findByPk(id, {
      attributes: ['id','deviceId','type','lastSeen','configJson','createdAt','updatedAt']
    });
    if (!device) {
      return res.status(404).json({ message: 'Gerät nicht gefunden.' });
    }
    return res.json(device);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Laden des Geräts.' });
  }
};

// GET /api/v1/devices/:id/config
exports.getConfig = async (req, res) => {
  try {
    const id = req.params.id;
    const device = await Device.findByPk(id, {
      attributes: ['id','deviceId','configJson']
    });
    if (!device) {
      return res.status(404).json({ message: 'Gerät nicht gefunden.' });
    }
    return res.json({ config: device.configJson });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Laden der Konfiguration.' });
  }
};

// POST /api/v1/devices
exports.createDevice = async (req, res) => {
  try {
    const { deviceId, type, lastSeen, configJson } = req.body;
    if (!deviceId || !type) {
      return res.status(400).json({ message: 'deviceId und type sind erforderlich.' });
    }
    // Einzigartigkeit prüfen
    const exists = await Device.findOne({ where: { deviceId } });
    if (exists) {
      return res.status(409).json({ message: 'deviceId bereits vorhanden.' });
    }
    const device = await Device.create({
      deviceId,
      type,
      lastSeen: lastSeen ? new Date(lastSeen) : new Date(),
      configJson: configJson || {}
    });
    const io = req.app.get('io');
    io.emit('deviceCreated', device);
    return res.status(201).json(device);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Anlegen des Geräts.' });
  }
};

// PUT /api/v1/devices/:id
exports.updateDevice = async (req, res) => {
  try {
    const id = req.params.id;
    const { type, lastSeen, configJson } = req.body;
    const device = await Device.findByPk(id);
    if (!device) {
      return res.status(404).json({ message: 'Gerät nicht gefunden.' });
    }
    if (type)      device.type      = type;
    if (lastSeen)  device.lastSeen  = new Date(lastSeen);
    if (configJson !== undefined) device.configJson = configJson;
    await device.save();
    const io = req.app.get('io');
    io.emit('deviceUpdated', device);
    return res.json({ message: 'Gerät aktualisiert.' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Aktualisieren des Geräts.' });
  }
};

// DELETE /api/v1/devices/:id
exports.deleteDevice = async (req, res) => {
  try {
    const id = req.params.id;
    const count = await Device.destroy({ where: { id } });
    if (count === 0) {
      return res.status(404).json({ message: 'Gerät nicht gefunden.' });
    }
    const io = req.app.get('io');
    io.emit('deviceDeleted', { id });
    return res.json({ message: 'Gerät gelöscht.' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Löschen des Geräts.' });
  }
};
