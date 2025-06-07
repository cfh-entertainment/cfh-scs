'use strict';

const bcrypt = require('bcrypt');

module.exports = {
  async up (queryInterface, Sequelize) {
    // Passwort hashen
    const passwordHash = bcrypt.hashSync('wow1234wl', 10);

    // Demo-Admin einfügen
    await queryInterface.bulkInsert('Users', [{
      username:    'cfh',
      passwordHash,
      role:        'admin',
      createdAt:   new Date(),
      updatedAt:   new Date()
    }], {});
  },

  async down (queryInterface, Sequelize) {
    // Beim Rückgängig-Machen den Admin wieder löschen
    await queryInterface.bulkDelete('Users', { username: 'cfh' }, {});
  }
};
