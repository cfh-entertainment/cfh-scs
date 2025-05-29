const express = require('express');
const router = express.Router();
const { Area } = require('../models');

// ➕ Bereich anlegen
router.post('/', async (req, res) => {
  try {
    const area = await Area.create(req.body);
    res.status(201).json(area);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 🔁 Bereich bearbeiten
router.put('/:id', async (req, res) => {
  try {
    const area = await Area.findByPk(req.params.id);
    if (!area) return res.status(404).json({ error: 'not found' });

    await area.update(req.body);
    res.json(area);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 📖 Alle Bereiche abrufen
router.get('/', async (req, res) => {
  const areas = await Area.findAll();
  res.json(areas);
});

// 🧾 Einzelnen Bereich abrufen
router.get('/:id', async (req, res) => {
  const area = await Area.findByPk(req.params.id);
  if (!area) return res.status(404).json({ error: 'not found' });
  res.json(area);
});

// ❌ Bereich löschen
router.delete('/:id', async (req, res) => {
  const area = await Area.findByPk(req.params.id);
  if (!area) return res.status(404).json({ error: 'not found' });

  await area.destroy();
  res.json({ deleted: true });
});

module.exports = router;
