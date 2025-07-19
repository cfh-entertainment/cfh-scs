'use strict';
const bcrypt = require('bcrypt');

module.exports = {
  async up(queryInterface, Sequelize) {
    const passwordHash = bcrypt.hashSync('firmware123', 10);
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
