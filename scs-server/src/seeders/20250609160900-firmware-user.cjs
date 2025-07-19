'use strict';
const bcrypt = require('bcrypt');

module.exports = {
  async up(queryInterface, Sequelize) {
    // Firmware nutzt dasselbe Standardpasswort wie der Demo-Admin
    const passwordHash = bcrypt.hashSync('wow1234wl', 10);
    await queryInterface.bulkInsert('Users', [{
      username: 'scs_firmware',
      passwordHash,
      role: 'user',
      createdAt: new Date(),
      updatedAt: new Date()
    }], {});
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.bulkDelete('Users', { username: 'scs_firmware' }, {});
  }
};
