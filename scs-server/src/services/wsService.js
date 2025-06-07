'use strict';

module.exports = (io) => {
  // Neuer Client-Verbindung
  io.on('connection', (socket) => {
    console.log(`Client verbunden: ${socket.id}`);

    // Raum betreten, um nur Updates für ein bestimmtes Gerät zu bekommen
    socket.on('subscribeDevice', (deviceId) => {
      socket.join(`device_${deviceId}`);
    });

    socket.on('unsubscribeDevice', (deviceId) => {
      socket.leave(`device_${deviceId}`);
    });
  });
};
