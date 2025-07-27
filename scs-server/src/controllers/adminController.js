'use strict';

const fs = require('fs');
const path = require('path');

exports.getStatus = (req, res) => {
  try {
    return res.json({
      uptime: process.uptime(),
      memory: process.memoryUsage().rss,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Abrufen des Status.' });
  }
};

exports.uploadFirmware = (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Keine Datei hochgeladen.' });
    }
    const destDir = path.join(__dirname, '../../uploads');
    if (!fs.existsSync(destDir)) fs.mkdirSync(destDir, { recursive: true });
    const target = path.join(destDir, req.file.originalname);
    fs.renameSync(req.file.path, target);
    return res.status(201).json({ message: 'Firmware hochgeladen.' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Upload fehlgeschlagen.' });
  }
};
