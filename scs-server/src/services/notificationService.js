'use strict';

const nodemailer = require('nodemailer');

let transporter;
if (process.env.SMTP_HOST) {
  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT || '587', 10),
    secure: false,
    auth: process.env.SMTP_USER
      ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
      : undefined,
  });
}

async function sendEmail(subject, text) {
  if (!transporter || !process.env.NOTIFY_EMAIL_TO) return;
  await transporter.sendMail({
    from: process.env.NOTIFY_EMAIL_FROM || 'scs@example.com',
    to: process.env.NOTIFY_EMAIL_TO,
    subject,
    text,
  });
}

function sendWsNotification(io, deviceId, message) {
  io.to(`device_${deviceId}`).emit('notification', { message });
}

async function sendNotification(io, deviceId, message) {
  sendWsNotification(io, deviceId, message);
  try {
    await sendEmail('SCS Alarm', message);
  } catch (err) {
    console.error('E-Mail-Versand fehlgeschlagen:', err);
  }
}

module.exports = { sendNotification };
