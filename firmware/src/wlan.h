// Wi-Fi: the network the bot joins, kept in flash beside the settings, and how the link is doing.
// The console sets it (`wifi ssid NAME`, then `wifi pass PASSWORD`), or the setup page does;
// remote.h serves the bot on it.  The bot runs the valve whether or not it has a network.
//
// Setup: with no network kept, the bot raises an open network of its own, kSetupSsid, and serves
// a page on it (remote.h) that lists the networks in range and joins one.  Its DNS answers every
// name with the bot's own address, so a phone that joins it opens the page as a captive portal.
// A network the page chooses is tried before it's kept: kept once joined, and then the setup
// network closes a minute later, for the page to say where the bot went.  `wifi setup` raises it
// by hand.
#pragma once

#include <IPAddress.h>
#include <Print.h>
#include <stdint.h>

namespace wifi {

constexpr const char* kHostname = "radiatorbot";        // its DHCP name, and radiatorbot.local
constexpr const char* kSetupSsid = "radiatorbot-setup";  // the open network it's set up on

// Joins the stored network, if there is one, or raises the setup network.
void begin();
// Keeps the link up, and the setup network: call every loop.  A link down for a minute is started
// afresh.
void poll(uint32_t now);

// Stores the network's name, or its password, and joins it.  False, storing nothing, if it's too
// long, or the password isn't 8 to 63 characters (or none, for an open network).
bool setSsid(const char* ssid);
bool setPass(const char* pass);
// Forgets the network and leaves it, and raises the setup network.
void forget();

bool configured();
bool connected();
// The link, in a line: the network, the bot's address on it and the signal, or why there's none.
void describe(Print& out);

// The setup network: raised, closed, and whether it's up.
void openSetup();
void closeSetup();
bool inSetup();
// Whether a client reached the bot by the setup network, by the address it reached.
bool viaSetup(const IPAddress& local);
IPAddress setupAddress();

// A network in range, from the scan the setup network starts.
struct Network {
  char ssid[33];
  int8_t rssi;  // dBm
  bool open;
};
// The networks in range, strongest first, each name once and hidden ones left out: how many, up
// to `max`, or -1 while the scan runs.
int networks(Network* out, int max);
// Scans again, unless a scan or a try is under way.
void rescan();

// Tries a network for the setup page, keeping it only once joined.  False if the setup network
// isn't up, or the name or password won't do (as setSsid and setPass).
bool tryJoin(const char* ssid, const char* pass);
enum class Trial : uint8_t { kNone, kJoining, kJoined, kFailed };
Trial trial();
const char* trialSsid();

}  // namespace wifi
