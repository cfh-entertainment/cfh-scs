# CFH-Entertainment – Smart Control System (SCS)

## Übersicht

Dieses Projekt verbindet Firmware für Mikrocontroller, einen Node.js‑Server und ein Flutter‑Dashboard, um Sensoren und Aktoren komfortabel zu steuern. Das Ziel ist eine modulare, leicht erweiterbare Lösung für Festival‑, Bühnen‑ oder Gewächshaus‑Automatisierung.

---

## Repository‑Struktur

```
cfh-scs/
├── scs-firmwares/      # Firmware‑Quellcode für ESP8266/ESP32/Arduino Mega 2560
├── scs-server/         # Node.js‑Server (Express, Sequelize, WebSocket)
├── scs-control/        # Flutter‑Dashboard (Desktop, Web, Android)
├── LICENSE             # MIT‑Lizenz
└── README.md           # Dieses Dokument
```

---

## Quickstart (Entwicklungsumgebung)

### Voraussetzungen

* **Betriebssystem:** Ubuntu 25.04 64 bit, Windows 10/11 oder macOS
* **Software:** Git, Node.js ≥ 20 LTS, npm, Python ≥ 3 .x (für *node‑gyp*), Flutter SDK ≥ 3 .x, Arduino IDE ≥ 2.3
* **Hardware:** Raspberry Pi 4 B (Ubuntu Server 25.04) als Dev‑Server

### 1. Repository klonen

```bash
git clone https://github.com/<dein‑Git‑User>/cfh-scs.git
cd cfh-scs
```

### 2. Server einrichten (auf dem Raspberry Pi)

```bash
cd scs-server
npm install                 # Abhängigkeiten
cp .env.example .env        # Beispiel‑Konfiguration kopieren
# 👉 In .env: DB_URL, JWT_SECRET, WS_PORT, HTTP_PORT anpassen

npx sequelize-cli db:create # Datenbank anlegen
npx sequelize-cli db:migrate
npm start                   # Server starten
```

**Wichtig:** Halte den Ordner `scs-server` per FTP‑Sync aktuell. Nach jedem Pull ggf. `npm install` ausführen.

### 3. Firmware flashen

1. Arduino IDE öffnen
2. Gewünschtes Board auswählen (z. B. **ESP32 DevModule**).
3. Sketch unter `scs-firmwares/esp32` oder `esp8266` öffnen.
4. In `config.h` folgende Zeilen anpassen (**Code‑Einfügepunkt ✅**):

   ```cpp
   #define WIFI_SSID   "DeinWLAN"
   #define WIFI_PASS   "Passwort"
   #define SERVER_HOST "raspberrypi.local" // oder IP
   #define SERVER_PORT 1883                // MQTT/WebSocket Port
   ```
5. Hochladen ➡️ Fertig!

### 4. Dashboard starten

```bash
cd scs-control
flutter pub get
flutter run -d windows    # alternativ chrome / android
```

---

## Standard‑Workflow

1. **Server** bereitstellen (Standalone oder Docker – *Dockerfile* folgt)
2. **Controller** flashen & ins Netzwerk einbinden
3. **Serveradresse** im Dashboard hinterlegen (Dropdown speichert Hosts)
4. **Controller registrieren**
5. **Pins konfigurieren**, Bereichen zuordnen & **Regeln definieren**

---

## Namenskonventionen

| Ebene             | Beispiel                    |
| ----------------- | --------------------------- |
| **DB‑Spalte**     | `device_id`, `last_seen_at` |
| **JS‑Variable**   | `lastSeenAt`                |
| **API‑Parameter** | `pinMode`, `waterLevelLow`  |
| **Flutter‑State** | `selectedAreaId`            |

---

## Aktuelle Listen

### Pin‑Typen

* `digital_in`, `digital_out`
* `analog_in`, `analog_out`
* `volt_sensor`, `rain_sensor`, `co2_sensor`, `o2_sensor`, `pressure_sensor`
* `relay`, `pwm_fan`, `emergency_stop`, `key_switch`, `toggle_switch`, `button`, `light`

### Bereiche (Beispiele)

* `zeltplatz`
* `main_stage`
* `wachstum`

### Reminder‑Checkliste

* [ ] Konsistente Schreibweisen
* [ ] Schritt‑für‑Schritt‑Erklärungen
* [ ] Gerätespezifische Hinweise
* [ ] Code‑Einfügepunkte markieren
* [ ] Listen hier aktuell halten

---

## Roadmap

* [ ] **Installer** für Server (Windows & Linux, z. B. *pkg* + NSIS)
* [ ] Docker‑Compose Vorlage
* [ ] Szenen‑Engine & Variablen‑System
* [ ] Öffentliche API‑Dokumentation (Swagger UI)
* [ ] Push‑Benachrichtigungen (Firebase Cloud Messaging)
* [ ] WhatsApp‑Bot (optional)

---

## Lizenz

MIT – siehe `LICENSE`
