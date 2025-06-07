'use strict';

const express       = require('express');
const router        = express.Router({ mergeParams: true });
const logController = require('../controllers/logController');
const { authenticate, authorize } = require('../utils/authMiddleware');

// Logs lesen (alle und einzeln) – alle Rollen
router.get(
  '/',
  authenticate,
  authorize(['admin','user','viewer']),
  logController.listLogs
);
router.get(
  '/:id',
  authenticate,
  authorize(['admin','user','viewer']),
  logController.getLog
);

// Log erstellen – admin & user
router.post(
  '/',
  authenticate,
  authorize(['admin','user']),
  logController.createLog
);

// Log löschen – nur admin
router.delete(
  '/:id',
  authenticate,
  authorize(['admin']),
  logController.deleteLog
);

module.exports = router;
