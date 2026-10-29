#include "wlan.h"

#include <ESPmDNS.h>
#include <Preferences.h>
#include <WiFi.h>
#include <string.h>

namespace wifi {

namespace {

constexpr const char* kSpace = "radiatorbot";  // storage.cpp's namespace
constexpr uint32_t kRestartMs = 60000;         // a link down this long is started afresh

char ssid[33];  // 32 at most, as 802.11 allows
char pass[64];  // 63 at most, as WPA2's passphrase
bool mdns = false;
uint32_t down_since = 0;
bool was_up = false;

void join() {
  WiFi.disconnect();
  if (ssid[0] == '\0') return;
  WiFi.begin(ssid, pass[0] ? pass : nullptr);
  down_since = millis();
}

bool store(const char* key, const char* value) {
  Preferences prefs;
  if (!prefs.begin(kSpace, false)) return false;
  bool ok = prefs.putString(key, value) == strlen(value) || value[0] == '\0';
  prefs.end();
  return ok;
}

}  // namespace

void begin() {
  Preferences prefs;
  if (prefs.begin(kSpace, true)) {
    if (prefs.isKey("wifi_ssid")) prefs.getString("wifi_ssid", ssid, sizeof ssid);
    if (prefs.isKey("wifi_pass")) prefs.getString("wifi_pass", pass, sizeof pass);
    prefs.end();
  }
  WiFi.persistent(false);  // the credentials are kept here, not in the Wi-Fi driver's own flash
  WiFi.setHostname(kHostname);
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  join();
}

void poll(uint32_t now) {
  bool up = connected();
  if (up && !mdns) mdns = MDNS.begin(kHostname);
  if (up || ssid[0] == '\0') {
    was_up = up;
    return;
  }
  if (was_up) down_since = now;
  was_up = false;
  if (now - down_since >= kRestartMs) join();
}

bool setSsid(const char* name) {
  if (name == nullptr || name[0] == '\0' || strlen(name) >= sizeof ssid) return false;
  if (!store("wifi_ssid", name)) return false;
  strcpy(ssid, name);
  join();
  return true;
}

bool setPass(const char* word) {
  if (word == nullptr) word = "";
  size_t n = strlen(word);
  if (n != 0 && (n < 8 || n >= sizeof pass)) return false;
  if (!store("wifi_pass", word)) return false;
  strcpy(pass, word);
  join();
  return true;
}

void forget() {
  ssid[0] = pass[0] = '\0';
  Preferences prefs;
  if (prefs.begin(kSpace, false)) {
    prefs.remove("wifi_ssid");
    prefs.remove("wifi_pass");
    prefs.end();
  }
  WiFi.disconnect();
}

bool configured() { return ssid[0] != '\0'; }

bool connected() { return WiFi.status() == WL_CONNECTED; }

void describe(Print& out) {
  if (!configured()) {
    out.print("not set up: `wifi ssid NAME`, then `wifi pass PASSWORD`");
  } else if (connected()) {
    out.printf("on %s as %s (%s.local), %d dBm", ssid, WiFi.localIP().toString().c_str(),
               kHostname, static_cast<int>(WiFi.RSSI()));
  } else if (WiFi.status() == WL_NO_SSID_AVAIL) {
    out.printf("can't find %s: is it in range, and its name right?", ssid);
  } else if (WiFi.status() == WL_CONNECT_FAILED) {
    out.printf("%s turned it away: check the password", ssid);
  } else {
    out.printf("joining %s", ssid);
  }
}

}  // namespace wifi
