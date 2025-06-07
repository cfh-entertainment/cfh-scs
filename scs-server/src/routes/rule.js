'use strict';

const express           = require('express');
const router            = express.Router();
const ruleController    = require('../controllers/ruleController');
const { authenticate, authorize } = require('../utils/authMiddleware');

// Alle authentifizierten Rollen dürfen Regeln lesen
router.get('/',      authenticate, authorize(['admin','user','viewer']), ruleController.listRules);
router.get('/:id',   authenticate, authorize(['admin','user','viewer']), ruleController.getRule);

// Nur Admins dürfen anlegen, ändern und löschen
router.post('/',     authenticate, authorize(['admin']), ruleController.createRule);
router.put('/:id',   authenticate, authorize(['admin']), ruleController.updateRule);
router.delete('/:id',authenticate, authorize(['admin']), ruleController.deleteRule);

module.exports = router;
