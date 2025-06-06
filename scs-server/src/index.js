// src/index.js

// 1. Express-Modul importieren
const express = require('express');

// 2. App-Instanz erzeugen
const app = express();

// 3. Port festlegen (aus Umgebungsvariable oder Default 3000)
const PORT = process.env.SERVER_PORT || 3000;

// 4. Middleware, um JSON-Anfragen zu parsen (für spätere API-Endpunkte)
app.use(express.json());

// 5.1. Test-Daten: Array mit Platzhalter-Bereichen
const exampleAreas = [
  { id: 1, name: 'Zeltplatz' },
  { id: 2, name: 'Main Stage' },
  { id: 3, name: 'Wachstum' }
];

// 5.2. Neuer Endpunkt GET /api/v1/areas → liefert exampleAreas zurück
app.get('/api/v1/areas', (req, res) => {
  res.status(200).json(exampleAreas);
});

// 5. Einfacher Test-Endpunkt: GET / → liefert Status 200 und Text "OK"
app.get('/', (req, res) => {
  res.status(200).send('OK');
});

// 6. Server starten und auf Anfragen lauschen
app.listen(PORT, () => {
  console.log(`SCSServer läuft auf Port ${PORT}`);
});
