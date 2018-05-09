#ifndef MACHINE_H
#define MACHINE_H

#include <stdint.h>
#include <elf.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>


/******************************************************************************/
// register
#define NUM_REGS 32
#define REG_PC 0
#define REG_SP 1
#define REG_FP 2
#define REG_ZR 3
#define REG_SW 4
#define REG_WR 5
#define REG_LR 7
typedef uint32_t reg_t[NUM_REGS];


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

#define MEM_UART_OUT 0x300000

#define E_MEM_SEGFAULT 1
#define E_MEM_PERM 2
#define E_MEM_ALIGN 3


/******************************************************************************/
// machine abstraction:
typedef struct machine_t {
  mm_t mm;
  reg_t regs;
} machine_t;


static inline int mem_write(machine_t* m, uint32_t addr, uint32_t val)
{
  if (addr & 3)
    return E_MEM_ALIGN;
  // a stupid MMU here
  if (addr == MEM_UART_OUT) {
    printf("uart out: %08X    (d=%d)\n", val, val);
    return 0;
  }
  vma_t* vma = m->mm.vma;
  while (vma != NULL) {
    if (vma->begin <= addr && addr < vma->end) {
      if (!(vma->perm & PF_W)) {
        printf("memory error: E_MEM_PERM\n");
        printf("PC=%08X, va_err=%08X\n", m->regs[REG_PC], addr);
        assert(0);
        return E_MEM_PERM;
      }
      *(uint32_t*) &(vma->data[addr - vma->begin]) = val;
      return 0;
    }
    vma = vma->next;
  }
  printf("memory error: E_MEM_SEGFAULT\n");
  printf("PC=%08X, va_err=%08X\n", m->regs[REG_PC], addr);
  assert(0);
  return E_MEM_SEGFAULT;
}


static inline int mem_read(machine_t* m, uint32_t addr, uint32_t* rv) 
{
  if (addr & 3)
    return E_MEM_ALIGN;
  vma_t* vma = m->mm.vma;
  while (vma != NULL) {
    if (vma->begin <= addr && addr < vma->end) {
      if (!(vma->perm & PF_R)) {
        printf("memory error: E_MEM_PERM\n");
        printf("PC=%08X, va_err=%08X\n", m->regs[REG_PC], addr);
        assert(0);
        return E_MEM_PERM;
      }
      *rv = *(uint32_t*) &(vma->data[addr - vma->begin]);
      return 0;
    }
    vma = vma->next;
  }
  printf("memory error: E_MEM_SEGFAULT\n");
  printf("PC=%08X, va_err=%08X\n", m->regs[REG_PC], addr);
  assert(0);
  return E_MEM_SEGFAULT;
}

static inline int mem_exec(machine_t* m, uint32_t addr,
    void (*cpuexec)(machine_t* m, uint32_t inst))
{
  if (addr & 3)
    return E_MEM_ALIGN;
  vma_t* vma = m->mm.vma;
  while (vma != NULL) {
    if (vma->begin <= addr && addr < vma->end) {
      if (!(vma->perm & PF_X)) {
        printf("memory error: E_MEM_PERM\n");
        printf("PC=%08X, va_err=%08X\n", m->regs[REG_PC], addr);
        assert(0);
        return E_MEM_PERM;
      }
      cpuexec(m, *(uint32_t*) &(vma->data[addr - vma->begin]));
      return 0;
    }
    vma = vma->next;
  }
  printf("memory error: E_MEM_SEGFAULT\n");
  printf("PC=%08X, va_err=%08X\n", m->regs[REG_PC], addr);
  assert(0);
  return E_MEM_SEGFAULT;
}

#endif // MACHINE_H
