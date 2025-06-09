'use strict';
module.exports = (sequelize, DataTypes) => {
  const Command = sequelize.define('Command', {
    deviceId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: { model: 'Devices', key: 'id' }
    },
    pinId: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    value: {
      type: DataTypes.INTEGER,
      allowNull: false
    }
  }, {});
  
  Command.associate = function(models) {
    Command.belongsTo(models.Device, { foreignKey: 'deviceId', onDelete: 'CASCADE' });
  };
  
  return Command;
};
