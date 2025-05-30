'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class PinPreset extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
      PinPreset.hasMany(models.Pin, { foreignKey: 'presetId' });
    }
  }
  PinPreset.init({
    name: DataTypes.STRING,
    mode: DataTypes.STRING,
    type: DataTypes.STRING,
    defaultState: DataTypes.STRING,
    unit: DataTypes.STRING,
    minValue: DataTypes.FLOAT,
    maxValue: DataTypes.FLOAT
  }, {
    sequelize,
    modelName: 'PinPreset',
  });
  return PinPreset;
};
