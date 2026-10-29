#include "wlan.h"

#include <DNSServer.h>
#include <ESPmDNS.h>
#include <Preferences.h>
#include <WiFi.h>
#include <string.h>

namespace wifi {

namespace {

constexpr const char* kSpace = "radiatorbot";  // storage.cpp's namespace
constexpr uint32_t kRestartMs = 60000;         // a link down this long is started afresh
constexpr uint32_t kTryMs = 20000;             // a try not joined by then has failed
constexpr uint32_t kVerdictMs = 5000;          // until then the driver may still say the last try's
constexpr uint32_t kLingerMs = 60000;          // the setup network's stay once a network's joined

char ssid[33];  // 32 at most, as 802.11 allows
char pass[64];  // 63 at most, as WPA2's passphrase
bool mdns = false;
uint32_t down_since = 0;
bool was_up = false;

DNSServer dns;
bool setup = false;
bool setup_auto = false;  // raised for want of a network, so a network joined any way closes it
bool done = false;        // a network's joined: the setup network closes at done_at + kLingerMs
uint32_t done_at = 0;
char try_ssid[33];
char try_pass[64];
Trial try_state = Trial::kNone;
uint32_t try_at = 0;

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

bool fits(const char* name, const char* word) {
  if (name == nullptr || name[0] == '\0' || strlen(name) >= sizeof ssid) return false;
  size_t n = strlen(word);
  return n == 0 || (n >= 8 && n < sizeof pass);
}

void raise(bool automatic) {
  if (!setup) {
    WiFi.mode(WIFI_AP_STA);
    WiFi.softAP(kSetupSsid);
    dns.start(53, "*", WiFi.softAPIP());
    setup = true;
  }
  setup_auto = automatic;
  done = false;
  try_state = Trial::kNone;
  WiFi.scanNetworks(true);
}

void pollSetup(uint32_t now) {
  dns.processNextRequest();
  if (try_state == Trial::kJoining) {
    wl_status_t s = WiFi.status();
    if (s == WL_CONNECTED) {
      if (store("wifi_ssid", try_ssid) && store("wifi_pass", try_pass)) {
        strcpy(ssid, try_ssid);
        strcpy(pass, try_pass);
        try_state = Trial::kJoined;
        done = true;
        done_at = now;
      } else {
        try_state = Trial::kFailed;
        join();
      }
    } else if (now - try_at >= kTryMs ||
               (now - try_at >= kVerdictMs && (s == WL_CONNECT_FAILED || s == WL_NO_SSID_AVAIL))) {
      try_state = Trial::kFailed;
      join();  // back to the network it had, if it had one
    }
  } else if (setup_auto && !done && connected()) {
    // set up some other way, at the console
    done = true;
    done_at = now;
  }
  if (done && now - done_at >= kLingerMs) closeSetup();
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
  if (configured()) {
    join();
  } else {
    raise(true);
  }
}

void poll(uint32_t now) {
  if (setup) pollSetup(now);
  bool up = connected();
  if (up && !mdns) mdns = MDNS.begin(kHostname);
  if (up || ssid[0] == '\0' || try_state == Trial::kJoining) {
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
  raise(true);
}

bool configured() { return ssid[0] != '\0'; }

bool connected() { return WiFi.status() == WL_CONNECTED; }

void describe(Print& out) {
  if (setup) {
    out.printf("setup open as %s at http://%s/; ", kSetupSsid,
               WiFi.softAPIP().toString().c_str());
  }
  if (try_state == Trial::kJoining) {
    out.printf("trying %s", try_ssid);
  } else if (!configured()) {
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

void openSetup() { raise(false); }

void closeSetup() {
  if (!setup) return;
  dns.stop();
  WiFi.softAPdisconnect(true);
  WiFi.mode(WIFI_STA);
  setup = done = false;
  if (try_state == Trial::kJoining) join();
  try_state = Trial::kNone;
}

bool inSetup() { return setup; }

bool viaSetup(const IPAddress& local) { return setup && local == WiFi.softAPIP(); }

IPAddress setupAddress() { return WiFi.softAPIP(); }

int networks(Network* out, int max) {
  int n = WiFi.scanComplete();
  if (n == WIFI_SCAN_RUNNING) return -1;
  int k = 0;
  for (int i = 0; i < n; i++) {
    String name = WiFi.SSID(i);
    if (name.length() == 0 || name.length() >= sizeof out->ssid) continue;
    int8_t rssi = static_cast<int8_t>(WiFi.RSSI(i));
    bool open = WiFi.encryptionType(i) == WIFI_AUTH_OPEN;
    int j = 0;
    while (j < k && strcmp(out[j].ssid, name.c_str()) != 0) j++;
    if (j == k) {
      if (k == max) continue;
      strcpy(out[k].ssid, name.c_str());
      out[k].rssi = -128;
      k++;
    }
    // a name heard from several access points: its strongest
    if (rssi > out[j].rssi) {
      out[j].rssi = rssi;
      out[j].open = open;
    }
  }
  for (int i = 1; i < k; i++) {
    Network held = out[i];
    int j = i;
    for (; j > 0 && out[j - 1].rssi < held.rssi; j--) out[j] = out[j - 1];
    out[j] = held;
  }
  return k;
}

void rescan() {
  if (WiFi.scanComplete() == WIFI_SCAN_RUNNING || try_state == Trial::kJoining) return;
  WiFi.scanDelete();
  WiFi.scanNetworks(true);
}

bool tryJoin(const char* name, const char* word) {
  if (word == nullptr) word = "";
  if (!setup || !fits(name, word)) return false;
  strcpy(try_ssid, name);
  strcpy(try_pass, word);
  WiFi.disconnect();
  WiFi.begin(try_ssid, try_pass[0] ? try_pass : nullptr);
  try_state = Trial::kJoining;
  try_at = millis();
  done = false;
  return true;
}

Trial trial() { return try_state; }

const char* trialSsid() { return try_ssid; }

}  // namespace wifi
