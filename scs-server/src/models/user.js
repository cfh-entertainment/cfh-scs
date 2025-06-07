'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class User extends Model {
    static associate(models) {
      // ggf. Relationen definieren
    }
  }
  User.init({
    username: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true
    },
    passwordHash: {
      type: DataTypes.STRING,
      allowNull: false
    },
    role: {
      type: DataTypes.ENUM('admin','user','viewer'),
      allowNull: false
    }
  }, {
    sequelize,
    modelName: 'User',
    tableName: 'Users',        // explizit den Datenbank-Tabellennamen setzen
    timestamps: true           // createdAt und updatedAt automatisch anlegen
  });
  return User;
};
