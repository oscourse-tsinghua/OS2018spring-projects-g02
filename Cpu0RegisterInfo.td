//===-- Cpu0RegisterInfo.td - Cpu0 Register defs -----------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the CPU0 register file
//===----------------------------------------------------------------------===//

// We have banks of 16 registers each.
class Cpu0Reg<bits<16> Enc, string n> : Register<n> {
  let HWEncoding = Enc;
  let Namespace = "Cpu0";
}

// Cpu0 CPU Registers
class Cpu0GPRReg<bits<16> Enc, string n> : Cpu0Reg<Enc, n>;

// Co-processor 0 Registers
class Cpu0C0Reg<bits<16> Enc, string n> : Cpu0Reg<Enc, n>;

//===----------------------------------------------------------------------===//
//@Registers
//===----------------------------------------------------------------------===//
// The register string, such as "9" or "gp" will show on "llvm-objdump -d"
//@ All registers definition
let Namespace = "Cpu0" in {
  //@ General Purpose Registers
  // defined by Cpu0
  def PC: Cpu0GPRReg<0, "pc">, DwarfRegNum<[0]>;
  def SP: Cpu0GPRReg<1, "sp">, DwarfRegNum<[1]>;
  def FP: Cpu0GPRReg<2, "fp">, DwarfRegNum<[2]>;
  def ZR: Cpu0GPRReg<3, "zr">, DwarfRegNum<[3]>;
  def SW: Cpu0GPRReg<4, "fr">, DwarfRegNum<[4]>;
  def WR: Cpu0GPRReg<5, "wr">, DwarfRegNum<[5]>;

  // Mips-like assistance
  def AT: Cpu0GPRReg<6, "at">, DwarfRegNum<[6]>;
  def LR: Cpu0GPRReg<7, "lr">, DwarfRegNum<[7]>;
  def GP: Cpu0GPRReg<8, "gp">, DwarfRegNum<[8]>;

  // others... mips like
  def V0: Cpu0GPRReg<9, "v0">, DwarfRegNum<[9]>;
  def V1: Cpu0GPRReg<10, "v1">, DwarfRegNum<[10]>;

  def A0: Cpu0GPRReg<11, "a0">, DwarfRegNum<[11]>;
  def A1: Cpu0GPRReg<12, "a1">, DwarfRegNum<[12]>;

  def S0: Cpu0GPRReg<13, "s0">, DwarfRegNum<[13]>;
  def S1: Cpu0GPRReg<14, "s1">, DwarfRegNum<[14]>;

  def T0: Cpu0GPRReg<15, "t0">, DwarfRegNum<[15]>;
  def T1: Cpu0GPRReg<15, "t1">, DwarfRegNum<[16]>;
  def T9: Cpu0GPRReg<15, "t9">, DwarfRegNum<[17]>;
}

//===----------------------------------------------------------------------===//
//@Register Classes
//===----------------------------------------------------------------------===//

def CPURegs : RegisterClass<"Cpu0", [i32], 32, (add
  // Reserved
  ZR, AT, PC, WR,
  // Return Values and Arguments
  V0, V1, A0, A1, 
  // Not preserved across procedure calls
  T0, T1, T9,
  // Callee save
  S0, S1,
  // Reserved
  GP, FP, 
  SP, LR, SW)>;

//@Status Registers class
def SR     : RegisterClass<"Cpu0", [i32], 32, (add SW)>;

