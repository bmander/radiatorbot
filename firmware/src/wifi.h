// Wi-Fi: the network the bot joins, kept in flash beside the settings, and how the link is doing.
// The console sets it (`wifi ssid NAME`, then `wifi pass PASSWORD`); remote.h serves the bot on
// it.  The bot runs the valve whether or not it has a network.
#pragma once

#include <Print.h>
#include <stdint.h>

namespace wifi {

constexpr const char* kHostname = "radiatorbot";  // its DHCP name, and radiatorbot.local

// Joins the stored network, if there is one.
void begin();
// Keeps the link up: call every loop.  A link down for a minute is started afresh.
void poll(uint32_t now);

// Stores the network's name, or its password, and joins it.  False, storing nothing, if it's too
// long, or the password isn't 8 to 63 characters (or none, for an open network).
bool setSsid(const char* ssid);
bool setPass(const char* pass);
// Forgets the network and leaves it.
void forget();

bool configured();
bool connected();
// The link, in a line: the network, the bot's address on it and the signal, or why there's none.
void describe(Print& out);

}  // namespace wifi
