'use strict';

const { Rule } = require('../models');

// GET /api/v1/rules
exports.listRules = async (req, res) => {
  try {
    const rules = await Rule.findAll({
      attributes: [
        'id','deviceId','pinId',
        'conditionJson','actionJson','scheduleJson','type',
        'createdAt','updatedAt'
      ]
    });
    return res.json(rules);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Laden der Regeln.' });
  }
};

// GET /api/v1/rules/:id
exports.getRule = async (req, res) => {
  try {
    const id = req.params.id;
    const rule = await Rule.findByPk(id, {
      attributes: [
        'id','deviceId','pinId',
        'conditionJson','actionJson','scheduleJson','type',
        'createdAt','updatedAt'
      ]
    });
    if (!rule) {
      return res.status(404).json({ message: 'Regel nicht gefunden.' });
    }
    return res.json(rule);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Laden der Regel.' });
  }
};

// POST /api/v1/rules
exports.createRule = async (req, res) => {
  try {
    const { deviceId, pinId, conditionJson, actionJson, scheduleJson, type } = req.body;
    if (!deviceId || pinId === undefined || !conditionJson || !actionJson || !type) {
      return res.status(400).json({ message: 'deviceId, pinId, conditionJson, actionJson und type sind erforderlich.' });
    }
    const rule = await Rule.create({
      deviceId,
      pinId,
      conditionJson,
      actionJson,
      scheduleJson: scheduleJson || {},
      type
    });
    // WebSocket-Event: Regel erstellt
    const io = req.app.get('io');
    io.emit('ruleCreated', rule);
    return res.status(201).json(rule);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Anlegen der Regel.' });
  }
};

// PUT /api/v1/rules/:id
exports.updateRule = async (req, res) => {
  try {
    const id = req.params.id;
    const { conditionJson, actionJson, scheduleJson, type } = req.body;
    const rule = await Rule.findByPk(id);
    if (!rule) {
      return res.status(404).json({ message: 'Regel nicht gefunden.' });
    }
    if (conditionJson !== undefined) rule.conditionJson = conditionJson;
    if (actionJson    !== undefined) rule.actionJson    = actionJson;
    if (scheduleJson  !== undefined) rule.scheduleJson  = scheduleJson;
    if (type          !== undefined) rule.type          = type;
    await rule.save();
    // WebSocket-Event: Regel aktualisiert
    const io = req.app.get('io');
    io.emit('ruleUpdated', rule);
    return res.json({ message: 'Regel aktualisiert.' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Aktualisieren der Regel.' });
  }
};

// DELETE /api/v1/rules/:id
exports.deleteRule = async (req, res) => {
  try {
    const id = req.params.id;
    const count = await Rule.destroy({ where: { id } });
    if (count === 0) {
      return res.status(404).json({ message: 'Regel nicht gefunden.' });
    }
    // WebSocket-Event: Regel gelöscht
    const io = req.app.get('io');
    io.emit('ruleDeleted', { id });
    return res.json({ message: 'Regel gelöscht.' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Löschen der Regel.' });
  }
};
