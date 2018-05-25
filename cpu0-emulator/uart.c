#include "uart.h"

/*
 * feed a character into the machine (from emulator display)
 */
unsigned uart_feed(struct machine_t* m, unsigned c){
  if (m->regs[REG_FR] & FRBIT_UART1_INRDY)
    return 1; // machine cannot consume input character c
  // now that machine can consume c, just by going into the uart interrupt
  // generate an interrupt
  m->regs[REG_FR] |= FRBIT_UART1_INRDY;
  m->regs[REG_FR] |= FRBIT_UART1_IN;
  // probably direct write instead mem_write? any justification?
  assert(mem_write(m, UART1_IN, c) == 0);
	return 0; // machine consumed input character
}

/*
 * pulls a character out from machine (onto emulator display)
 */
unsigned uart_request(struct machine_t * m, unsigned * rtn){
  static int wait = UART_INIT_WAIT;
  if (m->regs[REG_FR] & FRBIT_UART1_OUTRDY)
    return 1; // the machine has nothing to emit
  if (wait == -1) {
    // the machine has something to emit, pull it out
    m->regs[REG_FR] |= FRBIT_UART1_OUTRDY;
    m->regs[REG_FR] |= FRBIT_UART1_OUT;
    // same as feed, justify use of mem_read?
    wait = UART_RANDOM_WAIT;
    assert(mem_read(m, UART1_OUT, rtn) == 0);
    return 0;
  } else {
    wait--;
    return 1;
  }
}
