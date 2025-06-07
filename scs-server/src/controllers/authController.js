'use strict';

const { User }      = require('../models');
const bcrypt        = require('bcrypt');
const jwt           = require('jsonwebtoken');

// POST /api/v1/auth/register
exports.register = async (req, res) => {
  try {
    const { username, password, role } = req.body;
    if (!username || !password) {
      return res.status(400).json({ message: 'Username und Passwort erforderlich.' });
    }
    // Prüfen, ob User schon existiert
    const exists = await User.findOne({ where: { username } });
    if (exists) {
      return res.status(409).json({ message: 'Benutzername bereits vergeben.' });
    }
    // Passwort hashen
    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({ username, passwordHash, role: role || 'user' });
    return res.status(201).json({ id: user.id, username: user.username, role: user.role });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Serverfehler beim Registrieren.' });
  }
};

// POST /api/v1/auth/login
exports.login = async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ message: 'Username und Passwort erforderlich.' });
    }
    const user = await User.findOne({ where: { username } });
    if (!user) {
      return res.status(401).json({ message: 'Ungültige Anmeldedaten.' });
    }
    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      return res.status(401).json({ message: 'Ungültige Anmeldedaten.' });
    }
    // Token signieren
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '2h' }
    );
    return res.json({ token, expiresIn: 7200, role: user.role });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Serverfehler beim Login.' });
  }
};
