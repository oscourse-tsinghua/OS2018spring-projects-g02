#include "machine.h"

#include <string.h>
#include <assert.h>
#include <stdio.h>


uint32_t excep = 0;

void machine_init(machine_t* m)
{
  memset(m, 0, sizeof(m));
  m->regs[REG_SW] = 0x200; // TODO: SW
  m->regs[REG_WR] = 4;
  m->regs[REG_ZR] = 0;

  // dirty hack
  m->regs[REG_SP] = 0xFFF00000 + 0x10000 - 4;
}

#define decode_opcode(i) ((i>>26) & 0x3F)
#define decode_rx(i) ((i>>21) & 0x1F)
#define decode_ry(i) ((i>>16) & 0x1F)
#define decode_rz(i) ((i>>11) & 0x1F)
#define decode_imm16(i) (i & 0xFFFF)
#define decode_imm16sext(i) ((int) ((short) (i & 0xFFFF)))


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


void exec_inst(machine_t* m, uint32_t inst)
{
  printf("* %08X\n", inst);
  m->regs[REG_PC] += sizeof(uint32_t);
  uint32_t opcode = decode_opcode(inst);
  uint32_t rx = decode_rx(inst);
  uint32_t ry = decode_ry(inst);
  uint32_t rz = decode_rz(inst);
  uint32_t imm = decode_imm16(inst);
  uint32_t immsext = decode_imm16sext(inst);

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
      printf("JR: %d\n", rx);
      m->regs[REG_PC] = m->regs[rx];
      break;
    case OPCODE_JALR:
      printf("JALR: %d\n", rx);
      m->regs[REG_LR] = m->regs[REG_PC];
      m->regs[REG_PC] = m->regs[rx];
      break;
    default:
      assert(0 && "bad opcode!");
      break;
  }
}

