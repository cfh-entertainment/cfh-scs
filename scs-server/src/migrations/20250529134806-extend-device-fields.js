'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('Devices', 'type', Sequelize.STRING);
    await queryInterface.addColumn('Devices', 'location', Sequelize.STRING);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeColumn('Devices', 'type');
    await queryInterface.removeColumn('Devices', 'location');
  }
};
