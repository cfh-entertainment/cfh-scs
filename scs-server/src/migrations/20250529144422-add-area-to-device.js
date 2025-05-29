'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('Devices', 'areaId', {
      type: Sequelize.INTEGER,
      references: {
        model: 'Areas',
        key: 'id'
      },
      allowNull: true,
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL'
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeColumn('Devices', 'areaId');
  }
};
