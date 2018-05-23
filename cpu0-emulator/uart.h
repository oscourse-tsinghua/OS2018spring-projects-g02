#ifndef UART_H
#define UART_H

#include "machine.h"

/*
 * feed a character into the machine (from emulator display)
 */
unsigned uart_feed(struct machine_t* m, unsigned c);

/*
 * pulls a character out from machine (onto emulator display)
 */
unsigned uart_request(struct machine_t * m, unsigned * rtn);

#endif // UART_H
