#include "clibmonome.h"

monome_t *monome_connect(const char *monome_device, const char *port,
                         va_list args) {
  return monome_open(monome_device, port, args);
};