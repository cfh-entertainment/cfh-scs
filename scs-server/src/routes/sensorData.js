'use strict';

const express                 = require('express');
const router                  = express.Router({ mergeParams: true });
const sensorDataController    = require('../controllers/sensorDataController');
const { authenticate, authorize } = require('../utils/authMiddleware');

// CSV-Export-Route
router.get(
  '/export',
  authenticate,
  authorize(['admin','user','viewer']),
  sensorDataController.exportData
);

// NEU: GET aller Daten im Zeitfenster
router.get(
  '/',
  authenticate,
  authorize(['admin','user','viewer']),
  sensorDataController.listData
);

// Einzelner Eintrag
router.post(
  '/',
  authenticate,
  authorize(['admin','user']),
  sensorDataController.createData
);

// Bulk-Import
router.post(
  '/bulk',
  authenticate,
  authorize(['admin','user']),
  sensorDataController.bulkCreateData
);

module.exports = router;
