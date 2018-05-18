#include <stdio.h>
#include <assert.h>
#include <stdint.h>
#include <string.h>

#include "common.h"
#include "machine.h"

// EM_CPU0 == 999
#define EM_CPU0 0x3e7

// object image cannot be greater than 8MB
#define MAX_IMG_SZ 8*1024*1024 

vma_t* add_vma(machine_t* m, uint32_t beg, uint32_t end, uint32_t perm)
{
  vma_t* vma = (vma_t*) malloc(sizeof(vma_t));
  vma->begin = beg;
  vma->end = end;
  assert(vma->end > vma->begin);
  vma->perm = perm;
  vma->next = m->mm.vma;
  m->mm.vma = vma;
  vma->data = calloc(end - beg, 1); // 1 MB of stack space
  return vma;
}

void load_elf(const char* filename, machine_t* rv)
{
  // load object into memory
  FILE* fin = fopen(filename, "r");
  assert(fin);
  static uint8_t img[MAX_IMG_SZ];
  assert(fread(img, 1, MAX_IMG_SZ, fin) < MAX_IMG_SZ && "object too big!");

  rv->mm.vma = NULL;

  Elf32_Ehdr* eheader = (Elf32_Ehdr*) img;

  // check magic
  assert(eheader->e_ident[0] == ELFMAG0 && "bad magic");
  assert(eheader->e_ident[1] == ELFMAG1 && "bad magic");
  assert(eheader->e_ident[2] == ELFMAG2 && "bad magic");
  assert(eheader->e_ident[3] == ELFMAG3 && "bad magic");

  // check if is executable object
  assert(eheader->e_type == ET_EXEC && "not executable type");

  // check machine
  assert(eheader->e_machine == EM_CPU0 && "object is not targeted on cpu0");

  printf("e_flags=%08x\n", eheader->e_flags);

  rv->regs[REG_PC] = eheader->e_entry;
  printf("e_entry=%08x\n", eheader->e_entry);

  assert(eheader->e_phentsize == sizeof(Elf32_Phdr));
  for (int no_ph = 0; no_ph < eheader->e_phnum; no_ph++) {
    Elf32_Phdr* pheader = (Elf32_Phdr*) (img +
      eheader->e_phoff + no_ph * eheader->e_phentsize);
    if (pheader->p_type != PT_LOAD) continue;

    // initialize memory region
    assert(pheader->p_memsz >= pheader->p_filesz); // ELF standard
    // the beginning p_filesz bytes are loaded from file
    // while the rest are filled with zero
    vma_t* vma = add_vma(rv, pheader->p_vaddr,
        pheader->p_vaddr + pheader->p_memsz,
        pheader->p_flags & VMA_PERM_MASK);
    memcpy(vma->data, img + pheader->p_offset, pheader->p_filesz);
    printf("region %08X - %08x (%d): rwx=%d%d%d\n",
        vma->begin, vma->end, pheader->p_memsz,
        (vma->perm & PF_R) ? 1 : 0,
        (vma->perm & PF_W) ? 1 : 0,
        (vma->perm & PF_X) ? 1 : 0);
  }

  // XXX: dirty hack to initialize a read / writable stack
  add_vma(rv, STACK_POS, STACK_POS + STACK_SIZE, PF_W | PF_R);
  printf("stack %08X-%08X (%d)\n",
      STACK_POS, STACK_POS + STACK_SIZE, STACK_SIZE);
  add_vma(rv, MAPPED_POS, MAPPED_POS + MAPPED_SIZE, PF_W | PF_R);
  printf("mapped %08X-%08X (%d)\n",
      MAPPED_POS, MAPPED_POS + MAPPED_SIZE, MAPPED_SIZE);
  printf("\n\n");
}


extern void machine_init(machine_t* m);
extern void exec_inst(machine_t* m, uint32_t inst);
extern void check_excep(machine_t* m);

void cpu_run(machine_t* m, unsigned num_cycles)
{
  while (num_cycles--) {
    check_excep(m);
    mem_exec(m, m->regs[REG_PC], exec_inst);
  }
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
    printf("Usage: %s FILE CYCLES\n", argv[0]);
    printf("  FILE: executable object.\n");
    printf("  CYCLES: number of execution cycles.\n");
    return 0;
  }

  machine_init(&machine);  

  load_elf(argv[1], &machine);

  cpu_run(&machine, atoi(argv[2]));
}
