#include "storage.h"

#include <EEPROM.h>
#include <string.h>

namespace storage {

namespace {

// One image, written whole (the data flash is erased and written a 1 kB block at a time): a slot a
// field, found by its name, so a firmware that adds, drops or reorders fields reads what an older
// one stored.
constexpr uint32_t kMagic = 0x544f4252;  // "RBOT"
constexpr size_t kSlots = 32;

struct Slot {
  char name[16];
  uint32_t bits;
};

struct Image {
  uint32_t magic;
  uint32_t count;
  Slot slots[kSlots];
};

Image image, readback;  // off the stack: 648 bytes each

}  // namespace

void load(valve::Settings& s) {
  EEPROM.get(0, image);
  if (image.magic != kMagic || image.count > kSlots) return;  // nothing stored yet
  for (size_t i = 0; i < image.count; i++) {
    Slot& slot = image.slots[i];
    slot.name[sizeof slot.name - 1] = '\0';
    const valve::Field* f = valve::findField(slot.name);
    if (f == nullptr) continue;
    // A stored value outside the field's range (an older firmware's) is ignored.
    switch (f->type) {
      case valve::FieldType::kFloat: {
        float v;
        memcpy(&v, &slot.bits, sizeof v);
        if (valve::inRange(*f, v)) valve::floatField(s, *f) = v;
        break;
      }
      case valve::FieldType::kUint:
        if (valve::inRange(*f, slot.bits)) valve::uintField(s, *f) = slot.bits;
        break;
      case valve::FieldType::kBool:
        valve::boolField(s, *f) = slot.bits != 0;
        break;
    }
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
    const valve::Field& f = fs[i];
    Slot& slot = image.slots[i];
    strncpy(slot.name, f.name, sizeof slot.name - 1);
    switch (f.type) {
      case valve::FieldType::kFloat: {
        float v = valve::floatField(s, f);
        memcpy(&slot.bits, &v, sizeof v);
        break;
      }
      case valve::FieldType::kUint:
        slot.bits = valve::uintField(s, f);
        break;
      case valve::FieldType::kBool:
        slot.bits = valve::boolField(s, f) ? 1 : 0;
        break;
    }
  }
  EEPROM.put(0, image);
  EEPROM.get(0, readback);
  return memcmp(&image, &readback, sizeof image) == 0;
}

}  // namespace storage
