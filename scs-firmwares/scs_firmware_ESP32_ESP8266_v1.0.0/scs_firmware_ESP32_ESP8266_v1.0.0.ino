// ① Plattform-spezifische Includes
#ifdef ESP32
  #include <WiFi.h>
  #include <HTTPClient.h>
#elif defined(ESP8266)
  #include <ESP8266WiFi.h>
  #include <ESP8266HTTPClient.h>
#endif

#include <SPIFFS.h>
#include <ArduinoJson.h>

// ② WLAN-Zugangsdaten (auf dem Server ändern, wenn nötig)
const char* WIFI_SSID     = "CFH-AP";
const char* WIFI_PASSWORD = "wow1234wlanlehr3";

// ③ Server- und Geräte-Konfiguration
const char* SERVER_IP     = "192.168.178.25";      // nur IP, kein Protokoll/Port
const uint16_t SERVER_PORT= 3000;
const uint16_t DEVICE_ID  = 1;                  // entspricht device.id in MySQL

// ④ Pin-Modi definieren
//    Hier später dynamisch aus Server-Config laden
const uint8_t PINS[]      = {2, 3, 4, 5};     // Beispiel: 2x analog, 2x digital
const uint8_t PIN_COUNT   = sizeof(PINS) / sizeof(PINS[0]);

// ⑧ Anmeldedaten für Firmware (bitte anpassen)
const char* AUTH_USERNAME = "scs_firmware";
const char* AUTH_PASSWORD = "wow1234wl";

// Variabeln
unsigned long lastMillis = 0;

// ⑨ Token-Handling
String jwtToken = "";

// ⑤ Initialisierung
void setup() {
  Serial.begin(115200);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWLAN verbunden!");

  loginAndStoreToken();

  // ① Konfiguration vom Server holen
  HTTPClient http;
  String url = String("http://")
  + SERVER_IP
  + ":"
  + String(SERVER_PORT)
  + "/api/v1/devices/"
  + String(DEVICE_ID)
  + "/config";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + jwtToken);
  int code = http.GET();
  if (code == 200) {
    String body = http.getString();
    StaticJsonDocument<1024> doc;
    deserializeJson(doc, body);
    JsonObject cfg = doc["config"].as<JsonObject>();

    // ② Für jeden Eintrag pinMode setzen
    for (JsonPair kv : cfg) {
      int pin = atoi(kv.key().c_str());
      const char* mode = kv.value()["mode"];
      if (strcmp(mode, "Digital In") == 0) {
        pinMode(pin, INPUT);
      } else if (strcmp(mode, "Digital Out") == 0) {
        pinMode(pin, OUTPUT);
      } else if (strcmp(mode, "Analog In") == 0) {
        pinMode(pin, INPUT);
      }
      // Analoge Out & Sonderfunktionen später...
    }
  } else {
    Serial.printf("Config-GET fehlgeschlagen: %d\n", code);
  }
  http.end();
}
// ⑥ Hauptschleife: alle x Sekunden Daten lesen und senden
void loop() {
  if (millis() - lastMillis >= 1000) { // alle 1 Sekunde
    lastMillis = millis();
    if (WiFi.status() == WL_CONNECTED) {
      sendSensorData();
      processCommands();
    } else {
      // Bei Verbindungsabbruch erneut verbinden
      WiFi.reconnect();
    }
  }  
}

// ⑦ Funktion: Sensordaten lesen und per HTTP-POST senden
void sendSensorData() {
  // JSON-Dokument anlegen
  StaticJsonDocument<512> doc;
  // Wurzel: dataJson
  JsonObject root = doc.to<JsonObject>();
  JsonObject dataJson = root.createNestedObject("dataJson");

  // Jeden Pin auslesen
  for (uint8_t i = 0; i < PIN_COUNT; i++) {
    uint8_t pin = PINS[i];
    int value;
    // Hier nur Rohdaten: analogRead vs. digitalRead
    #ifdef ESP32
      // analogRead auf ESP32 liefert 0–4095
      value = analogRead(pin);
    #elif defined(ESP8266)
      // A0 auf ESP8266 liefert 0–1023
      if (pin == A0) value = analogRead(pin);
      else           value = digitalRead(pin);
    #endif
    // In JSON einfügen: key ist Pin-Nummer
    dataJson[String(pin)] = value;
  }

  // URL zusammenbauen: http://IP:Port/api/v1/devices/DEVICE_ID/data
  String url = String("http://")
  + SERVER_IP
  + ":"
  + String(SERVER_PORT)
  + "/api/v1/devices/"
  + String(DEVICE_ID)
  + "/data";

  // HTTP-Client starten
  HTTPClient http;
  http.begin(url);


  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + jwtToken);

  // JSON in String serialisieren
  String body;
  serializeJson(root, body);

  // POST absenden
  int code = http.POST(body);
  Serial.printf("POST %s -> %d\n", url.c_str(), code);

  http.end();
}

// ★ Neue Funktion am Ende hinzufügen:
void processCommands() {
  HTTPClient http;
  String url = String("http://")
  + SERVER_IP
  + ":"
  + String(SERVER_PORT)
  + "/api/v1/devices/"
  + String(DEVICE_ID)
  + "/commands";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + jwtToken);
  int code = http.GET();
  if (code == 200) {
    String payload = http.getString();
    StaticJsonDocument<512> doc;
    DeserializationError err = deserializeJson(doc, payload);
    if (!err) {
      JsonArray arr = doc.as<JsonArray>();
      for (JsonObject cmd : arr) {
        int pin   = cmd["pin"];
        int value = cmd["value"];
        // digitaler output
        pinMode(pin, OUTPUT);
        digitalWrite(pin, value ? HIGH : LOW);
        Serial.printf("CMD: pin %d -> %d\n", pin, value);
      }
    } else {
      Serial.println("JSON-Fehler beim Parsen der Befehle");
    }
  } else {
    Serial.printf("GET commands fehlgeschl.: %d\n", code);
  }
  http.end();
}

// ★ Funktion: Login holen und Token in SPIFFS sichern
void loginAndStoreToken() {
  HTTPClient http;
  String url = String("http://") 
  + SERVER_IP 
  + ":" 
  + String(SERVER_PORT)
  + "/api/v1/auth/login";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + jwtToken);

  // Login-Body
  StaticJsonDocument<200> doc;
  doc["username"] = AUTH_USERNAME;
  doc["password"] = AUTH_PASSWORD;
  String body;
  serializeJson(doc, body);

  int code = http.POST(body);
  if (code == 200) {
    String resp = http.getString();
    StaticJsonDocument<256> jdoc;
    deserializeJson(jdoc, resp);
    jwtToken = jdoc["token"].as<String>();
    Serial.println("JWT erhalten: " + jwtToken);

    // Token in Datei schreiben
    File f = SPIFFS.open("/token.txt", "w");
    f.print(jwtToken);
    f.close();
    Serial.println("JWT in SPIFFS gespeichert");
  } else {
    Serial.printf("Login fehlgeschlagen: %d\n", code);
  }
  http.end();
}
