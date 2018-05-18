#include <stdio.h>
#include <assert.h>
#include <stdint.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>

#include "common.h"
#include "machine.h"
#include "loader.h"
#include "uart.h"


struct termios * terminal_setup(void){
  struct termios * original = (struct termios *)malloc(sizeof(struct termios));
  struct termios stdio;
  tcgetattr(STDOUT_FILENO, original);

  memcpy(&stdio, original, sizeof(struct termios));
  stdio.c_iflag = 0;
  stdio.c_cflag = 0;
  stdio.c_lflag = 0;
  stdio.c_cc[VMIN] = 1;
  stdio.c_cc[VTIME] = 0;
  tcsetattr(STDOUT_FILENO, TCSANOW, &stdio);
  tcsetattr(STDOUT_FILENO, TCSAFLUSH, &stdio);
  fcntl(STDIN_FILENO, F_SETFL, O_NONBLOCK);
  return original;
}


#define MAX_USER_INBUF 1000
char user_inbuf[MAX_USER_INBUF];
int user_inbuf_beg;
int user_inbuf_end;
#define user_inbuf_adv(v) ((v) = (((v)+1) % MAX_USER_INBUF))

void cpu_run(machine_t* m, unsigned n_cycles)
{
	struct termios * original = terminal_setup();

  user_inbuf_beg = 0;
  user_inbuf_end = 0;

  unsigned nonstop = 0;
  if (n_cycles == 0)
    nonstop = 1;

  while (1) {
    if (!nonstop && !n_cycles--)
      break;
    // check for machine output
    unsigned req_rtn;
    if (uart_request(m, &req_rtn) == 0) {
      printf("> uart std out: %08X    (d=% 10d) (c=%c)\n",
          req_rtn, req_rtn, req_rtn);
      fflush(stdout);
    }

    // check for user input, and buffer it
    char ch;
    if (read(STDIN_FILENO, &ch, 1) > 0) {
      if (ch == 3) break; // Ctrl-C
      user_inbuf[user_inbuf_end] = ch;
      user_inbuf_adv(user_inbuf_end);
    }

    // if any input
    if (user_inbuf_beg != user_inbuf_end) {
      if (uart_feed(m, user_inbuf[user_inbuf_beg]) == 0)
        user_inbuf_adv(user_inbuf_beg);
    }

    // actually execute
    check_excep(m);
    mem_exec(m, m->regs[REG_PC], exec_inst);
  }

  tcsetattr(STDOUT_FILENO, TCSANOW, original);
  tcsetattr(STDOUT_FILENO, TCSAFLUSH, original);

  exit(0);
}


machine_t machine;
/* emulator is written in C.
 * for performance reasons.
 *
 * a lightweight elf loader.
 *
 * host machine should be little endian
 */
int main(int argc, char** argv)
{
  if (argc != 3) {
    printf("Usage: %s FILE MAXCYCLES\n", argv[0]);
    printf("  FILE: executable object.\n");
    printf("  MAXCYCLES: number of execution cycles. 0 means unlimited\n");
    return 0;
  }

  machine_init(&machine);  
  load_elf(argv[1], &machine);
  cpu_run(&machine, atoi(argv[2]));
}
