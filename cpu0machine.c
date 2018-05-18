#include "machine.h"
#include "common.h"

#include <string.h>
#include <assert.h>
#include <stdio.h>

uint32_t excep = 0;

void machine_init(machine_t* m)
{
  memset(m, 0, sizeof(m));
  m->regs[REG_FR] = 0x200; // TODO: FR
  m->regs[REG_WR] = 4;
  m->regs[REG_ZR] = 0;

  m->regs[REG_SP] = STACK_POS + STACK_SIZE - 4;

  m->cycno = 0;
}

#define decode_opcode(i) (((i)>>26) & 0x3F)
#define decode_rx(i) (((i)>>21) & 0x1F)
#define decode_ry(i) (((i)>>16) & 0x1F)
#define decode_rz(i) (((i)>>11) & 0x1F)
#define decode_imm16(i) ((i) & 0xFFFF)
#define decode_imm16sext(i) ((int) ((short) ((i) & 0xFFFF)))
#define decode_imm26(i) ((i) & 0x3FFFFFF)
static inline uint32_t decode_imm26sext(uint32_t i) {
  if (i & (1<<25)) {
    return i | 0xFC000000;
  } else {
    return i & 0x03FFFFFF;
  }
}

#define OPCODE_ADD 0
#define OPCODE_SUB 1
#define OPCODE_MUL 2
#define OPCODE_DIV 3

#define OPCODE_AND 4
#define OPCODE_OR 5
#define OPCODE_XOR 6

#define OPCODE_LD 7
#define OPCODE_ST 8

#define OPCODE_SHR 9
#define OPCODE_SHL 10

#define OPCODE_BEQ 11
#define OPCODE_BLT 12

#define OPCODE_ADDIU 13
#define OPCODE_LUI 14

#define OPCODE_ORI 16
#define OPCODE_LB 17
#define OPCODE_SB 18
#define OPCODE_BNE 19
#define OPCODE_JR 20
#define OPCODE_JALR 21
#define OPCODE_JSUB 22

char* instrname[] = {
  "add", "sub", "mul", "div",
  "and", "or",  "xor", "loa",
  "sto", "shr", "shl", "beq",
  "blt", "addiu", "lui", "BAD",
  "ori", "lb", "sb", "bne",
  "jr", "jalr", "jsub"
};

#ifdef INSTR_WATCH

#define INSTR_TYPE_R 1
#define INSTR_TYPE_I 2
#define INSTR_TYPE_J 3

int instr_type(uint32_t opcode)
{
  switch (opcode) {
    case OPCODE_ADD: case OPCODE_SUB: case OPCODE_MUL: case OPCODE_DIV:
    case OPCODE_AND: case OPCODE_OR:  case OPCODE_XOR: case OPCODE_SHR:
    case OPCODE_SHL:
      return INSTR_TYPE_R;
    case OPCODE_LD:  case OPCODE_ST:  case OPCODE_BEQ: case OPCODE_BLT:
    case OPCODE_ADDIU: case OPCODE_LUI: case OPCODE_ORI:
    case OPCODE_LB: case OPCODE_SB: case OPCODE_BNE: case OPCODE_JR:
    case OPCODE_JALR:
      return INSTR_TYPE_I;
    case OPCODE_JSUB:
      return INSTR_TYPE_J;
    default:
      assert(0 && "bad opcode");
  }
}

void dump_fr(machine_t* m)
{
  unsigned r = m->regs[REG_FR];
  if (r & FRBIT_GIE)
    printf("GIE ");
  if (r & FRBIT_ERET)
    printf("ERET ");
  if (r & FRBIT_CLKEN)
    printf("CLKEN ");
  if (r & FRBIT_CLK)
    printf("CLK ");
  if (r & FRBIT_UART1_OUTEN)
    printf("OUTEN ");
  if (r & FRBIT_UART1_OUT)
    printf("OUT ");
  if (r & FRBIT_UART1_INEN)
    printf("INEN ");
  if (r & FRBIT_UART1_IN)
    printf("IN ");
  if (r & FRBIT_UART1_OUTRDY)
    printf("OUTRDY ");
  if (r & FRBIT_UART1_INRDY)
    printf("INRDY ");
}

#endif


void exec_inst(machine_t* m, uint32_t inst)
{
  assert(!((m->regs[REG_PC]) & 3) && "unaligned IF");
  m->regs[REG_PC] += sizeof(uint32_t);
  uint32_t opcode = decode_opcode(inst);
  uint32_t rx = decode_rx(inst);
  uint32_t ry = decode_ry(inst);
  uint32_t rz = decode_rz(inst);
  uint32_t imm = decode_imm16(inst);
  uint32_t immsext = decode_imm16sext(inst);
  uint32_t imm26sext = decode_imm26sext(inst);

#ifdef INSTR_WATCH
  switch (instr_type(opcode)) {
    case INSTR_TYPE_R:
      printf("* [%08X]{%08X} [%-10d] [%6s] opcode=%d, rx=%d, ry=%d, rz=%d\n",
          m->regs[REG_PC], inst, m->cycno, instrname[opcode], opcode, rx, ry, rz);
      break;
    case INSTR_TYPE_I:
      if (opcode == OPCODE_BEQ && rx == REG_ZR && ry == REG_ZR && immsext == -4)
        break; // don't print spin instructions
      printf("* [%08X]{%08X} [%-10d] [%6s] opcode=%d, rx=%d, ry=%d, imm=%d (unsigned=%d)\n",
          m->regs[REG_PC], inst, m->cycno, instrname[opcode], opcode, rx, ry, immsext, imm);
      break;
    case INSTR_TYPE_J:
      printf("* [%08X]{%08X} [%-10d] [%6s] opcode=%d, imm=%d (hex=%08X)\n",
          m->regs[REG_PC], inst, m->cycno, instrname[opcode], opcode, imm26sext, imm26sext);
      break;
    default:
      assert(0 && "bad instr type");
  }
#endif

  int err = 0;

  switch (opcode) {
    case OPCODE_ADD:
      m->regs[rx] = m->regs[ry] + m->regs[rz];
      break;
    case OPCODE_SUB:
      m->regs[rx] = m->regs[ry] - m->regs[rz];
      break;
    case OPCODE_MUL:
      m->regs[rx] = m->regs[ry] * m->regs[rz];
      break;
    case OPCODE_DIV:
      assert(0 && "div not implemented");
      break;
    case OPCODE_AND:
      m->regs[rx] = m->regs[ry] & m->regs[rz];
      break;
    case OPCODE_OR:
      m->regs[rx] = m->regs[ry] | m->regs[rz];
      break;
    case OPCODE_XOR:
      m->regs[rx] = m->regs[ry] ^ m->regs[rz];
      break;
    case OPCODE_LD:
      err = mem_read(m, m->regs[ry] + immsext, &(m->regs[rx]));
      assert(err == 0);
      break;
    case OPCODE_ST:
      err = mem_write(m, m->regs[ry] + immsext, m->regs[rx]);
      assert(err == 0);
      break;
    case OPCODE_SHR:
      m->regs[rx] = m->regs[ry] >> m->regs[rz];
      break;
    case OPCODE_SHL:
      m->regs[rx] = m->regs[ry] << m->regs[rz];
      break;
    case OPCODE_BEQ:
      if (m->regs[rx] == m->regs[ry])
        m->regs[REG_PC] += immsext;
      break;
    case OPCODE_BLT:
      if (m->regs[rx] < m->regs[ry])
        m->regs[REG_PC] += immsext;
      break;
    case OPCODE_ADDIU:
      m->regs[rx] = m->regs[ry] + immsext;
      break;
    case OPCODE_LUI:
      m->regs[rx] = imm << 16;
      break;

    case OPCODE_ORI:
      m->regs[rx] = m->regs[ry] | imm;
      break;
    case OPCODE_LB:
      assert(0 && "lb todo");
      break;
    case OPCODE_SB:
      assert(0 && "sb todo");
      break;
    case OPCODE_BNE:
      if (m->regs[rx] != m->regs[ry])
        m->regs[REG_PC] += immsext;
      break;
    case OPCODE_JR:
      m->regs[REG_PC] = m->regs[rx];
      break;
    case OPCODE_JALR:
      m->regs[REG_LR] = m->regs[REG_PC];
      m->regs[REG_PC] = m->regs[ry];
      break;
    case OPCODE_JSUB:
      m->regs[REG_LR] = m->regs[REG_PC];
      m->regs[REG_PC] += imm26sext;
      break;
    default:
      assert(0 && "bad opcode!");
      break;
  }

  m->cycno++;
  unsigned timer_period = 0;
  assert(mem_read(m, TIMER_PERIOD, &timer_period) == 0);
  if (timer_period != 0 && m->cycno % timer_period == 0) {
    m->regs[REG_FR] |= FRBIT_CLK;
    m->cycno = 0;
  }
}


void check_excep(machine_t* m)
{
  // check for ERET
  if (m->regs[REG_FR] & FRBIT_ERET) {
#ifdef EXCEP_WATCH
    printf("@ [%08X] eret\n", m->regs[REG_PC]);
#endif
    m->regs[REG_FR] &= ~FRBIT_ERET;
    m->regs[REG_FR] |= FRBIT_GIE; // enable interrupts
    assert(mem_read(m, m->regs[REG_SP], &(m->regs[REG_PC])) == 0);
    m->regs[REG_SP] += 4; // pop PC
    return;
  }

  if (!(m->regs[REG_FR] & FRBIT_GIE))
    return;

  unsigned excep = 0;
  unsigned regfr = m->regs[REG_FR];

  if ((regfr & FRBIT_CLKEN) && (regfr & FRBIT_CLK)) {
#ifdef EXCEP_WATCH
    printf("@ [%08X] clk\n", m->regs[REG_PC]);
#endif
    excep = 1;
  }
  if ((regfr & FRBIT_UART1_OUTEN) && (regfr & FRBIT_UART1_OUT)) {
#ifdef EXCEP_WATCH
    printf("@ [%08X] uartout\n", m->regs[REG_PC]);
#endif
    excep = 1;
  }
  if ((regfr & FRBIT_UART1_INEN) && (regfr & FRBIT_UART1_IN)) {
#ifdef EXCEP_WATCH
    printf("@ [%08X] uartin\n", m->regs[REG_PC]);
#endif
    excep = 1;
  }

  if (!excep)
    return;

  m->regs[REG_SP] -= 4;
  assert(mem_write(m, m->regs[REG_SP], m->regs[REG_PC]) == 0); // push PC
  m->regs[REG_FR] &= ~FRBIT_GIE;  // disable interrupts
  assert(mem_read(m, IRQ_HANDLER, &(m->regs[REG_PC])) == 0); // goto irq_handler
}


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

