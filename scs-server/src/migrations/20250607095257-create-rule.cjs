'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('Rules', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      deviceId: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: { model: 'Devices', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      pinId: {
        type: Sequelize.INTEGER,
        allowNull: false
      },
      conditionJson: {
        type: Sequelize.JSON,
        allowNull: false
      },
      actionJson: {
        type: Sequelize.JSON,
        allowNull: false
      },
      scheduleJson: {
        type: Sequelize.JSON,
        allowNull: true
      },
      type: {
        type: Sequelize.STRING,
        allowNull: false
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
    await queryInterface.dropTable('Rules');
  }
};
