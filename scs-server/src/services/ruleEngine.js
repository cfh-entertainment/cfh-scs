'use strict';

const cron         = require('node-cron');
const { Rule, Device } = require('../models');

/**
 * Prüft, ob eine Bedingung (conditionJson) erfüllt ist.
 * Beispiel-Aufbau conditionJson: { sensorValue: { gt: 50 } }
 */
function evaluateCondition(dataJson, conditionJson) {
  // für jede Bedingungsschlüssel prüfen
  return Object.entries(conditionJson).every(([key, cond]) => {
    const value = dataJson[key];
    if (cond.gt !== undefined)   return value >  cond.gt;
    if (cond.gte !== undefined)  return value >= cond.gte;
    if (cond.lt !== undefined)   return value <  cond.lt;
    if (cond.lte !== undefined)  return value <= cond.lte;
    if (cond.eq !== undefined)   return value === cond.eq;
    return false;
  });
}

/**
 * Führt die Aktion aus, wenn Bedingung erfüllt ist.
 * actionJson: { pin: 2, value: 'on' }
 */
async function executeAction(deviceId, actionJson, io) {
  // Hier würdest du entweder HTTP/MQTT/WebSocket an das Gerät senden.
  // Beispiel: per WebSocket
  io.to(`device_${deviceId}`).emit('executeAction', actionJson);
}

/**
 * Lädt alle Regeln aus der DB und plant sie.
 * Wird beim Serverstart aufgerufen.
 */
async function scheduleAllRules(io) {
  const rules = await Rule.findAll();
  rules.forEach(rule => {
    const { id, deviceId, conditionJson, actionJson, scheduleJson, type } = rule;
    let cronExp;

    // Typ „timeAndThreshold“: cron aus scheduleJson.cron, prüft zusätzlich Bedingung
    if (type === 'timeAndThreshold' && scheduleJson?.cron) {
      cronExp = scheduleJson.cron;
    }
    // Typ „thresholdOnly“: aus cron-Standard alle Minute
    else if (type === 'thresholdOnly') {
      cronExp = '* * * * *';
    } else {
      console.warn(`Unbekannter Regel-Typ für ID ${id}: ${type}`);
      return;
    }

    // Job anlegen
    cron.schedule(cronExp, async () => {
      try {
        // Letzte Sensordaten zum Gerät abrufen
        const latest = await rule.getSensorData({
          limit: 1,
          order: [['timestamp', 'DESC']]
        });
        if (latest.length === 0) return;

        const dataJson = latest[0].dataJson;
        // Bedingung prüfen
        if (type === 'timeAndThreshold') {
          if (!evaluateCondition(dataJson, conditionJson)) return;
        } else if (type === 'thresholdOnly') {
          if (!evaluateCondition(dataJson, conditionJson)) return;
        }

        // Aktion ausführen
        await executeAction(deviceId, actionJson, io);
        console.log(`Regel ${id} ausgelöst für Gerät ${deviceId}`);
      } catch (err) {
        console.error(`Fehler bei Regel ${id}:`, err);
      }
    });
    console.log(`Regel ${id} geplant: ${cronExp}`);
  });
}

module.exports = { scheduleAllRules };
