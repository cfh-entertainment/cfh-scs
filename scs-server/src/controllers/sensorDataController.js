'use strict';

const { SensorData, Device } = require('../models');
const { Op }                 = require('sequelize');

// CSV-Export /api/v1/devices/:deviceId/data/export?from=<ISO>&to=<ISO>
exports.exportData = async (req, res) => {
  try {
    const { deviceId } = req.params;
    const { from, to } = req.query;
    const device = await Device.findByPk(deviceId);
    if (!device) {
      return res.status(404).json({ message: 'Gerät nicht gefunden.' });
    }
    const tTo   = to   ? new Date(to)   : new Date();
    const tFrom = from ? new Date(from) : new Date(tTo.getTime() - 24*60*60*1000);
    const entries = await SensorData.findAll({
      where: {
        deviceId: device.id,
        timestamp: { [Op.between]: [tFrom, tTo] }
      },
      order: [['timestamp','ASC']]
    });
    // Header setzen
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="device_${deviceId}_data.csv"`);
    // CSV-Kopf
    let csv = 'timestamp';
    // Spalten aus DatenJSON dynamisch ermitteln
    const cols = entries.length
      ? Object.keys(entries[0].dataJson)
      : [];
    cols.forEach(col => { csv += `,${col}`; });
    csv += '\n';
    // Zeilen
    entries.forEach(e => {
      csv += `${e.timestamp.toISOString()}`;
      cols.forEach(col => {
        const v = e.dataJson[col];
        csv += `,${v != null ? v : ''}`;
      });
      csv += '\n';
    });
    return res.send(csv);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Exportieren der Daten.' });
  }
};

// LISTE /api/v1/devices/:deviceId/data?from=<ISO>&to=<ISO>
exports.listData = async (req, res) => {
  try {
    const { deviceId } = req.params;
    const { from, to } = req.query;

    // Gerät prüfen
    const device = await Device.findByPk(deviceId);
    if (!device) {
      return res.status(404).json({ message: 'Gerät nicht gefunden.' });
    }

    // Zeitfilter parsen, Standard: letzte 24 Stunden
    const tTo   = to   ? new Date(to)   : new Date();
    const tFrom = from ? new Date(from) : new Date(tTo.getTime() - 24*60*60*1000);

    const entries = await SensorData.findAll({
      where: {
        deviceId: device.id,
        timestamp: {
          [Op.between]: [tFrom, tTo]
        }
      },
      order: [['timestamp','ASC']]
    });

    return res.json(entries);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Laden der Sensordaten.' });
  }
};

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
