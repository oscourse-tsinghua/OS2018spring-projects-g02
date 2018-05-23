#ifndef MACHINE_H
#define MACHINE_H

#include <stdint.h>
#include <elf.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include "common.h"

// EM_CPU0 == 999
#define EM_CPU0 0x3e7


/******************************************************************************/
// register
#define NUM_REGS 32
#define REG_PC 0
#define REG_SP 1
#define REG_FP 2
#define REG_ZR 3
#define REG_FR 4
#define REG_WR 5
#define REG_LR 7
typedef uint32_t reg_t[NUM_REGS];

#define FRBIT_HALT (1u << 0u)
#define FRBIT_GIE (1u << 1u)
#define FRBIT_ERET (1u << 2u)
#define FRBIT_CLKEN (1u << 3u)
#define FRBIT_CLK (1u << 4u)
#define FRBIT_UART1_OUTEN (1u << 5u)
#define FRBIT_UART1_OUT (1u << 6u)
#define FRBIT_UART1_INEN (1u << 7u)
#define FRBIT_UART1_IN (1u << 8u)
#define FRBIT_UART1_OUTRDY (1u << 9u)
#define FRBIT_UART1_INRDY (1u << 10u)

#define UART1_OUT 0x300000
#define UART1_IN 0x300010
#define IRQ_HANDLER 0x300020
#define TIMER_PERIOD 0x300030


/******************************************************************************/
// memory
#define VMA_PERM_MASK 0x07
typedef struct vma_t {
  uint32_t begin;
  uint32_t end;
  uint8_t perm;
  uint8_t* data;
  struct vma_t* next;
} vma_t;

typedef struct mm_t {
  vma_t* vma;
} mm_t;

#define MEM_UART_OUT_DIRECT 0x300090

#define E_MEM_SEGFAULT 1
#define E_MEM_PERM 2
#define E_MEM_ALIGN 3


/******************************************************************************/
// machine abstraction:
typedef struct machine_t {
  mm_t mm;
  reg_t regs;

  uint32_t cycno;
} machine_t;

int mem_write(machine_t* m, uint32_t addr, uint32_t val);
int mem_read(machine_t* m, uint32_t addr, uint32_t* rv);
int mem_exec(machine_t* m, uint32_t addr,
    void (*cpuexec)(machine_t* m, uint32_t inst));

vma_t* add_vma(machine_t* m, uint32_t beg, uint32_t end, uint32_t perm);


/******************************************************************************/
// machine specific
void check_excep(machine_t* m);
void exec_inst(machine_t* m, uint32_t inst);
void machine_init(machine_t* m);

#endif // MACHINE_H
