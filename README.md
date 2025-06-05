## CFH-Entertainment - Smart Control System (SCS)

**Beschreibung:**
Das SCS-Projekt von CFH-Entertainment ist ein modular aufgebautes System zur Steuerung und Überwachung von Sensoren und Aktoren über verschiedene Mikrocontroller, zentralisiert durch einen Server, und gesteuert via plattformübergreifender Dashboards (Windows, Web, Android) in Flutter.

---

### Inhaltsverzeichnis

1. [Projektübersicht](#projektübersicht)
2. [Verzeichnisstruktur](#verzeichnisstruktur)
3. [Setup-Anleitung](#setup-anleitung)

   1. [Server-Setup auf dem Raspberry Pi (Ubuntu Server 25.04)](#server-setup-auf-dem-raspberry-pi-ubuntu-server-2504)
   2. [Firmware-Entwicklung (Arduino IDE)](#firmware-entwicklung-arduino-ide)
   3. [Client-Software (Flutter in VS Code)](#client-software-flutter-in-vs-code)
4. [Logik & Steuerung](#logik--steuerung)

   1. [Bereichs- & Geräteverwaltung](#bereichs--geräteverwaltung)
   2. [Einbindung neuer Controller](#einbindung-neuer-controller)
   3. [Zustandsvisualisierung](#zustandsvisualisierung)
   4. [Logging & Historie](#logging--historie)
   5. [Backup & Wiederherstellung](#backup--wiederherstellung)
   6. [Zugriffsmanagement](#zugriffsmanagement)
   7. [Zustandsabhängige Steuerung](#zustandsabhängige-steuerung)
5. [Erweiterte Funktionen](#erweiterte-funktionen)
6. [Geplante Funktionen & Roadmap](#geplante-funktionen--roadmap)
7. [Listen & Dokumente](#listen--dokumente)
8. [Reminder für das Projekt](#reminder-für-das-projekt)

---

## 1. Projektübersicht

Das Smart Control System (SCS) von CFH-Entertainment besteht aus drei Hauptkomponenten:

1. **Firmwares** für verschiedene Mikrocontroller (ESP8266, ESP32, Arduino Mega 2560 mit Ethernet-Modul) zur Hardware-nahen Steuerung, Sensormessung und Kommunikation.
2. **Server** (Node.js + Express + Sequelize + WebSocket) als zentrales Verbindungsglied und Datenverwalter.
3. **Client-Software** (Flutter) für Windows, Web und Android zur Visualisierung und Steuerung.

Ziel ist ein flexibles, skalierbares System zur Steuerung von Sensoren und Aktoren über definierte Regeln und Dashboard-Oberflächen.

---

## 2. Verzeichnisstruktur

Im Git-Repository `cfh-scs` befindet sich derzeit:

```
cfh-scs/
├── scs-firmwares/       # Ordner für alle Mikrocontroller-Firmwares
│   ├── esp32/
│   ├── esp8266/
│   └── mega2560/
├── scs-server/          # Ordner für Server-Software (Node.js + Express)
│   ├── src/
│   ├── migrations/
│   ├── config/
│   ├── package.json
│   └── .env.example
├── scs_control/         # Ordner für Flutter-Client (Windows/Web/Android)
│   ├── lib/
│   ├── assets/
│   ├── pubspec.yaml
│   └── android/
├── LICENSE              # MIT-Lizenz
└── README.md            # Diese Datei
```

**Hinweis:** Weitere Unterordner für notwendige Module (z. B. Datenbank-Scripts, Skripte für Docker) können hinzugefügt werden.

---

## 3. Setup-Anleitung

### 3.1. Server-Setup auf dem Raspberry Pi (Ubuntu Server 25.04)

1. **Zugang zum Server**

   * Melde dich per SSH auf dem Raspberry Pi an:

     ```bash
     ssh benutzername@raspberrypi.local
     ```
   * Stelle sicher, dass du sudo-Rechte hast.

2. **System aktualisieren**

   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

3. **Node.js & npm installieren**

   * Installiere Node.js (empfohlen v18 LTS):

     ```bash
     curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
     sudo apt install -y nodejs
     ```
   * Prüfe Installation:

     ```bash
     node -v
     npm -v
     ```

4. **PostgreSQL (optional, falls SQLite nicht ausreicht)**

   * Installiere PostgreSQL:

     ```bash
     sudo apt install -y postgresql postgresql-contrib
     ```
   * Lege Benutzer & Datenbank an (Beispiel):

     ```bash
     sudo -u postgres createuser -P scs_user
     sudo -u postgres createdb -O scs_user scs_db
     ```
   * Konfiguriere `scs-server/config/config.json` entsprechend.

5. **scs-server einrichten**

   * Wechsle in das Verzeichnis:

     ```bash
     cd ~/cfh-scs/scs-server
     ```
   * Stelle Umgebungsvariablen bereit:

     ```bash
     cp .env.example .env
     # Öffne .env und trage Host, Port, Datenbank-Zugangsdaten ein:
     nano .env
     ```

     Beispiel (`.env`):

     ```bash
     NODE_ENV=development
     DB_HOST=localhost
     DB_USER=scs_user
     DB_PASSWORD=passwort
     DB_NAME=scs_db
     JWT_SECRET=DeinGeheimesJWTSecret
     SERVER_PORT=3000
     ```
   * Abhängigkeiten installieren:

     ```bash
     npm install
     ```
   * Datenbank-Migrationen ausführen:

     ```bash
     npx sequelize db:migrate
     ```
   * Seed-Daten (optional für Testdaten):

     ```bash
     npx sequelize db:seed:all
     ```

6. **Server starten**

   * Lokaler Start (nur für Tests):

     ```bash
     npm run dev
     ```
   * Für Produktionsbetrieb empfiehlt sich ein Prozessmanager wie PM2:

     ```bash
     sudo npm install -g pm2
     pm2 start src/index.js --name "scs-server"
     pm2 save
     pm2 startup    # Anleitung anzeigen lassen und Befehl ausführen
     ```
   * Überprüfe Logs, ob der Server korrekt gestartet ist:

     ```bash
     pm2 logs scs-server
     ```

7. **Firewall (UFW) konfigurieren**

   * Öffne nur die nötigen Ports (z. B. 22 für SSH, 3000 für Server):

     ```bash
     sudo apt install ufw -y
     sudo ufw allow OpenSSH
     sudo ufw allow 3000/tcp
     sudo ufw enable
     ```

8. **(Optional) Docker-Setup**

   * Wenn Docker gewünscht, installiere Docker & Docker Compose:

     ```bash
     sudo apt install -y docker.io docker-compose
     ```
   * Erstelle `docker-compose.yml` im Ordner `scs-server/` mit Services für Node.js und Datenbank.
   * Beispiel:

     ````yaml
     version: '3'
     services:
       db:
         image: postgres:15
         environment:
           POSTGRES_USER: scs_user
           POSTGRES_PASSWORD: passwort
           POSTGRES_DB: scs_db
         volumes:
           - db-data:/var/lib/postgresql/data
       server:
         build: .
         command: npm run start
         ports:
           - "3000:3000"
         environment:
           NODE_ENV: production
           DB_HOST: db
           DB_USER: scs_user
           DB_PASSWORD: passwort
           DB_NAME: scs_db
           JWT_SECRET: DeinGeheimesJWTSecret
         depends_on:
           - db
     volumes:
       db-data:
         ```
     ````
   * Starte mit:

     ```bash
     docker-compose up -d
     ```

---

### 3.2. Firmware-Entwicklung (Arduino IDE)

1. **Arduino IDE einrichten (lokal auf Windows/PC)**

   * Installiere Arduino IDE (empfohlen Version ≥ 1.8.19).
   * Füge die Board-Manager-URLs hinzu:

     * ESP8266: `http://arduino.esp8266.com/stable/package_esp8266com_index.json`
     * ESP32: `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
   * Öffne Arduino IDE → **Datei** → **Voreinstellungen** → **Zusätzliche Boardverwalter-URLs** und füge beide URLs ein, getrennt durch Komma.

2. **Bibliotheken installieren**

   * MQTT: PubSubClient
   * HTTP/WebSocket: ArduinoWebsockets, HTTPClient
   * Sensor-Bibliotheken (z. B. DHT für Temperatur/Feuchte)
   * Weitere (z. B. SPI, Ethernet für Mega, Wire, etc.)

3. **Firmware-Grundstruktur erstellen**

   * Lege in `scs-firmwares/esp32/` die Datei `main.ino` an.
   * Beispielstruktur (inklusive plattformübergreifendem Setup):

     ```cpp
     // main.ino

     #if defined(PLATFORM_ESP32)
       #include "wifi_esp32.h"
       #include "pins_esp32.h"
     #elif defined(PLATFORM_ESP8266)
       #include "wifi_esp8266.h"
       #include "pins_esp8266.h"
     #elif defined(PLATFORM_MEGA2560)
       #include "wifi_mega.h"
       #include "pins_mega.h"
     #endif

     #include "mqtt_client.h"
     #include "sensor_aktoren.h"
     #include "config_parser.h"

     void setup() {
       // 1. Hardware initialisieren (Pins, Sensoren, Aktoren)
       initPins();
       initSensors();

       // 2. WLAN/Ethernet-Verbindung herstellen
       setupNetwork();

       // 3. Verbindung zum SCS-Server (MQTT oder WebSocket)
       setupMQTT();
       // Optional HTTP/WebSocket verbinden

       // 4. Konfiguration vom Server laden
       requestConfiguration();

       // 5. Heartbeat initialisieren (Timer)
       startHeartbeatTimer();
     }

     void loop() {
       // 1. MQTT-/WebSocket-Client-Loop
       mqttClient.loop();
       // 2. Sensordaten lesen & ggf. senden
       readSensors();
       // 3. Aktor-Logik umsetzen
       processActuatorCommands();
       // 4. Heartbeat senden (z. B. jede Minute)
       sendHeartbeatIfDue();
       // 5. Lokale Logik (z. B. Notfallabschaltung)
       localSafetyChecks();
     }
     ```
   * Ersetze in den Dateien `wifi_*.h`, `pins_*.h` usw. die jeweiligen Plattform-spezifischen Implementierungen.
   * **Einfügepunkt Hinweis:**
     In der Datei `main.ino` im Abschnitt `setup()` müssen folgende Zeilen eingetragen werden:

     1. `initPins();` → direkt nach `{`
     2. `setupNetwork();` → nach Hardware-Initialisierung
     3. `setupMQTT();` → nach Netzwerkaufbau
     4. `requestConfiguration();`
     5. `startHeartbeatTimer();`

4. **Programmieren & Hochladen**

   * Öffne Arduino IDE → Wähle Board und Port (z. B. ESP32 Dev Module).
   * Kompilieren und Hochladen.
   * Überprüfe die Seriellen Ausgaben für Debug-Informationen (z. B. `Serial.begin(115200);`).

5. **OTA-Update (später)**

   * Planung: Admin-Frontend lädt Firmware hoch → Server verteilt per MQTT oder HTTP OTA.
   * Implementierung in Firmware: In `main.ino` OTA-Update-Handler ergänzen.

---

### 3.3. Client-Software (Flutter in VS Code)

1. **Entwicklungsumgebung einrichten**

   * Installiere Flutter SDK (Version ≥ 3.x).
   * Richte PATH-Variable ein (z. B. `export PATH="$PATH:/path/to/flutter/bin"`).
   * Installiere Android Studio bzw. setze Windows Desktop-Setup auf.
   * Prüfe mit:

     ```bash
     flutter doctor
     ```

2. **Projekt öffnen**

   * Wechsle in `scs_control/` und öffne VS Code:

     ```bash
     cd ~/cfh-scs/scs_control
     code .
     ```

3. **Abhängigkeiten definieren**

   * Öffne `pubspec.yaml` und füge benötigte Pakete hinzu:

     ```yaml
     dependencies:
       flutter:
         sdk: flutter
       cupertino_icons: ^1.0.2
       provider: ^6.0.0            # State-Management
       http: ^0.13.4               # REST-API
       mqtt_client: ^9.6.0         # MQTT-Integration
       websocket: ^2.0.0           # WebSocket
       shared_preferences: ^2.0.6  # Speicherung bekannter Domains
       flutter_secure_storage: ^5.0.2 # Sichere Speicherung von Tokens
     ```
   * Speichere und führe aus:

     ```bash
     flutter pub get
     ```

4. **Basisstruktur für Dashboard**

   * Unter `lib/` anlegen:

     * `main.dart`: Einstiegspunkt
     * `screens/`: Enthält Screens wie `login_screen.dart`, `dashboard_screen.dart`, `device_list_screen.dart`, `event_log_screen.dart` usw.
     * `models/`: Datenmodelle (z. B. `device.dart`, `area.dart`, `user.dart`, `event_log.dart`).
     * `services/`: API-Services (z. B. `api_service.dart`, `mqtt_service.dart`).
     * `widgets/`: Wiederverwendbare Widgets (z. B. `device_tile.dart`, `sensor_chart.dart`).
     * `providers/`: State-Management-Klassen (z. B. `auth_provider.dart`, `device_provider.dart`).

5. **Login & Domain-Auswahl**

   * In `login_screen.dart` einen Dropdown-Button implementieren, der gespeicherte Domains aus `shared_preferences` lädt.
   * Zusätzlich freies Textfeld für neue Domain-Eingabe.
   * Nach erfolgreichem Login Domain in Liste speichern.

6. **Live-Daten & Steuerung**

   * `mqtt_service.dart` implementieren: Verbindung zu MQTT-Broker (Server-Adresse), Listener für Topic `scs/{deviceId}/state`, Publisher für Steuerbefehle.
   * `api_service.dart` implementieren: CRUD-Aufrufe zu REST-API-Endpunkten (`/api/v1/devices`, `/api/v1/areas`, `/api/v1/events` etc.).

7. **UI-Aufbau**

   * Entwickle in `dashboard_screen.dart`:

     1. **AppBar** mit Menü (Logout, Einstellungen).
     2. **Drawer** oder BottomNavigationBar für Navigation: Geräte, Bereiche, Logs, Einstellungen.
     3. **Content-Bereich**: Je nach Menüpunkt unterschiedliche Listen und Detailansichten.

8. **Responsive Design**

   * Nutze `LayoutBuilder` und `MediaQuery` in Screens, um zwischen Desktop- und Mobile-Layout zu unterscheiden.

9. **Ereignisprotokoll & Export**

   * In `event_log_screen.dart` Tabelle mit Einträgen anzeigen.
   * Button zum CSV-Export: `path_provider` + `csv` Package verwenden.

---

## 4. Logik & Steuerung

### 4.1. Bereichs- & Geräteverwaltung

* **Bereiche** = Kategorien (z. B. "Zeltplatz", "Main Stage", "Wachstum").
* **Geräte (Pins)**: Konfiguration über Dashboard.

  * Modi: Digital In/Out, Analog In/Out.
  * Spezialfunktionen: Volt-Sensor, Regenwassersensor, CO₂-Sensor, Sauerstoffsensor, Drucksensor, Relais, PWM-Lüfter, Not-Aus, Schlüsselschalter, Schalter, Knopf, Leuchte.
* **Zuordnung** jedes Pins zu genau einem Bereich.
* **CRUD-Funktionalität**: Endpunkte und UI zur Verwaltung.

**Server-seitig (scs-server/src/controllers/deviceController.js):**

```js
// Beispiel-Endpunkt in Express
// GET /api/v1/areas/:areaId/devices
async function getDevicesByArea(req, res) {
  const { areaId } = req.params;
  const devices = await Device.findAll({ where: { areaId } });
  res.json(devices);
}
```

**Datenbank** (Sequelize-Modell `Device`):

```js
// scs-server/src/models/device.js
module.exports = (sequelize, DataTypes) => {
  const Device = sequelize.define('Device', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    name: { type: DataTypes.STRING, allowNull: false },
    type: { type: DataTypes.STRING, allowNull: false },        // z.B. 'digital_in', 'analog_out', 'relay'
    pinNumber: { type: DataTypes.INTEGER, allowNull: false },
    areaId: { type: DataTypes.INTEGER, allowNull: false },
    config: { type: DataTypes.JSON, allowNull: true }           // Zusätzliche Einstellungen (z.B. Pullup)
  });
  Device.associate = (models) => {
    Device.belongsTo(models.Area, { foreignKey: 'areaId' });
  };
  return Device;
};
```

### 4.2. Einbindung neuer Controller

* **Aufnahme** per Dashboard-Seite "Controller hinzufügen".
* Scan-Button: Sendet Broadcast (UDP) oder mDNS-Request in Netzwerk.
* Alternativ freie Eingabe der lokalen IP-Adresse.
* **Server-API** (`POST /api/v1/controllers`) speichert Controller-Daten:

  * `id`, `ipAddress`, `name`, `areaId`, `lastSeen`, `status`.

**Flutter UI (in `controller_list_screen.dart`):**

1. Button "Neuen Controller hinzufügen".
2. Popup: Scan-Netzwerk oder IP eingeben.
3. Bei Scan: Anzeige gefundener Geräte.
4. Auswahl → Formular zum Setzen von Name, Bereich, statische IP.

### 4.3. Zustandsvisualisierung

* **Online-/Offline-Status:** Server prüft per Heartbeat, speichert in DB-Feld `isOnline`, `lastSeen`.
* **Sensorwerte & Schaltzustände:** Echtzeit via MQTT/WebSocket an UI pushen.
* **Historie & Live-Daten:** Speicherung aller Sensor-Lesevorgänge in Tabelle `SensorLog`.
* **Separate Logging-Seite:** Anzeige Ereignis-Historie (EventLog) via REST-API.

### 4.4. Logging & Historie

* **EventLog-Modell** (Sequelize):

  * `id`, `timestamp`, `controllerId`, `deviceId`, `eventType`, `value`, `userId` (wenn von UI ausgelöst).
* **CRUD-API**: Nur Admins dürfen Logs löschen.
* **Export:** Endpunkt `GET /api/v1/logs/export?format=csv` generiert CSV.

### 4.5. Backup & Wiederherstellung

* **Export & Import** komplette Konfiguration:

  * Tabellen: `Users`, `Areas`, `Devices`, `Controllers`, `Variables`.
  * API-Endpunkte: `GET /api/v1/backup`, `POST /api/v1/restore`.
* **Geräte-Backup**: Firmware-Einstellungen, IP-Adressen.

### 4.6. Zugriffsmanagement

* **User-Modell** (Sequelize):

  * `id`, `username`, `passwordHash`, `role` (enum: 'admin','user','viewer'), `createdAt`, `updatedAt`.
* **Auth-Flow:** JWT-basierter Login. Beispiel in `authController.js`:

  ```js
  // POST /api/v1/auth/login
  async function login(req, res) {
    const { username, password } = req.body;
    const user = await User.findOne({ where: { username } });
    if (!user) return res.status(401).json({ message: 'Ungültiger Benutzername' });
    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) return res.status(401).json({ message: 'Ungültiges Passwort' });
    const token = jwt.sign({ userId: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '8h' });
    res.json({ token });
  }
  ```
* **Middleware**: `verifyToken(req, res, next)` prüft JWT und setzt `req.userId` und `req.userRole`.
* **Rollenprüfungen** in Routen definiert (z. B. `isAdmin`, `isUserOrAdmin`).

**Flutter:**

* Speicherung von JWT in `flutter_secure_storage`.
* Jeder API-Aufruf sendet Authorization-Header `Bearer <token>`.

### 4.7. Zustandsabhängige Steuerung

* **Szenen-Engine (Server-seitig)** liest Regeln aus Tabelle `Rules`:

  * `id`, `triggerType` (z. B. 'sensor', 'time', 'variable'), `triggerParams` (JSON), `action` (JSON: z. B. Gerät einschalten), `enabled`.
* **Beispielregel**: `{"triggerType": "sensor", "triggerParams": {"deviceId": 5, "operator": ">", "value": 30}, "action": {"deviceId": 12, "command": "setFanSpeed", "params": {"speed": 80}} }`
* **Scheduler** prüft zeitgesteuerte Regeln (CRON-artig).
* **MQTT-Handler** reagiert auf Sensordaten-Messages und führt Aktionen aus.

---

## 5. Erweiterte Funktionen

* **Automatische Kalibrierung von Sensoren** (Server-seitig oder Firmware).
* **Manuelle Übersteuerung** (Admins können Aktoren unabhängig von Regeln direkt schalten).
* **OTA-Firmware-Update-Mechanismus** (Server verteilt Firmware-Datei, Controller lädt herunter).
* **Öffentliche API mit Swagger** (Dokumentation: `/api/docs`).

---

## 6. Geplante Funktionen & Roadmap

| #    | Idee                                       | Nutzen                                                  |
| ---- | ------------------------------------------ | ------------------------------------------------------- |
| 15.1 | **AI-gestützte Anomalie-Erkennung**        | Frühwarnungen, prädiktive Wartung                       |
| 15.2 | **Energie-Dashboard**                      | Energie- & Budgetkontrolle, CO₂-Analyse                 |
| 15.3 | **Rollenbasierte Audit-Logs**              | Nachvollziehbarkeit (ISO/TÜV)                           |
| 15.4 | **Push-Benachrichtigungen**                | Flexible Alarmierung (Signal, Telegram, WebPush, Email) |
| 15.5 | **Sprachsteuerung (Alexa/Google Home)**    | Komfort, Demo-Faktor                                    |
| 15.6 | **Geo-Fence-Trigger (Mobile App)**         | Automatisierung, Sicherheit                             |
| 15.7 | **Kalender-Integration (ICS/Google Cal.)** | Szenenplanung per Standardkalender                      |

---

## 7. Listen & Dokumente

Folgende Listen und Dokumente werden im Projekt geführt und stets aktualisiert:

1. **README.md** – Überblick, Verzeichnisstruktur, Setup, Logik, Funktionen.
2. **Befehle & Skripte** – Sammlung aller Shell-/CLI-Befehle für Setup und Betrieb.
3. **API-Dokumentation** – Endpunkte und Parameter (Swagger, Markdown).
4. **DB-Schema & Migrations** – Beschreibung der Datenbanktabellen.
5. **Änderungsprotokoll (Changelog)** – Historie aller größeren Änderungen.
6. **Konfigurationsreferenz** – Umgebungsvariablen, Datei-Templates (`.env.example`).
7. **Firmware-Beschreibungen** – Übersicht über Code-Module, Bibliotheken und Pin-Belegungen.
8. **Szenen & Regeln** – Beschreibung des Regel-Engines, JSON-Templates.

*Hinweis: Weitere Listen werden ergänzt, sobald neue Bereiche oder Komponenten hinzukommen.*

---

## 8. Reminder für das Projekt

Bitte stets beachten:

1. **Konsistenz** bei Schreibweisen:

   * Datenbank-Spaltennamen, Variablennamen in Code, API-Parameter (CamelCase, snake\_case einheitlich nach Vereinbarung).
2. **Schritt-für-Schritt-Erklärungen** ohne Zusammenfassung mehrerer Schritte in Fachworte (lokal auf Server, Firmware-IDE, etc.).
3. **Gerätespezifische Anweisungen** immer klar kennzeichnen (z. B. "auf dem Server machen").
4. **Stelle im Code beschreiben**, an der Zeilen eingefügt werden (z. B. `main.ino`, `deviceController.js`).
5. **Updates aller Listen**: README, Befehle, Dokumente.
6. **Überprüfen der bisherigen Unterhaltung**: Ungereimtheiten vermeiden; bei neuen Vorschlägen Rückmeldung einholen.
7. **Projekt-Zeitzone**: Europe/Berlin; alle relativen Daten auf absolute Daten prüfen.

*Wenn dir etwas auffällt, das im Reminder fehlt, bitte direkt melden und aktualisieren.*
