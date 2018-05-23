#include "loader.h"
#include <string.h>

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



