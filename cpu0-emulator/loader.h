#ifndef LOADER_H
#define LOADER_H

#include "machine.h"

// object image cannot be greater than 8MB
#define MAX_IMG_SZ 8*1024*1024 

void load_elf(const char* filename, machine_t* rv);

#endif // LOADER_H
