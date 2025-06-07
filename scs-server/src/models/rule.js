'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Rule extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // eine Regel gehört zu einem Gerät
      Rule.belongsTo(models.Device, { foreignKey: 'deviceId' });
      // und hat viele SensorData-Einträge
      Rule.hasMany(models.SensorData, {
        foreignKey: 'deviceId',
        sourceKey: 'deviceId'
      });
    }
  }
  Rule.init({
    deviceId: DataTypes.INTEGER,
    pinId: DataTypes.INTEGER,
    conditionJson: DataTypes.JSON,
    actionJson: DataTypes.JSON,
    scheduleJson: DataTypes.JSON,
    type: DataTypes.STRING
  }, {
    sequelize,
    modelName: 'Rule',
  });
  return Rule;
};
