'use strict';

const express        = require('express');
const router         = express.Router();
const userController = require('../controllers/userController');
const { authenticate, authorize } = require('../utils/authMiddleware');

// Alle Routen für /api/v1/users
router.get('/',      authenticate, authorize(['admin']), userController.listUsers);
router.get('/:id',   authenticate, authorize(['admin']), userController.getUser);
router.post('/',     authenticate, authorize(['admin']), userController.createUser);
router.put('/:id',   authenticate, authorize(['admin']), userController.updateUser);
router.delete('/:id',authenticate, authorize(['admin']), userController.deleteUser);

module.exports = router;
