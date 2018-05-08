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


class FA<bits<8> op, dag outs, dag ins, string asmstr,
         list<dag> pattern>:
      Cpu0Inst<outs, ins, asmstr, pattern, Cpu0IEF_A>
{
  bits<8>  opcode;
  bits<4>  ra;
  bits<4>  rb;
  bits<4>  rc;
  bits<12> shamt;

  let Inst{31-24} = opcode;
  let Inst{23-20} = ra;
  let Inst{19-16} = rb;
  let Inst{15-12} = rc;
  let Inst{11-0}  = shamt;
}


class FL<bits<8> op, dag outs, dag ins, string asmstr, list<dag> pattern>: 
  Cpu0Inst<outs, ins, asmstr, pattern, Cpu0IEF_B>
{
  bits<8> opcode;
  bits<4>  ra;
  bits<4>  rb;
  bits<16> imm16;

  let Inst{31-24} = opcode;
  let Inst{23-20} = ra;
  let Inst{19-16} = rb;
  let Inst{15-0}  = imm16;
}

