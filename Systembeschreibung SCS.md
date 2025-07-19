Einleitung
Dieses Dokument beschreibt das CFH-Entertainment Smart Control System (SCS) für das Überwachen und Steuern von Sensoren und Aktoren in Veranstaltungs- oder Industrieumgebungen. Die Firmwares für unterschiedliche Mikrocontroller-Plattformen kommunizieren mit einem zentralen Node.js-Server, der über eine Flutter-basierte Dashboard-App bedient wird.

---

## 1. Projektüberblick

Das SCS-Projekt verfolgt das Ziel, verschiedene eingebettete Controller (ESP8266, ESP32, Arduino Mega 2560) über WLAN oder Ethernet für Sensordatenerfassung und Aktorsteuerung in einem einheitlichen System zu vernetzen. Die Komponenten im Überblick:

1. **Firmware (Embedded-Controller)**

   * Plattformen: ESP8266, ESP32, Arduino Mega 2560
   * Funktionen: Sensordaten erfassen, Aktoren steuern, Netzwerkkommunikation (HTTP, WebSocket, MQTT), OTA-Updates (nur ESP), Datenpufferung bei Verbindungsproblemen, Heartbeat

2. **Zentraler Server (Node.js + Express + Sequelize + WebSocket)**

   * REST-API für Konfiguration, Telemetrie, Regeln
   * WebSocket-Server für Echtzeitkommunikation
   * Sequelize/SQLite (bzw. MySQL/PostgreSQL) für Persistenz
   * Regeln & Automatisierungen (node-cron, mqtt, etc.)
   * Benutzerverwaltung (Roles: admin, user, viewer)

3. **Dashboard (Flutter-App)**

   * Plattformen: Windows Desktop, Web, Android (zukünftig iOS)
   * Funktionen: Geräteliste, Live-Daten, Pin-Konfiguration, Szenen/Regeln, Historie, Benachrichtigungen

---

## 2. Komponenten im Detail

### 2.1 Firmware (Embedded-Controller)

#### 2.1.1 ESP8266

* **Microcontroller**: ESP8266 (z. B. NodeMCU, Wemos D1 Mini)
* **Netzwerk**: WLAN (SmartConfig / SoftAP zur Provisionierung)
* **OTA**: Unterstützt OTA-Updates über HTTP, Bibliothek `ESP8266httpUpdate`
* **Deep-Sleep**: Nicht verfügbar
* **Beschränkungen**: 80 kB Heap; keine Hardware-RTC, Uhrzeit über NTP oder RTC-Module

#### 2.1.2 ESP32

* **Microcontroller**: ESP32 (z. B. DevKit)
* **Netzwerk**: WLAN (SmartConfig / SoftAP zur Provisionierung)
* **OTA**: Unterstützt OTA-Updates über HTTP, Bibliothek `Update.h`
* **Deep-Sleep**: Verfügbar (RTC-Anbindung)
* **Beschränkungen**: Ca. 300 kB Heap; integrierte RTC

#### 2.1.3 Arduino Mega 2560

* **Controller**: Atmel ATmega2560
* **Netzwerk**: Ethernet-Modul (z. B. W5500 oder ENC28J60) per SPI
* **Provisionierung**: Keine SoftAP-/Hotspot-Funktion (geringer Speicher); Netzwerkkonfiguration via `config.h` oder serielle Eingabe
* **OTA**: Nicht unterstützt; Firmware-Updates per USB (IDE)
* **Beschränkungen**: Ca. 8 kB RAM; kein WLAN, keine native RTC

### 2.1.4 Gemeinsame Firmware-Funktionen

1. **Sensorik & Aktorik**

   * Sensordaten: Temperatur, Feuchtigkeit, Wasserstand, CO₂, Druck, Spannung (Volt-Sensor), Regenwasser, Sauerstoff, etc.
   * Eingabemodule: Taster, Schlüsselschalter, Not-Aus-Schalter, Knöpfe
   * Aktorik: Relais (ein/aus), Ventile (öffnen/schließen), PWM-Lüfter steuern, Leuchten dimmen oder schalten
   * Konfiguration: Pin-Modi (Digital In/Out, Analog In/Out, Relay, PWM\_Fan, Specialized Sensors) und Zuordnung zu logischen Einheiten (rooms, zones)

2. **Netzwerkkommunikation**

   * ESP8266/ESP32: WLAN (WiFi, HTTP, WebSocket), OTA (ESP8266httpUpdate / Update.h), MQTT über `PubSubClient`
   * Mega 2560: Ethernet (SPI, Bibliothek `Ethernet.h`), HTTP, WebSocket (z. B. `WebSocketsClient`), kein OTA, optional MQTT (falls Ethernet-Shield ausreichend Arbeitsspeicher)

3. **Provisionierung**

   * ESP8266/ESP32: Start im SmartConfig-Mode oder SoftAP, Konfiguration über Webformular (SSID, Passwort, Server-URL)
   * Mega 2560: Keine SoftAP-Funktion; Netzwerkeinstellungen (`IP`, `Gateway`, `Subnetz`, `Server-IP`) direkt in `config.h` oder serielle Eingabe via USB

4. **Konfigurationsabruf**

   * Nach erfolgreicher Netzwerkverbindung: GET `/api/v1/devices/{DEVICE_ID}/config` → JSON → Speicherung in Flash (SPIFFS/LittleFS für ESP; EEPROM für Mega)

5. **Kommunikationskanäle**

   * HTTP / WebSocket (primäre Übertragung sensorenbezogener Telemetriewerte)
   * MQTT (optional, z. B. `mqtt://brokeradresse:1883`, Themen: `devices/{DEVICE_ID}/state`)

6. **Heartbeat**

   * Sende periodisch (z. B. alle 60 s) einen Status-Übergabe-Report (z. B. Free-Heap, Uptime) an `POST /api/v1/devices/{DEVICE_ID}/heartbeat`

7. **OTA-Updates (ESP8266 & ESP32)**

   * Admin lädt neue Firmware (`*.bin`) über Dashboard hoch → Server speichert unter `/firmware/{plattform}/latest.json` (Versionsnummer, URL) und `latest.bin`
   * **ESP8266**: Stündliche Abfrage `https://{SERVER}/firmware/esp8266/latest.json`; bei neuer Version `ESPhttpUpdate.update(url)`
   * **ESP32**: Stündliche Abfrage `https://{SERVER}/firmware/esp32/latest.json`; bei neuer Version `Update.begin()`, `Update.writeStream()`, `Update.end()`
   * **Mega 2560**: Keine OTA-Unterstützung

8. **Datenpufferung bei Ausfall**

   * Sensordaten in zyklischen Buffern sammeln (max. 100 Einträge), bei Wiederherstellung Verbindung → Batch-POST `/api/v1/devices/{DEVICE_ID}/data/bulk`

### 2.1.5 Sketch-Aufbau je Plattform

#### 2.1.5.1 ESP8266 Sketch-Template

```cpp
#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <ESP8266httpUpdate.h>
#include <PubSubClient.h>
#include "config.h"
#include "pins.h"
#include "sensors/AllSensors.h"
#include "actuators/AllActuators.h"
#include "utils/APProvisioning.h"    // SoftAP Provisionierung
#include "utils/NetworkManager.h"    // WiFi-Management
#include "utils/Heartbeat.h"
#include "utils/BufferManager.h"
#include "utils/OTAProvider.h"

WiFiClient espClient;
PubSubClient mqttClient(espClient);

void setup() {
  initSensors();
  initActuators();
  startProvisioningIfNeeded();   // SoftAP-Provisioning (SSID: SCS-Setup-<DEVICE_ID>)
  connectToWiFi();               // WiFi-Verbindung aufbauen
  fetchConfiguration();          // GET /api/v1/devices/{DEVICE_ID}/config
  initWebSocket();               // WebSocket-Client initialisieren
  initMQTT();                    // MQTT-Client initialisieren (optional)
  startHeartbeatTimer();         // Herzschlag-Intervall starten
  startOTACheckTimer();          // OTA-Check-Intervall starten (stündlich)
}

void loop() {
  handleProvisioning();          // Webserver der SoftAP, falls aktiv
  handleNetwork();               // WebSocket.loop() oder mqttClient.loop()
  readSensorsAndSend();          // Sensordaten auslesen und senden
  handleHeartbeat();             // Periodischer Heartbeat
  handleOTAUpdates();            // Prüft einmal pro Stunde auf neue Firmware
}
```

#### 2.1.5.2 ESP32 Sketch-Template

```cpp
#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <Update.h>
#include <PubSubClient.h>
#include "config.h"
#include "pins.h"
#include "sensors/AllSensors.h"
#include "actuators/AllActuators.h"
#include "utils/APProvisioning.h"    // SoftAP Provisionierung
#include "utils/NetworkManager.h"    // WiFi-Management
#include "utils/Heartbeat.h"
#include "utils/BufferManager.h"

WiFiClient espClient;
PubSubClient mqttClient(espClient);

void setup() {
  initSensors();
  initActuators();
  startProvisioningIfNeeded();   // SoftAP-Provisioning
  connectToWiFi();               // WiFi-Verbindung
  fetchConfiguration();          // GET /api/v1/devices/{DEVICE_ID}/config
  initWebSocket();               // WebSocket-Client
  initMQTT();                    // MQTT-Client (optional)
  startHeartbeatTimer();         // Herzschlag
  startOTACheckTimer();          // OTA-Check (stündlich)
}

void loop() {
  handleProvisioning();
  handleNetwork();
  readSensorsAndSend();
  handleHeartbeat();
  handleOTAUpdates();            // OTA mit Update.h
}
```

#### 2.1.5.3 Arduino Mega 2560 Sketch-Template

```cpp
#include <Arduino.h>
#include <SPI.h>
#include <Ethernet.h>
#include <WebSocketsClient.h>       // WebSocket über Ethernet
#include <PubSubClient.h>           // MQTT (optional)
#include "config.h"
#include "pins.h"
#include "sensors/AllSensors.h"
#include "actuators/AllActuators.h"
#include "utils/NetworkManager.h"   // Ethernet-Management
#include "utils/Heartbeat.h"
#include "utils/BufferManager.h"

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
EthernetClient ethClient;
PubSubClient mqttClient(ethClient);

void setup() {
  initSensors();
  initActuators();
  Ethernet.begin(mac);                 // DHCP oder statische Konfiguration in config.h
  delay(1000);
  fetchConfiguration();                // GET /api/v1/devices/{DEVICE_ID}/config
  initWebSocket();                     // WebSocket-Client
  initMQTT();                          // MQTT-Client (optional, nur wenn genug Speicher)
  startHeartbeatTimer();               // Herzschlag-Intervall starten
}

void loop() {
  handleNetwork();                     // WebSocket.loop() oder mqttClient.loop()
  readSensorsAndSend();                // Sensordaten auslesen und senden
  handleHeartbeat();                   // Periodischer Heartbeat
}
```

### 2.2 Zentraler Server (Node.js + Express + Sequelize + WebSocket)

#### 2.2.1 Architektur & Technologien

* **Node.js** (v16+)
* **Express**: REST-API
* **Socket.io** (WebSocket) oder `ws`-Paket
* **Sequelize** (ORM) mit SQLite (Entwicklung) oder MySQL/PostgreSQL (Produktion)
* **Bibliotheken**:

  * `bcrypt` / `argon2` (Passwort-Hashing)
  * `jsonwebtoken` (JWT für Authentifizierung)
  * `node-cron` (zeitgesteuerte Aufgaben)
  * `dotenv` (Umgebungsvariablen, `.env`)
  * `swagger-jsdoc` & `swagger-ui-express` (API-Dokumentation)

#### 2.2.2 Datenbankmodell (Sequelize mit Migrations)

* **Tabellen**:

  * **Users** (`id`, `username`, `passwordHash`, `role`)
  * **Devices** (`id`, `deviceId`, `type`, `lastSeen`, `configJson`)
  * **SensorData** (`id`, `deviceId`, `timestamp`, `dataJson`)
  * **Rules** (`id`, `deviceId`, `pinId`, `conditionJson`, `actionJson`, `scheduleJson`, `type`)
  * **Logs** (`id`, `deviceId`, `timestamp`, `message`)

#### 2.2.3 Kernfunktionalitäten des Servers

1. **Authentifizierung & Autorisierung**

   * JWT-basiert (Bearer Token im Header)
   * Rollen: `admin` (voller Zugriff), `user` (Geräte- und Regelverwaltung), `viewer` (nur Lesezugriff)

2. **Geräteverwaltung & Discovery**

   * Erhält Discovery-Anfragen per UDP/mDNS
   * Fügt neue Geräte in Datenbank ein (Status = Pending)
   * Stellt Konfigurations-JSON unter `/api/v1/devices/{DEVICE_ID}/config` bereit

3. **Telemetrie & Heartbeat**

   * Empfängt Telemetrie (HTTP POST) → speichert in `SensorData`
   * Empfängt Heartbeat (HTTP POST) → aktualisiert `Devices.lastSeen`

4. **Regel-Engine & Cron-Jobs**

   * `node-cron` lädt alle `Rules` mit gültigem `scheduleJson` und plant sie ein
   * Fällige Regeln werden automatisch ausgelöst, auch ohne Sensor-Trigger
   * Bei Erfüllung von Bedingungen (z. B. `pinValue > threshold`) sendet der Server `actionJson` an Controller

5. **WebSocket-Kommunikation**

   * Echtzeit-Updates (Live-Daten, Statusänderungen)
   * Controller verbindet sich nach Provisionierung per WebSocket

6. **API-Endpunkte** (Auswahl)

   * `POST /auth/login` (Rückgabe eines JWT)
   * `GET /api/v1/devices` (Liste aller Geräte, rolleabhängig)
   * `GET /api/v1/devices/{DEVICE_ID}/config` (Rückgabe Konfigurations-JSON)
   * `POST /api/v1/devices/{DEVICE_ID}/data` (Einzelne Sensordaten)
   * `POST /api/v1/devices/{DEVICE_ID}/data/bulk` (Datenpuffer synchronisieren)
   * `GET /api/v1/rules` (Liste aller Regeln)
   * `POST /api/v1/rules` (Regel anlegen)
   * `DELETE /api/v1/rules/{RULE_ID}` (Regel löschen)

### 2.3 Dashboard (Flutter-App für Windows, Web & Android)

#### 2.3.1 Architektur & Abhängigkeiten

* **Flutter 3.x** (stable)
* **Packages**:

  * `flutter_bloc` (State-Management)
  * `dio` (HTTP-Client)
  * `web_socket_channel` (WebSocket)
  * `provider` / `get_it` (Dependency Injection)
  * eigenes `SimpleLineChart` Widget (Diagramme)
  * `flutter_secure_storage` (Token-Speicherung)
  * `responsive_framework` (Responsive Layout)

#### 2.3.2 Projektstruktur

```
scs_dashboard/
├── lib/
│   ├── main.dart
│   ├── blocs/
│   ├── models/
│   ├── repositories/
│   ├── services/
│   ├── ui/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── themes/
│   └── utils/
└── pubspec.yaml
```

#### 2.3.3 Anmeldung & Einstieg

1. **Login-Screen**

   * Felder: Benutzername, Passwort
   * Nach erfolgreichem Login: JWT in `flutter_secure_storage` speichern
   * Rolle aus JWT-Claim `role` auslesen → Navigation

2. **Dashboard-Screen**

   * Zeigt Geräte-Liste (Geräte-ID, Status, zuletzt gesehen)
   * Filter: Alle / Online / Offline
   * Rollensteuerung:

     * `admin`: Volle Sichtbarkeit (Geräte, Regeln, System)
     * `user`: Sichtbarkeit Geräte & Regeln (keine System-/Userverwaltung)
     * `viewer`: Nur Lesezugriff (Gerätedetails, Live-Ansicht)

#### 2.3.4 Geräte- & Bereichsverwaltung

* **Geräteliste**: Kachel-Ansicht mit Status-Indikator (grün/rot)
* **Gerätedetail**: Live-Daten (Diagramme), Pin-Konfiguration, Historie, Logs
* **Bereichsverwaltung**: Räume/Zonen anlegen, Geräte zu Zonen zuweisen

#### 2.3.5 Pin-Konfiguration

* **Pin-Liste** (pro Gerät):

  * Pin-Nummer, Typ (Digital/Analog), Name, Einheit
  * Kalibrierung (scale, offset)
  * Schwellenwerte (Trigger)
* **Bearbeitung**: Inline-Edit, Änderung → `PUT /api/v1/devices/{DEVICE_ID}/config`

#### 2.3.6 Live-Daten & Steuerung

* **WebSocket**:

  * Verbindung: `ws://{SERVER}/devices/{DEVICE_ID}`
  * Nachrichten: `telemetry` / `status` / `override`
* **Aktoren-Steuerung**:

  * Direktes Schalten (Relais ON/OFF) per Button → `POST /api/v1/devices/{DEVICE_ID}/pins/{PIN_ID}/action`
  * Dauer-Code/Intervall: Slider oder Eingabefeld für PWM

#### 2.3.7 Ereignisprotokoll & Historie

* **Logs** (letzte 100 Einträge)
* **Historische Sensordaten**:

  * Diagramme (Line Chart, Bar Chart)
  * Zeitbereich wählen (Stunde, Tag, Woche, Monat) → `GET /api/v1/devices/{DEVICE_ID}/data?from=...&to=...`

#### 2.3.8 Regeln & Szenen

* **Regeltypen**:

  * Zeitbasiert (Cron-Syntax)
  * Schwellwertbasiert (z. B. `Temp > 30 °C`)
  * Kombiniert (z. B. Zeit + Schwellwert)
* **Regelerstellung**:

  * „Wenn … Dann …“ (JSON-Format für `conditionJson`, `actionJson`)
  * Aktionen: Relais ON/OFF, MQTT-Publish, Szenen aktivieren
* **Szenen**: Gruppen von Regeln/Pin-Aktionen (z. B. „Abendszenario“)

#### 2.3.9 Benachrichtigungen & Warnungen

* **Alert-Methoden**: E-Mail, WebPush, Signal (über API)
* **Konfiguration**:

  * Schwellenwerte für Alarme (z. B. „CO₂ > 800 ppm“)
  * Empfängerliste (E-Mail-Adressen, WebPush-Token)
* **Funktionsweise**:

  * Regel wird als „Alarmregel“ markiert → bei Bedingung „notify“ (E-Mail/WebPush/Signal)

#### 2.3.10 Authentifizierung & Zugriffsschutz

* **JWT-Token** (Expiry: 2 Stunden)
* **Refresh-Token** (optional)
* **In-App-Guards**:

  * Routen werden nur geladen, wenn Rolle passt (`adminOnly`, `userOrAdmin`)
  * UI-Elemente (Buttons, Menüs) basierend auf Rolle ein-/ausblenden

#### 2.3.11 Responsive & Mobile-freundliches Layout

* **Responsive Design**: Flexibles Grid, Breakpoints (Mobile / Tablet / Desktop)
* **Adaptive Widgets**:

  * Drawer navigiert auf Desktop seitlich, auf Mobil per Overlay
  * Tabellen scrollen horizontal bei schmalen Viewports
* **Barrierefreiheit** (Accessibility):

  * Kontrast hohe Levels, Screen-Reader-Labels

---

## 3. Projektstruktur & Entwicklungsumgebung

Da das Projekt komplett neu startet („von null“), werden hier entsprechende Konventionen und Arbeitsabläufe beschrieben. PlatformIO wird **nicht** verwendet, sondern ausschließlich die Arduino IDE und Flutter CLI.

### 3.1 Gesamt-Repository

```
cfh-scs/
├── scs-firmwares/
│   ├── esp8266/
│   │   └── scs_esp8266/            // Arduino-IDE-Projekt für ESP8266
│   ├── esp32/
│   │   └── scs_esp32/              // Arduino-IDE-Projekt für ESP32
│   └── mega2560/
│       └── scs_mega2560/           // Arduino-IDE-Projekt für Arduino Mega 2560
├── scs-server/
│   ├── src/
│   ├── migrations/
│   ├── seeders/
│   ├── .env                        // Umgebungsvariablen
│   ├── swagger.yaml                // API-Dokumentation
│   └── package.json
└── scs-dashboard/
    ├── lib/
    └── pubspec.yaml
```

### 3.2 Firmware-Entwicklung (Arduino IDE)

* **Verzeichnisstruktur**

  * Jeder Controller hat ein eigenes Unterverzeichnis (`scs_esp8266`, `scs_esp32`, `scs_mega2560`) mit `*.ino`, `config.h`, `pins.h`, `sensors/`, `actuators/`, `utils/`.
* **Kompatibilität**

  * ESP8266: Board-Manager-URL: `http://arduino.esp8266.com/stable/package_esp8266com_index.json`
  * ESP32: Board-Manager-URL: `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
  * Mega 2560: Arduino/Genuino Mega oder Mega 2560
* **Bibliotheken**

  * Gemeinsame: `PubSubClient`, `ArduinoJson`,
  * ESP8266: `ESP8266WiFi`, `ESP8266HTTPClient`, `ESP8266httpUpdate`, `ESP8266WebServer`
  * ESP32: `WiFi.h`, `HTTPClient.h`, `Update.h`, `AsyncWebServer`
  * Mega 2560: `Ethernet.h`, `SPI.h`, `WebSocketsClient` (EthernetClient-kompatibel), ggf. `PubSubClient`
* **Tools**

  * **ESP8266/ESP32**: Mono-USB-Anschluss (TTL-Serial), Baudrate 115200
  * **Mega 2560**: USB-B, Baudrate 115200

### 3.3 Server-Entwicklung (Node.js)

* **Node-Version**: v16 LTS oder höher
* **Skripte** (package.json)

  * `start`: `node src/index.js`
  * `dev`: `nodemon src/index.js`
  * `migrate`: `sequelize db:migrate`
  * `seed`: `sequelize db:seed:all`
* **Umgebungsvariablen** (`.env`)

  * `PORT` (Server-Port)
  * `DB_HOST`, `DB_USER`, `DB_PASS`, `DB_NAME` (Datenbank)
  * `JWT_SECRET` (Schlüssel für JWT)
  * `MQTT_BROKER_URL` (optional)

### 3.4 Dashboard-Entwicklung (Flutter)

* **Flutter-Version**: 3.x (stable)
* **Befehle**

  * `flutter pub get`
  * `flutter run -d chrome` (Web)
  * `flutter run -d windows` (Windows)
  * `flutter run -d android` (Android)
* **Debugging**

  * `flutter devtools` (Performance, Netzwerk, Logging)
  * Inspector für Widget-Baum

---

## 4. REST API (Dokumentation)

Die API folgt dem Pfadpräfix `/api/v1`. Alle Endpunkte erfordern einen gültigen JWT im Header `Authorization: Bearer <token>`, außer die Authentifizierungsrouten.

### 4.1 Authentifizierung

* **POST /auth/login**

  * Request Body: `{ "username": "...", "password": "..." }`
  * Response: `{ "token": "...", "expiresIn": 7200, "role": "admin" }`

* **POST /auth/register** (nur `admin`)

  * Request Body: `{ "username": "...", "password": "...", "role": "user" }`

### 4.2 Geräte-Endpunkte

* **GET /api/v1/devices**

  * Rückgabe: Liste aller Geräte (abhängig von Rolle)

* **GET /api/v1/devices/{DEVICE\_ID}/config**

  * Rückgabe:

    ```json
    {
      "deviceId": "<ID>",
      "sensors": [ { "pin": 1, "type": "temperature", "scale": 1.0, "offset": 0.0 }, … ],
      "actuators": [ { "pin": 5, "type": "relay", "activeHigh": true }, … ]
    }
    ```

* **POST /api/v1/devices/{DEVICE\_ID}/data**

  * EINZELNE Sensordaten: `{ "timestamp": "2025-06-06T12:34:56Z", "dataJson": { "T": 22.5, "H": 45.0 } }`
  * Response: `201 Created`

* **POST /api/v1/devices/{DEVICE\_ID}/data/bulk**

  * BATCH: `{ "data": [ { "timestamp": "...", "dataJson": { … } }, … ] }`

* **POST /api/v1/devices/{DEVICE\_ID}/pins/{PIN\_ID}/action**

  * Aktuatorsteuerung: `{ "action": "ON" }` oder `{ "action": "OFF" }` oder `{ "action": "PWM", "value": 128 }`

### 4.3 Rules & Scenes

* **GET /api/v1/rules**

  * Rückgabe: Liste aller Regeln

* **POST /api/v1/rules**

  * Request Body:

    ```json
    {
      "deviceId": "<ID>",
      "pinId": 5,
      "condition": { "type": "threshold", "operator": ">", "value": 30 },
      "action": { "type": "pin", "pin": 7, "action": "ON" },
      "schedule": { "cron": "0 18 * * *" },
      "type": "timeAndThreshold"
    }
    ```

* **DELETE /api/v1/rules/{RULE\_ID}**

### 4.4 Benutzerverwaltung

* **GET /api/v1/users** (nur `admin`)

  * Rückgabe: Liste aller Benutzer (`username`, `role`)

* **POST /api/v1/users** (nur `admin`)

  * Erstellen: `{ "username": "...", "password": "...", "role": "user" }`

* **PUT /api/v1/users/{USER\_ID}** (nur `admin`)

  * Ändern: `{ "role": "viewer" }`

* **DELETE /api/v1/users/{USER\_ID}** (nur `admin`)

---

## 5. Erweiterte Funktionen

### 5.1 Automatische Kalibrierung von Sensoren

* **Kalibrierungsroutinen**

  * Admin ruft im Dashboard auf Pin-Detailseite „Kalibrieren“ auf.
  * Firmware sendet Leerlaufwert bzw. Referenzwert an Server.
  * Server berechnet `scale` und `offset` basierend auf Soll-Ist-Vergleich.
  * Firmware wendet bei jeder Messung an:

    ```cpp
    kalibrierterWert = rohwert * scale + offset;
    ```

### 5.2 Manuelle Übersteuerung (Admin-Override)

* **Admin-Override**

  * Admin kann in Dashboard jede Pin-Aktion erzwingen („Relais X OFF setzen“), unabhängig von Regeln.
  * Workflow:

  1. Admin klickt bei Pin auf „Override“ → Slider oder Toggle erscheint.
  2. App sendet `POST /api/v1/devices/{DEVICE_ID}/pins/{PIN_ID}/action` → Aktuator setzt Zustand.
  3. Daten werden per WebSocket an alle Clients aktualisiert, Timer für manuelle Steuerung beendet nach konfigurierbarer Zeit.

### 5.3 Benachrichtigungen & Warnungen

* **Alert-Methoden**: E-Mail, WebPush, Signal (über API)
* **Konfiguration**:

  * Schwellenwerte für Alarme (z. B. „CO₂ > 800 ppm“)
  * Empfängerliste (E-Mail-Adressen, WebPush-Token)
* **Funktionsweise**:

  * Regel wird als „Alarmregel“ markiert → bei Bedingung „notify“ (E-Mail/WebPush/Signal)

---

## 6. Sicherheit & Authentifizierung

### 6.1 JWT & Rollen

* **JWT-Token** (Expiry: 2 Stunden)
* **Rollen**: `admin`, `user`, `viewer`
* **Backend**:

  * Passwort-Hashing mit `bcrypt` oder `argon2`
  * JWT-Signatur mit `JWT_SECRET`
* **Firmware**:

  * API-Token (`deviceKey`) in `config.h` oder per Provisionierung konfiguriert

### 6.2 Transportverschlüsselung

* **HTTPS**: Server betreibt TLS (zertifiziert)
* **Firmware** (ESP8266/ESP32):

  * SSL-Client-Verbindung (`WiFiClientSecure`)
  * Zertifikat-Pinning (optional)

### 6.3 Zugriffsschutz Dashboard

* **Flutter-App**:

  * Speichert JWT im `flutter_secure_storage`
  * Routenschutz: Guards basierend auf Rolle

---

## 7. Monitoring & Logging

### 7.1 Firmware-Logging

* **Serieller Monitor** (Debug-Ausgaben)
* Optional: Log-Level (Debug, Info, Warn, Error) über `config.h`
* Bei Speicherknappheit auf Mega 2560: Nur `Error` und `Warn`

### 7.2 Server-Logging

* **Winston** (Logging-Bibliothek)
* Log-Level: `error`, `warn`, `info`, `debug`
* Rotation: Tägliche Log-Dateien, maximale Größe 10 MB
* Speicherort: `/var/log/scs-server/`

### 7.3 Dashboard-Logging

* **In-App-Logging** (nur `debug`)
* Fehlerberichte werden per Snackbar angezeigt; bei kritischen Fehlern Push-Benachrichtigung an Admin

---

## 8. Backup & Restore

### 8.1 Datenbank-Backup

* **Node.js**:

  * Cron-Job: Tägliches Backup `mysqldump` oder `pg_dump` → Speicherort `/backups/{YYYY-MM-DD}.sql`
  * Alternativ: Automatisierte Sequelize-Exports in JSON

### 8.2 Benutzerdaten & Konfiguration

* **Export CSV**: Benutzer, Geräte, Regeln
* **Import CSV**: Über Dashboard → `POST /api/v1/admin/import` → Verknüpfung mit Migrations

---

## 9. Roadmap

1. **Q3 2025**

   * iOS-Unterstützung für Dashboard (Flutter)
   * Erweiterte MQTT-Funktionen (Retained Messages, QoS)
   * Integration von LoRaWAN-Controllern (Lora WAN-Firmware)

2. **Q4 2025**

   * Unterstützung für ARM-basierte Controller (z. B. Raspberry Pi Zero W)
   * Erweiterte Regel-Engine: Machine Learning (Anomalieerkennung)
   * Integration externer Cloud-Dienste (AWS IoT, Azure IoT Hub)

3. **2026+**

   * Vollständige Containerisierung (Docker, Kubernetes)
   * Dashboard: Progressive Web App (PWA)
   * Multi-Tenant-Betrieb (Mandantenfähiger Server)

---

## 10. Anhang

### 10.1 Glossar

* **OTA**: Over-The-Air (Firmware-Update über Netz)
* **SPIFFS / LittleFS**: Dateisystem auf Flash für ESP
* **MQTT**: Message Queuing Telemetry Transport (Publish/Subscribe)
* **mDNS**: Multicast DNS (Servicediscovery)
* **rtc**: Real Time Clock (Uhrzeit-Funktionalität)

### 10.2 Beispielkonfiguration `config.h` (ESP8266)

```cpp
#ifndef CONFIG_H
#define CONFIG_H

#define DEVICE_ID           "esp8266-01"
#define WIFI_SSID           "MeinWLAN"
#define WIFI_PASSWORD       "MeinPasswort"
#define SERVER_URL          "https://meinserver.de"
#define DEVICE_KEY          "abc123def456"
#define PROVISIONING_MODE   true  // SoftAP-Modus beim ersten Start

// Pin-Definitionen (Beispiel):
#define PIN_TEMPERATURE     A0
#define PIN_HUMIDITY        2
#define PIN_RELAY_1         5

#endif // CONFIG_H
```

### 10.3 Beispielkonfiguration `config.h` (ESP32)

```cpp
#ifndef CONFIG_H
#define CONFIG_H

#define DEVICE_ID           "esp32-01"
#define WIFI_SSID           "MeinWLAN"
#define WIFI_PASSWORD       "MeinPasswort"
#define SERVER_URL          "https://meinserver.de"
#define DEVICE_KEY          "uvw789xyz012"
#define PROVISIONING_MODE   true  // SoftAP-Modus beim ersten Start

// Deep-Sleep-Intervall:
#define DEEP_SLEEP_SECONDS  300

// Pin-Definitionen (Beispiel):
#define PIN_TEMPERATURE     34
#define PIN_HUMIDITY        35
#define PIN_RELAY_1         26

#endif // CONFIG_H
```

### 10.4 Beispielkonfiguration `config.h` (Arduino Mega 2560)

```cpp
#ifndef CONFIG_H
#define CONFIG_H

#define DEVICE_ID           "mega2560-01"
// Ethernet statisch (wenn kein DHCP):
#define ETHERNET_IP         "192.168.1.50"
#define ETHERNET_SUBNET     "255.255.255.0"
#define ETHERNET_GATEWAY    "192.168.1.1"
#define SERVER_URL          "http://meinserver.local"
#define DEVICE_KEY          "mno345pqr678"

// Pin-Definitionen (Beispiel):
#define PIN_TEMPERATURE     A0
#define PIN_HUMIDITY        A1
#define PIN_RELAY_1         7

#endif // CONFIG_H
```

---

*(Ende des Dokuments)*
