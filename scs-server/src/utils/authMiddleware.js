'use strict';

const jwt = require('jsonwebtoken');

// 1) Token prüfen
exports.authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Kein Token angegeben.' });
  }
  const token = authHeader.split(' ')[1];
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.user = payload; // { userId, role, iat, exp }
    next();
  } catch {
    return res.status(401).json({ message: 'Ungültiges Token.' });
  }
};

// 2) Rollen prüfen
exports.authorize = (allowedRoles = []) => (req, res, next) => {
  if (!allowedRoles.includes(req.user.role)) {
    return res.status(403).json({ message: 'Keine Berechtigung.' });
  }
  next();
};
