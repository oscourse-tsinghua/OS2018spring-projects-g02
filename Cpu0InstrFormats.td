//===-- Cpu0InstrFormats.td - Cpu0 Instruction Formats -----*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//


// Each Cpu0InstrEncFormat instance represent an instruction encoding
//  format for Cpu0.
class Cpu0InstrEncFormat<bits<4> val> {
  bits<4> Value = val;
}


def Cpu0IEF_Pseudo: Cpu0InstrEncFormat<0>;
def Cpu0IEF_A: Cpu0InstrEncFormat<1>;
def Cpu0IEF_B: Cpu0InstrEncFormat<2>;


class Cpu0Inst<dag outs, dag ins, string asmstr,
    list<dag> pattern, Cpu0InstrEncFormat IEF>: Instruction
{
  let Namespace = "Cpu0";
  let DecoderNamespace = "Cpu0";
  let Size = 4;

  let OutOperandList = outs;
  let InOperandList  = ins;
  let AsmString   = asmstr;
  let Pattern     = pattern;

  field bits<32> Inst;

  // Used to identify the instruction format
  let TSFlags{3-0}   = IEF.Value;
}


class Cpu0Instr_Pseudo<dag outs, dag ins,string asmstr, list<dag> pattern>:
      Cpu0Inst<outs, ins, asmstr, pattern, Cpu0IEF_Pseudo>
{
  let isCodeGenOnly = 1;
  let isPseudo = 1;
}


class Cpu0Instr_PseudoSE<dag outs, dag ins, list<dag> pattern>:
  Cpu0Instr_Pseudo<outs, ins, "", pattern> {
}


// FA
//  syntax: op rx ry rz
//  semantics: rx = ry op rz
//  encoding:
//     6      5     5     5     11
//   opcode   rx    ry    rz    reserved (must be zero)

class FA<bits<6> opcode, dag outs, dag ins, string asmstr,
         list<dag> pattern>:
      Cpu0Inst<outs, ins, asmstr, pattern, Cpu0IEF_A>
{
  bits<5>  ra;
  bits<5>  rb;
  bits<5>  rc;
  bits<11> reserved = 0;

  let Inst{31-26} = opcode;
  let Inst{25-21} = ra;
  let Inst{20-16} = rb;
  let Inst{15-11} = rc;
  let Inst{10-0} = reserved;
}


// FL
//  syntax: op rx ry imm16
//  semantics: rx = ry op imm16
//  encoding:
//     6      5     5     16
//   opcode   rx    ry    imm16

class FL<bits<6> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>: 
  Cpu0Inst<outs, ins, asmstr, pattern, Cpu0IEF_B>
{
  bits<5>  ra;
  bits<5>  rb;
  bits<16> imm16;

  let Inst{31-26} = opcode;
  let Inst{25-21} = ra;
  let Inst{20-16} = rb;
  let Inst{15-0} = imm16;
}

