// The settings in flash (NVS), one key a field.
#pragma once

#include "settings.h"

namespace storage {

// Reads the stored settings over `s`; fields never stored keep their values.
void load(valve::Settings& s);
// Writes every field.
bool save(const valve::Settings& s);

}  // namespace storage
