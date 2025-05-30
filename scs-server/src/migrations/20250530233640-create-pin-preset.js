'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('PinPresets', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
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
      defaultState: {
        type: Sequelize.STRING
      },
      unit: {
        type: Sequelize.STRING
      },
      minValue: {
        type: Sequelize.FLOAT
      },
      maxValue: {
        type: Sequelize.FLOAT
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
    await queryInterface.dropTable('PinPresets');
  }
};