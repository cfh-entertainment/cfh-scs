#include <WiFi.h>
#include <PubSubClient.h>
#include <HTTPClient.h>

const char* ssid       = "CFH-AP";
const char* password   = "wow1234wlanlehr3";

const char* mqttServer = "192.168.178.130";
const int   mqttPort   = 1883;

const char* deviceId   = "esp32-test01";
const int   buttonPin  = 4;

WiFiClient espClient;
PubSubClient client(espClient);

unsigned long lastStatus = 0;
int lastButtonState = HIGH;

void setup() {
  Serial.begin(115200);
  pinMode(buttonPin, INPUT_PULLUP);

  WiFi.begin(ssid, password);
  Serial.print("🔌 Verbinde mit WLAN");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500); Serial.print(".");
  }
  Serial.println("✅ verbunden");

  registerDevice();

  client.setServer(mqttServer, mqttPort);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Regelmäßiges Status-Update alle 10 Sekunden
  if (millis() - lastStatus > 10000) {
    lastStatus = millis();
    String topic = "scs/" + String(deviceId) + "/status";
    client.publish(topic.c_str(), "online");
  }

  // Taster-Abfrage (Low = gedrückt)
  int state = digitalRead(buttonPin);
  if (state != lastButtonState) {
    lastButtonState = state;

    if (state == LOW) {
      String topic = "scs/" + String(deviceId) + "/event/button";
      client.publish(topic.c_str(), "pressed");
    }
  }

  delay(100);
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("🔁 MQTT verbinden...");
    if (client.connect(deviceId)) {
      Serial.println("✅ MQTT verbunden");
    } else {
      Serial.print("❌ Fehler, rc=");
      Serial.print(client.state());
      delay(2000);
    }
  }
}

void registerDevice() {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  String serverUrl = "http://192.168.178.130:3000/api/v1/devices";
  String payload = "{"
                   "\"name\":\"" + String(deviceId) + "\","
                   "\"type\":\"ESP32\","
                   "\"ip\":\"" + WiFi.localIP().toString() + "\","
                   "\"status\":\"online\""
                   "}";

  http.begin(serverUrl);
  http.addHeader("Content-Type", "application/json");

  int httpCode = http.POST(payload);
  Serial.print("📡 Gerät-POST: ");
  Serial.println(httpCode);

  if (httpCode == 400 || httpCode == 409) {
    // Gerät existiert evtl. schon → PATCH/PUT versuchen
    serverUrl += "/by-name/" + String(deviceId);
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");
    httpCode = http.PUT(payload);
    Serial.print("🔁 Gerät-PUT: ");
    Serial.println(httpCode);
  }

  http.end();
}