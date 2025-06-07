'use strict';

const express                 = require('express');
const router                  = express.Router({ mergeParams: true });
const sensorDataController    = require('../controllers/sensorDataController');
const { authenticate, authorize } = require('../utils/authMiddleware');

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
