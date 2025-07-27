const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../utils/authMiddleware');
const adminController = require('../controllers/adminController');
const multer = require('multer');

const upload = multer({ dest: 'tmp/' });

router.get('/status', authenticate, authorize(['admin']), adminController.getStatus);
router.post('/firmware', authenticate, authorize(['admin']), upload.single('firmware'), adminController.uploadFirmware);

module.exports = router;
