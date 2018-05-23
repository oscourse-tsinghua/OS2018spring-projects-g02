#include "machine.h"
#include <ctype.h>

int mem_write(machine_t* m, uint32_t addr, uint32_t val)
{
  if (addr & 3) {
    Printf("%08X\n", addr);
    assert(0 && "mem_write: unaligned");
    return E_MEM_ALIGN;
  }
#ifdef WATCH_UART_OUT_DIRECT
  // debug hack
  if (addr == MEM_UART_OUT_DIRECT) {
    Printf("> uart direct out: %08X    (d=% 10d)\n",
        val, val);
    return 0;
  }
#endif
  vma_t* vma = m->mm.vma;
  while (vma != NULL) {
    if (vma->begin <= addr && addr < vma->end) {
#ifdef PERM_CHECK
      if (!(vma->perm & PF_W)) {
        Printf("memory error: E_MEM_PERM\n");
        Printf("PC=%08X, va_err=%08X\n", m->regs[REG_PC], addr);
        assert(0);
        return E_MEM_PERM;
      }
#endif
      *(uint32_t*) &(vma->data[addr - vma->begin]) = val;
      return 0;
    }
    vma = vma->next;
  }
  Printf("memory error: E_MEM_SEGFAULT\n");
  Printf("PC=%08X, va_err=%08X\n", m->regs[REG_PC], addr);
  assert(0);
  return E_MEM_SEGFAULT;
}


int mem_read(machine_t* m, uint32_t addr, uint32_t* rv) 
{
  if (addr & 3) {
    assert(0 && "mem_read: unaligned");
    return E_MEM_ALIGN;
  }
  vma_t* vma = m->mm.vma;
  while (vma != NULL) {
    if (vma->begin <= addr && addr < vma->end) {
#ifdef PERM_CHECK
      if (!(vma->perm & PF_R)) {
        Printf("memory error: E_MEM_PERM\n");
        Printf("PC=%08X, va_err=%08X\n", m->regs[REG_PC], addr);
        assert(0);
        return E_MEM_PERM;
      }
#endif
      *rv = *(uint32_t*) &(vma->data[addr - vma->begin]);
      return 0;
    }
    vma = vma->next;
  }
  Printf("memory error: E_MEM_SEGFAULT\n");
  Printf("PC=%08X, va_err=%08X\n", m->regs[REG_PC], addr);
  assert(0);
  return E_MEM_SEGFAULT;
}

int mem_exec(machine_t* m, uint32_t addr,
    void (*cpuexec)(machine_t* m, uint32_t inst))
{
  if (addr & 3) {
    assert(0 && "mem_exec: unaligned");
    return E_MEM_ALIGN;
  }
  vma_t* vma = m->mm.vma;
  while (vma != NULL) {
    if (vma->begin <= addr && addr < vma->end) {
#ifdef PERM_CHECK
      if (!(vma->perm & PF_X)) {
        Printf("memory error: E_MEM_PERM\n");
        Printf("PC=%08X, va_err=%08X\n", m->regs[REG_PC], addr);
        assert(0);
        return E_MEM_PERM;
      }
#endif
      cpuexec(m, *(uint32_t*) &(vma->data[addr - vma->begin]));
      return 0;
    }
    vma = vma->next;
  }
  Printf("memory error: E_MEM_SEGFAULT\n");
  Printf("PC=%08X, va_err=%08X\n", m->regs[REG_PC], addr);
  assert(0);
  return E_MEM_SEGFAULT;
}
