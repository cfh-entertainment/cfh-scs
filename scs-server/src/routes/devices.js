const express = require('express');
const router = express.Router();
const { Device } = require('../models');

// ➕ Gerät registrieren
router.post('/', async (req, res) => {
  try {
    const device = await Device.create(req.body);
    res.status(201).json(device);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 🔁 Gerät updaten
router.put('/:id', async (req, res) => {
  try {
    const device = await Device.findByPk(req.params.id);
    if (!device) return res.status(404).json({ error: 'not found' });

    await device.update(req.body);
    res.json(device);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 📖 Alle Geräte
router.get('/', async (req, res) => {
  const devices = await Device.findAll({
    include: { model: Area, attributes: ['id', 'name'] }
  });
  res.json(devices);
});

// 🧾 Einzelnes Gerät
router.get('/:id', async (req, res) => {
  const device = await Device.findByPk(req.params.id);
  if (!device) return res.status(404).json({ error: 'not found' });
  res.json(device);
});

// ❌ Löschen
router.delete('/:id', async (req, res) => {
  const device = await Device.findByPk(req.params.id);
  if (!device) return res.status(404).json({ error: 'not found' });

  await device.destroy();
  res.json({ deleted: true });
});

// 🔁 PUT by device name (z. B. esp32-01)
router.put('/by-name/:name', async (req, res) => {
  const device = await Device.findOne({ where: { name: req.params.name } });
  if (!device) return res.status(404).json({ error: 'not found' });

  await device.update(req.body);
  res.json(device);
});

module.exports = router;
