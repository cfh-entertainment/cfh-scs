'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Pin extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      Pin.belongsTo(models.Device, { foreignKey: 'deviceId' });
      Pin.belongsTo(models.Area, { foreignKey: 'areaId' });
      Pin.belongsTo(models.PinPreset, { foreignKey: 'presetId' });
    }
  }
  Pin.init({
    pinNumber: DataTypes.INTEGER,
    name: DataTypes.STRING,
    mode: DataTypes.STRING,
    type: DataTypes.STRING,
    state: DataTypes.STRING,
    deviceId: DataTypes.INTEGER,
    areaId: DataTypes.INTEGER
  }, {
    sequelize,
    modelName: 'Pin',
  });
  return Pin;
};
