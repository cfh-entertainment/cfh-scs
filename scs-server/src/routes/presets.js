const r = require('express').Router();
const { PinPreset } = require('../models');

// ➕ Preset anlegen
r.post('/', async (req, res) => res.status(201).json(await PinPreset.create(req.body)));

// 📖 Alle Presets
r.get('/', async (_ , res) => res.json(await PinPreset.findAll()));

// 🔁 Preset ändern
r.put('/:id', async (req, res) => {
  const p = await PinPreset.findByPk(req.params.id);
  if (!p) return res.status(404).json({ error: 'not found' });
  res.json(await p.update(req.body));
});

// ❌ löschen
r.delete('/:id', async (req, res) => {
  const p = await PinPreset.findByPk(req.params.id);
  if (!p) return res.status(404).json({ error: 'not found' });
  await p.destroy(); res.json({ deleted:true });
});

module.exports = r;
