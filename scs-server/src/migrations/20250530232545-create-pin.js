'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('Pins', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      pinNumber: {
        type: Sequelize.INTEGER
      },
      name: {
        type: Sequelize.STRING
      },
      mode: {
        type: Sequelize.STRING
      },
      type: {
        type: Sequelize.STRING
      },
      state: {
        type: Sequelize.STRING
      },
      deviceId: {
        type: Sequelize.INTEGER
      },
      areaId: {
        type: Sequelize.INTEGER
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('Pins');
  }
};