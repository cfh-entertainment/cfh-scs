'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class SensorData extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
    }
  }
  SensorData.init({
    deviceId: DataTypes.INTEGER,
    timestamp: DataTypes.DATE,
    dataJson: DataTypes.JSON
  }, {
    sequelize,
    modelName: 'SensorData',
  });
  return SensorData;
};