#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <elf.h>
#include <string.h>
#include <stdint.h>

// EM_CPU0 == 999
#define EM_CPU0 0x3e7

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

#define NUM_REGS 32
#define REG_PC 0
#define REG_SP 1
#define REG_FP 2
#define REG_ZR 3
#define REG_SW 4
#define REG_WR 5
typedef uint32_t reg_t[NUM_REGS];

typedef struct machine_t {
  mm_t mm;
  reg_t regs;
} machine_t;

#define MAX_IMG_SZ 8*1024*1024 
// object image cannot be greater than 8MB


machine_t* load_elf(const char* filename)
{
  // load object into memory
  FILE* fin = fopen(filename, "r");
  assert(fin);
  static uint8_t img[MAX_IMG_SZ];
  assert(fread(img, 1, MAX_IMG_SZ, fin) < MAX_IMG_SZ && "object too big!");

  machine_t* rv = calloc(sizeof(machine_t), 1);
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
    vma_t* vma = (vma_t*) malloc(sizeof(vma_t));
    assert(pheader->p_memsz == pheader->p_filesz); // TODO: bss
    vma->begin = pheader->p_vaddr;
    vma->end = pheader->p_vaddr + pheader->p_memsz;
    vma->perm = pheader->p_flags & VMA_PERM_MASK;
    vma->next = rv->mm.vma;
    rv->mm.vma = vma;
    vma->data = calloc(pheader->p_memsz, 1);
    memcpy(vma->data, img + pheader->p_offset, pheader->p_memsz);
    printf("region %08X - %08x (%d): rwx=%d%d%d\n",
        vma->begin, vma->end, pheader->p_memsz,
        (vma->perm & PF_R) ? 1 : 0,
        (vma->perm & PF_W) ? 1 : 0,
        (vma->perm & PF_X) ? 1 : 0);
  }
}

/* emulator is written in C.
 * for performance reasons.
 *
 * a lightweight elf loader.
 *
 * host machine should be little endian
 */
int main(int argc, char** argv)
{
  if (argc != 2) {
    printf("Usage: %s FILE\n", argv[0]);
    printf("  FILE: executable object.\n");
    return 0;
  }

  load_elf(argv[1]);
}
