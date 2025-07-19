'use strict';

const express            = require('express');
const router             = express.Router();
const deviceController   = require('../controllers/deviceController');
const { authenticate, authorize } = require('../utils/authMiddleware');

// Alle authentifizierten Rollen dürfen Geräte lesen
router.get('/',      		authenticate, authorize(['admin','user','viewer']), 	deviceController.listDevices);
router.get('/:id',   		authenticate, authorize(['admin','user','viewer']), 	deviceController.getDevice);
router.get('/:id/config',	authenticate, authorize(['admin','user','viewer']),	deviceController.getConfig);
// Registrierung durch Firmware
router.post('/register', authenticate, authorize(['admin','user']), deviceController.registerDevice);
router.get('/:id/commands',     authenticate, authorize(['admin','user','viewer']),     deviceController.getCommands);

// Nur Admins dürfen anlegen, ändern, löschen
router.post('/',     		authenticate, authorize(['admin']), 			deviceController.createDevice);
router.put('/:id',   		authenticate, authorize(['admin']), 			deviceController.updateDevice);
router.delete('/:id',		authenticate, authorize(['admin']), 			deviceController.deleteDevice);

module.exports = router;
