#ifndef COMMON_H
#define COMMON_H

#define STACK_SIZE 0x10000
#define STACK_POS 0xF0000000

#define MAPPED_POS 0x300000
#define MAPPED_SIZE 0x100

#define PERM_CHECK

#undef EXCEP_WATCH

#undef WATCH_UART_OUT_DIRECT

#undef INSTR_WATCH

#undef WATCH_DEBUG_STD_OUTPUT

#define Printf(...) do { printf (__VA_ARGS__); fflush(stdout); } while (0)

#endif // COMMON_H