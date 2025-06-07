'use strict';

const { SensorData, Device } = require('../models');

// POST /api/v1/devices/:deviceId/data
exports.createData = async (req, res) => {
  try {
    const { deviceId } = req.params;
    const { timestamp, dataJson } = req.body;
    // prüfen, ob Gerät existiert
    const device = await Device.findOne({ where: { id: deviceId } });
    if (!device) {
      return res.status(404).json({ message: 'Gerät nicht gefunden.' });
    }
    if (!dataJson) {
      return res.status(400).json({ message: 'dataJson im Body erforderlich.' });
    }
    const data = await SensorData.create({
      deviceId: device.id,
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      dataJson
    });
    const io = req.app.get('io');
    // nur Clients im Raum für dieses Gerät benachrichtigen
    io.to(`device_${device.id}`).emit('sensorData', data);
    return res.status(201).json(data);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Speichern der Sensordaten.' });
  }
};

// POST /api/v1/devices/:deviceId/data/bulk
exports.bulkCreateData = async (req, res) => {
  try {
    const { deviceId } = req.params;
    const entries = req.body; // erwartet ein Array von { timestamp, dataJson }
    // prüfen, ob Gerät existiert
    const device = await Device.findOne({ where: { id: deviceId } });
    if (!device) {
      return res.status(404).json({ message: 'Gerät nicht gefunden.' });
    }
    if (!Array.isArray(entries) || entries.length === 0) {
      return res.status(400).json({ message: 'Ein Array mit Datensätzen erforderlich.' });
    }
    const toInsert = entries.map(e => ({
      deviceId: device.id,
      timestamp: e.timestamp ? new Date(e.timestamp) : new Date(),
      dataJson: e.dataJson
    }));
    const result = await SensorData.bulkCreate(toInsert);
    const io = req.app.get('io');
    io.to(`device_${device.id}`)
      .emit('sensorDataBulk', { inserted: result.length });
    return res.status(201).json({ inserted: result.length });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Bulk-Speichern der Sensordaten.' });
  }
};
