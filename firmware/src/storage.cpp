#include "storage.h"

#include <EEPROM.h>
#include <string.h>

namespace storage {

namespace {

// One image, written whole (the data flash is erased and written a 1 kB block at a time): a slot a
// field, its name and its value as the console writes it, so a firmware that adds, drops or
// reorders fields reads what an older one stored, and a value is checked as `set` checks it.
constexpr uint32_t kMagic = 0x544f4252;  // "RBOT"
constexpr size_t kSlots = 24;

struct Slot {
  char name[16];
  char value[16];
};

struct Image {
  uint32_t magic;
  uint32_t count;
  Slot slots[kSlots];
};

Image image;  // off the stack: 776 bytes

}  // namespace

void load(valve::Settings& s) {
  EEPROM.get(0, image);
  if (image.magic != kMagic || image.count > kSlots) return;  // nothing stored yet
  for (size_t i = 0; i < image.count; i++) {
    Slot& slot = image.slots[i];
    slot.name[sizeof slot.name - 1] = '\0';
    slot.value[sizeof slot.value - 1] = '\0';
    const valve::Field* f = valve::findField(slot.name);
    // A stored value outside the field's range (an older firmware's) is ignored.
    if (f != nullptr) valve::setField(s, *f, slot.value);
  }
}

bool save(const valve::Settings& s) {
  size_t n = 0;
  const valve::Field* fs = valve::fields(&n);
  if (n > kSlots) return false;
  memset(&image, 0, sizeof image);
  image.magic = kMagic;
  image.count = n;
  for (size_t i = 0; i < n; i++) {
    Slot& slot = image.slots[i];
    strncpy(slot.name, fs[i].name, sizeof slot.name - 1);
    valve::formatField(s, fs[i], slot.value, sizeof slot.value);
  }
  EEPROM.put(0, image);
  const uint8_t* bytes = reinterpret_cast<const uint8_t*>(&image);
  for (size_t i = 0; i < sizeof image; i++) {
    if (EEPROM.read(i) != bytes[i]) return false;
  }
  return true;
}

}  // namespace storage
