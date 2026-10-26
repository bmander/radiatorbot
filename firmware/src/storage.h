// The settings in flash: the R4's data flash, through its EEPROM library.
#pragma once

#include "settings.h"

namespace storage {

// Reads the stored settings over `s`; fields never stored keep their values.
void load(valve::Settings& s);
// Writes every field.
bool save(const valve::Settings& s);

}  // namespace storage
