#include "storage.h"

#include <Preferences.h>
#include <string.h>

namespace storage {

namespace {

// One image, written whole as one NVS blob: a slot a field, its name and its value as the console
// writes it, so a firmware that adds, drops or reorders fields reads what an older one stored, and
// a value is checked as `set` checks it.
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

constexpr const char* kSpace = "radiatorbot";  // the NVS namespace, shared with wlan.cpp's keys
constexpr const char* kKey = "settings";

Image image;  // off the stack: 776 bytes

}  // namespace

void load(valve::Settings& s) {
  Preferences prefs;
  memset(&image, 0, sizeof image);
  if (!prefs.begin(kSpace, true)) return;  // read-only: the namespace isn't there until a save
  size_t got = prefs.getBytes(kKey, &image, sizeof image);
  prefs.end();
  // nothing stored yet
  if (got != sizeof image || image.magic != kMagic || image.count > kSlots) return;
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
  Preferences prefs;
  if (!prefs.begin(kSpace, false)) return false;
  bool ok = prefs.putBytes(kKey, &image, sizeof image) == sizeof image;
  prefs.end();
  return ok;
}

bool erase() {
  Preferences prefs;
  if (!prefs.begin(kSpace, false)) return false;
  bool ok = prefs.clear();
  prefs.end();
  return ok;
}

}  // namespace storage
