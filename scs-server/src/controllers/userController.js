'use strict';

const { User } = require('../models');
const bcrypt   = require('bcrypt');

// GET /api/v1/users
exports.listUsers = async (req, res) => {
  try {
    const users = await User.findAll({
      attributes: ['id','username','role','createdAt','updatedAt']
    });
    return res.json(users);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Laden der Benutzer.' });
  }
};

// GET /api/v1/users/:id
exports.getUser = async (req, res) => {
  try {
    const id = req.params.id;
    const user = await User.findByPk(id, {
      attributes: ['id','username','role','createdAt','updatedAt']
    });
    if (!user) {
      return res.status(404).json({ message: 'Benutzer nicht gefunden.' });
    }
    return res.json(user);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Laden des Benutzers.' });
  }
};

// POST /api/v1/users
exports.createUser = async (req, res) => {
  try {
    const { username, password, role } = req.body;
    if (!username || !password || !role) {
      return res.status(400).json({ message: 'Username, Passwort und Rolle sind erforderlich.' });
    }
    const exists = await User.findOne({ where: { username } });
    if (exists) {
      return res.status(409).json({ message: 'Benutzername bereits vergeben.' });
    }
    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({ username, passwordHash, role });
    return res.status(201).json({
      id:       user.id,
      username: user.username,
      role:     user.role,
      createdAt:user.createdAt
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Erstellen des Benutzers.' });
  }
};

// PUT /api/v1/users/:id
exports.updateUser = async (req, res) => {
  try {
    const id   = req.params.id;
    const { password, role } = req.body;
    const user = await User.findByPk(id);
    if (!user) {
      return res.status(404).json({ message: 'Benutzer nicht gefunden.' });
    }
    // Passwort ändern?
    if (password) {
      user.passwordHash = await bcrypt.hash(password, 10);
    }
    // Rolle ändern?
    if (role) {
      user.role = role;
    }
    await user.save();
    return res.json({ message: 'Benutzer aktualisiert.' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Aktualisieren des Benutzers.' });
  }
};

// DELETE /api/v1/users/:id
exports.deleteUser = async (req, res) => {
  try {
    const id = req.params.id;
    const count = await User.destroy({ where: { id } });
    if (count === 0) {
      return res.status(404).json({ message: 'Benutzer nicht gefunden.' });
    }
    return res.json({ message: 'Benutzer gelöscht.' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Fehler beim Löschen des Benutzers.' });
  }
};
