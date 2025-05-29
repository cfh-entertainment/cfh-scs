// src/mqtt/index.js
const mqtt = require('mqtt');
const { EventEmitter } = require('events');

const mqttEvents = new EventEmitter();

const BROKER = 'mqtt://192.168.178.130';     // ✅ dein MQTT-Broker
const client = mqtt.connect(BROKER);

client.on('connect', () => {
  console.log('📡 MQTT verbunden');

  // Beispiel-Topics abonnieren
  client.subscribe('scs/+/status');         // z. B. scs/esp32-01/status
  client.subscribe('scs/+/sensor/#');       // z. B. scs/esp32-01/sensor/temp
  client.subscribe('scs/+/event/#');        // z. B. scs/esp32-01/event/button
});

client.on('message', (topic, messageBuffer) => {
  const message = messageBuffer.toString();
  console.log(`📥 MQTT: ${topic} ➝ ${message}`);

  // interne Weiterleitung via EventEmitter
  mqttEvents.emit('incoming', { topic, message });
});

function sendMqtt(topic, payload) {
  const data = typeof payload === 'string' ? payload : JSON.stringify(payload);
  client.publish(topic, data);
}

module.exports = {
  mqttEvents,
  sendMqtt
};
