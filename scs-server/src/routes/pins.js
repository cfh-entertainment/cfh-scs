const express = require('express');
const router = express.Router();
const { Pin, Device, Area, PinPreset } = require('../models');

// ➕ Pin anlegen
router.post('/', async (req, res) => {
  if (req.body.presetId) {
    const preset = await PinPreset.findByPk(req.body.presetId);
    if (preset) {
      // Vorgaben aus Preset als Fallback
      req.body.mode        = req.body.mode  ?? preset.mode;
      req.body.type        = req.body.type  ?? preset.type;
      req.body.state       = req.body.state ?? preset.defaultState;
    }
  }
  const pin = await Pin.create(req.body);
  res.status(201).json(pin);
});

// 🧾 Alle Pins
router.get('/', async (req, res) => {
  const pins = await Pin.findAll({
    include: ['Device', 'Area']
  });
  res.json(pins);
});

// 🔁 Einzelnen Pin aktualisieren
router.put('/:id', async (req, res) => {
  const pin = await Pin.findByPk(req.params.id);
  if (!pin) return res.status(404).json({ error: 'not found' });

  await pin.update(req.body);
  res.json(pin);
});

// ❌ Pin löschen
router.delete('/:id', async (req, res) => {
  const pin = await Pin.findByPk(req.params.id);
  if (!pin) return res.status(404).json({ error: 'not found' });

  await pin.destroy();
  res.json({ deleted: true });
});

module.exports = router;
