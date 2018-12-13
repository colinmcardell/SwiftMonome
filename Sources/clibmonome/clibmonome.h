#ifndef _CLIBMONOME_H
#define _CLIBMONOME_H

#include <monome.h>
#include <stdarg.h>

monome_t *monome_connect(const char *monome_device, const char *port) {
  return monome_open(monome_device, port);
};

#endif // _CLIBMONOME_H
