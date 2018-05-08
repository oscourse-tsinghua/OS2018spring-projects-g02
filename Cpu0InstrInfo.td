//===- Cpu0InstrInfo.td - Target Description for Cpu0 Target -*- tablegen -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//



// SDNode related information
def SDT_Cpu0Ret          : SDTypeProfile<0, 1, [SDTCisInt<0>]>;
def SDT_Cpu0JmpLink      : SDTypeProfile<0, 1, [SDTCisVT<0, iPTR>]>;


def SDT_Cpu0CallSeqStart : SDCallSeqStart<[SDTCisVT<0, i32>]>;
def SDT_Cpu0CallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i32>, SDTCisVT<1, i32>]>;


def Cpu0JmpLink : SDNode<"Cpu0ISD::JmpLink",SDT_Cpu0JmpLink,
                         [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue,
                          SDNPVariadic]>;


def Cpu0TailCall : SDNode<"Cpu0ISD::TailCall", SDT_Cpu0JmpLink,
                          [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

// Hi and Lo nodes are used to handle global addresses. Used on
// Cpu0ISelLowering to lower stuff like GlobalAddress, ExternalSymbol
// static model. (nothing to do with Cpu0 Registers Hi and Lo)
def Cpu0Hi    : SDNode<"Cpu0ISD::Hi", SDTIntUnaryOp>;
def Cpu0Lo    : SDNode<"Cpu0ISD::Lo", SDTIntUnaryOp>;
def Cpu0GPRel : SDNode<"Cpu0ISD::GPRel", SDTIntUnaryOp>;


def Cpu0Ret : SDNode<"Cpu0ISD::Ret", SDTNone,
                     [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;


// These are target-independent nodes, but have target-specific formats.
def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_Cpu0CallSeqStart,
                           [SDNPHasChain, SDNPOutGlue]>;
def callseq_end   : SDNode<"ISD::CALLSEQ_END", SDT_Cpu0CallSeqEnd,
                           [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;


def Cpu0Wrapper    : SDNode<"Cpu0ISD::Wrapper", SDTIntBinOp>;


def RelocPIC    :     Predicate<"TM.getRelocationModel() == Reloc::PIC_">;


class IsTailCall {
  bit isCall = 1;
  bit isTerminator = 1;
  bit isReturn = 1;
  bit isBarrier = 1;
  bit hasExtraSrcRegAllocReq = 1;
  bit isCodeGenOnly = 1;
}

// ****************************************************************************
include "Cpu0InstrFormats.td"

// ****************************************************************************
// Cpu0 Operand, Complex Patterns and Transformations Definitions.
// Instruction operand types

// BEQ, BNE
def brtarget16    : Operand<OtherVT> {
  let EncoderMethod = "getBranch16TargetOpValue";
  let OperandType = "OPERAND_PCREL";
  let DecoderMethod = "DecodeBranch16Target";
}

// JMP
def jmptarget    : Operand<OtherVT> {
  let EncoderMethod = "getJumpTargetOpValue";
  let OperandType = "OPERAND_PCREL";
}

def calltarget  : Operand<iPTR> {
  let EncoderMethod = "getJumpTargetOpValue";
}

// Signed Operand
def simm16      : Operand<i32> {
  let DecoderMethod= "DecodeSimm16";
}

def shamt       : Operand<i32>;

// Unsigned Operand
def uimm16      : Operand<i32> {
  let PrintMethod = "printUnsignedImm";
}

// Address operand
def mem : Operand<iPTR> {
  let PrintMethod = "printMemOperand";
  let MIOperandInfo = (ops CPURegs, simm16);
  let EncoderMethod = "getMemEncoding";
}

def mem_ea : Operand<iPTR> {
  let PrintMethod = "printMemOperandEA";
  let MIOperandInfo = (ops CPURegs, simm16);
  let EncoderMethod = "getMemEncoding";
}

// Transformation Function - get the lower 16 bits.
def LO16 : SDNodeXForm<imm, [{
  return getImm(N, N->getZExtValue() & 0xffff);
}]>;

// Transformation Function - get the higher 16 bits.
def HI16 : SDNodeXForm<imm, [{
  return getImm(N, (N->getZExtValue() >> 16) & 0xffff);
}]>;

// Node immediate fits as 16-bit sign extended on target immediate.
// e.g. addi, andi
def immSExt16  : PatLeaf<(imm), [{ return isInt<16>(N->getSExtValue()); }]>;

// Node immediate fits as 16-bit zero extended on target immediate.
// The LO16 param means that only the lower 16 bits of the node
// immediate are caught.
// e.g. addiu, sltiu
def immZExt16  : PatLeaf<(imm), [{
  if (N->getValueType(0) == MVT::i32)
    return (uint32_t)N->getZExtValue() == (unsigned short)N->getZExtValue();
  else
    return (uint64_t)N->getZExtValue() == (unsigned short)N->getZExtValue();
}], LO16>;

// Immediate can be loaded with LUi (32-bit int with lower 16-bit cleared).
def immLow16Zero : PatLeaf<(imm), [{
  int64_t Val = N->getSExtValue();
  return isInt<32>(Val) && !(Val & 0xffff);
}]>;

// shamt field must fit in 5 bits.
def immZExt5 : ImmLeaf<i32, [{return Imm == (Imm & 0x1f);}]>;

// Cpu0 Address Mode! SDNode frameindex could possibily be a match
// since load and store instructions from stack used it.
def addr :
  ComplexPattern<iPTR, 2, "SelectAddr", [frameindex], [SDNPWantParent]>;

// Pattern fragment for load/store

class AlignedLoad<PatFrag Node>:
  PatFrag<(ops node:$ptr), (Node node:$ptr), [{
  LoadSDNode *LD = cast<LoadSDNode>(N);
  return LD->getMemoryVT().getSizeInBits()/8 <= LD->getAlignment();
}]>;

class AlignedStore<PatFrag Node>:
  PatFrag<(ops node:$val, node:$ptr), (Node node:$val, node:$ptr), [{
  StoreSDNode *SD = cast<StoreSDNode>(N);
  return SD->getMemoryVT().getSizeInBits()/8 <= SD->getAlignment();
}]>;

// Load/Store PatFrags.
def load_a          : AlignedLoad<load>;
def store_a         : AlignedStore<store>;


//****************************************************************************
// Instructions specific format
// op $ra, $rb, $rc,  where $ra = (op $rb $rc)
class ArithLogicInstr_RRR<bits<8> op, string instr_asm, SDNode OpNode,
                  RegisterClass RC, bit isComm = 0>:
  FA<op, (outs GPROut:$ra), (ins RC:$rb, RC:$rc),
     !strconcat(instr_asm, "\t$ra, $rb, $rc"),
     [(set GPROut:$ra, (OpNode RC:$rb, RC:$rc))]> {
  let shamt = 0;
  let isCommutable = isComm;	// e.g. add rb rc =  add rc rb
  let isReMaterializable = 1;
}

// op $ra, $rb, $imm
class ArithLogic_RRI<bits<8> op, string instr_asm, SDNode OpNode,
                  Operand Od, PatLeaf imm_type, RegisterClass RC>:
  FL<op, (outs GPROut:$ra), (ins RC:$rb, Od:$imm16),
     !strconcat(instr_asm, "\t$ra, $rb, $imm16"),
     [(set GPROut:$ra, (OpNode RC:$rb, imm_type:$imm16))]> {
  let isReMaterializable = 1;
}

// load upper immediate
class LoadUpper<bits<8> op, string instr_asm, RegisterClass RC, Operand Imm>:
  FL<op, (outs RC:$ra), (ins Imm:$imm16),
     !strconcat(instr_asm, "\t$ra, $imm16"), []>
{
  let rb = 0;
  let isReMaterializable = 1;
}

class FMem<bits<8> op, dag outs, dag ins, string asmstr,
    list<dag> pattern>:
  FL<op, outs, ins, asmstr, pattern>
{
  bits<20> addr;
  let Inst{19-16} = addr{19-16};
  let Inst{15-0}  = addr{15-0};
  let DecoderMethod = "DecodeMem";
}

let canFoldAsLoad = 1 in
class LoadM<bits<8> op, string instr_asm, PatFrag OpNode,
    RegisterClass RC, Operand MemOpnd>:
  FMem<op, (outs RC:$ra), (ins MemOpnd:$addr),
     !strconcat(instr_asm, "\t$ra, $addr"),
     [(set RC:$ra, (OpNode addr:$addr))]>;

class StoreM<bits<8> op, string instr_asm, PatFrag OpNode,
    RegisterClass RC, Operand MemOpnd>:
  FMem<op, (outs), (ins RC:$ra, MemOpnd:$addr),
     !strconcat(instr_asm, "\t$ra, $addr"),
     [(OpNode RC:$ra, addr:$addr)]>;

class CBranch16<bits<8> op, string instr_asm, PatFrag cond_op,
    RegisterClass RC>:
  FL<op, (outs), (ins RC:$ra, RC:$rb, brtarget16:$imm16),
             !strconcat(instr_asm, "\t$ra, $rb, $imm16"),
             [(brcond (i32 (cond_op RC:$ra, RC:$rb)), bb:$imm16)]> {
  let isBranch = 1;
  let isTerminator = 1;
  let Defs = [AT];
}

class JumpFR<bits<8> op, string instr_asm, RegisterClass RC>:
  FL<op, (outs), (ins RC:$ra),
     !strconcat(instr_asm, "\t$ra"), [(brind RC:$ra)]> {
  let isBranch = 1;
  let isBarrier = 1;
  let isTerminator = 1;
  let isIndirectBranch = 1;
  let rb = 0;
  let imm16 = 0;
}

class RetBase<RegisterClass RC>: JumpFR<0x3c, "ret", RC> {
  let isReturn = 1;
  let isCodeGenOnly = 1;
  let hasCtrlDep = 1;
  let hasExtraSrcRegAllocReq = 1;
}

class JumpLinkReg<bits<8> op, string instr_asm,
                  RegisterClass RC>:
  FA<op, (outs), (ins RC:$rb, variable_ops),
     !strconcat(instr_asm, "\t$rb"), [(Cpu0JmpLink RC:$rb)]> {
  let rc = 0;
  let ra = 14;
  let shamt = 0;
  let isCall = 1;
}

let isCall = 1, isTerminator = 1, isReturn = 1, isBarrier = 1,
    hasDelaySlot = 1, hasExtraSrcRegAllocReq = 1, Defs = [AT] in {
  class TailCall<Instruction JumpInst>:
    Cpu0Instr_PseudoSE<(outs), (ins calltarget:$target), []>,
    PseudoInstExpansion<(JumpInst jmptarget:$target)>;

  class TailCallReg<RegisterClass RO, Instruction JRInst,
                    RegisterClass ResRO = RO>:
    Cpu0Instr_PseudoSE<(outs), (ins RO:$rs), [(Cpu0TailCall RO:$rs)]>,
    PseudoInstExpansion<(JRInst ResRO:$rs)>;
}

class EffectiveAddress<string instr_asm, RegisterClass RC, Operand Mem>:
  FMem<0x09, (outs RC:$ra), (ins Mem:$addr),
     instr_asm, [(set RC:$ra, addr:$addr)]>;

// ****************************************************************************
// Pseudo instructions

// As stack alignment is always done with addiu, we need a 16-bit immediate
let Defs = [SP], Uses = [SP] in {
def ADJCALLSTACKDOWN : Cpu0Instr_Pseudo<(outs), (ins uimm16:$amt),
                                  "!ADJCALLSTACKDOWN $amt",
                                  [(callseq_start timm:$amt)]>;
def ADJCALLSTACKUP   : Cpu0Instr_Pseudo<(outs), (ins uimm16:$amt1, uimm16:$amt2),
                                  "!ADJCALLSTACKUP $amt1",
                                  [(callseq_end timm:$amt1, timm:$amt2)]>;
}

//@def CPRESTORE {
// When handling PIC code the assembler needs .cpload and .cprestore
// directives. If the real instructions corresponding these directives
// are used, we have the same behavior, but get also a bunch of warnings
// from the assembler.
let hasSideEffects = 0 in
def CPRESTORE : Cpu0Instr_Pseudo<(outs), (ins i32imm:$loc, CPURegs:$gp),
                           ".cprestore\t$loc", []>;

// ****************************************************************************
// Instruction definition

def ADDiu   : ArithLogic_RRI<0xaa, "addi", add, simm16, immSExt16, CPURegs>;
def ORi     : ArithLogic_RRI<0xf0, "ori", or, uimm16, immZExt16, CPURegs>;
def LUi     : LoadUpper<0xf1, "lui", GPROut, uimm16>;

def ADDu    : ArithLogicInstr_RRR<0x11, "add", add, CPURegs, 1>;
def SUBu    : ArithLogicInstr_RRR<0x12, "sub", sub, CPURegs>;
def MULu    : ArithLogicInstr_RRR<0x13, "mul", mul, CPURegs>;

def AND     : ArithLogicInstr_RRR<0x18, "and", and, CPURegs, 1>;
def OR      : ArithLogicInstr_RRR<0x19, "or", or, CPURegs, 1>;
def XOR     : ArithLogicInstr_RRR<0x1a, "xor", xor, CPURegs, 1>;
def SHLV    : ArithLogicInstr_RRR<0x1b, "shl", shl, CPURegs>;
def SHRV    : ArithLogicInstr_RRR<0x1c, "shr", srl, CPURegs>;

def LD     : LoadM<0x01,  "loa",  load_a, GPROut, mem>;
def ST     : StoreM<0x02, "sto",  store_a, CPURegs, mem>;
def LB     : LoadM<0x03, "lb", sextloadi8, GPROut, mem>;
def SB     : StoreM<0x04, "sb", truncstorei8, CPURegs, mem>;

def BEQ     : CBranch16<0x31, "beq", seteq, GPROut>;
def BNE     : CBranch16<0x32, "bne", setne, GPROut>; // TODO: delete
def BLT     : CBranch16<0x33, "blt", setult, GPROut>;

def JR      : JumpFR<0x34, "jr", GPROut>;
def JALR    : JumpLinkReg<0x35, "jalr", GPROut>;

let isReturn=1, isTerminator=1, hasDelaySlot=0, isBarrier=1, hasCtrlDep=1 in
  def RetLR : Cpu0Instr_Pseudo<(outs), (ins), "", [(Cpu0Ret)]>;

def RET     : RetBase<GPROut>;

def TAILCALL_R : TailCallReg<GPROut, JR>;

// FrameIndexes are legalized when they are operands from load/store
// instructions. The same not happens for stack address copies, so an
// add op with mem ComplexPattern is used and the stack address copy
// can be matched. It's similar to Sparc LEA_ADDRi
def LEA_ADDiu : EffectiveAddress<"addiu\t$ra, $addr", CPURegs, mem_ea> {
  let isCodeGenOnly = 1;
}


// ****************************************************************************
// instruction aliases
class Cpu0InstAlias<string Asm, dag Result, bit Emit = 0b1>:
  InstAlias<Asm, Result, Emit>;
def : Cpu0InstAlias<"move $dst, $src",
                    (ADDu GPROut:$dst, GPROut:$src,ZR), 1>;


// ****************************************************************************
//  Arbitrary patterns that map to one or more instructions

// Small immediates
def : Pat<(i32 immSExt16:$in),
          (ADDiu ZR, imm:$in)>;

def : Pat<(i32 immZExt16:$in),
          (ORi ZR, imm:$in)>;
def : Pat<(i32 immLow16Zero:$in),
          (LUi (HI16 imm:$in))>;

// Arbitrary immediates
def : Pat<(i32 imm:$imm),
          (ORi (LUi (HI16 imm:$imm)), (LO16 imm:$imm))>;

def : Pat<(Cpu0JmpLink (i32 tglobaladdr:$dst)),
          (JALR tglobaladdr:$dst)>;
def : Pat<(Cpu0JmpLink (i32 texternalsym:$dst)),
          (JALR texternalsym:$dst)>;

def : Pat<(Cpu0TailCall (iPTR tglobaladdr:$dst)),
              (TAILCALL_R tglobaladdr:$dst)>;
def : Pat<(Cpu0TailCall (iPTR texternalsym:$dst)),
              (TAILCALL_R texternalsym:$dst)>;

// hi/lo relocs
def : Pat<(Cpu0Hi tglobaladdr:$in), (LUi tglobaladdr:$in)>;
def : Pat<(Cpu0Hi tblockaddress:$in), (LUi tblockaddress:$in)>;
def : Pat<(Cpu0Hi tjumptable:$in), (LUi tjumptable:$in)>;

def : Pat<(Cpu0Lo tglobaladdr:$in), (ORi ZR, tglobaladdr:$in)>;
def : Pat<(Cpu0Lo tblockaddress:$in), (ORi ZR, tblockaddress:$in)>;
def : Pat<(Cpu0Lo tjumptable:$in), (ORi ZR, tjumptable:$in)>;

def : Pat<(add CPURegs:$hi, (Cpu0Lo tglobaladdr:$lo)),
          (ORi CPURegs:$hi, tglobaladdr:$lo)>;
def : Pat<(add CPURegs:$hi, (Cpu0Lo tblockaddress:$lo)),
              (ORi CPURegs:$hi, tblockaddress:$lo)>;
def : Pat<(add CPURegs:$hi, (Cpu0Lo tjumptable:$lo)),
              (ORi CPURegs:$hi, tjumptable:$lo)>;

// gp_rel relocs
def : Pat<(add CPURegs:$gp, (Cpu0GPRel tglobaladdr:$in)),
          (ORi CPURegs:$gp, tglobaladdr:$in)>;

class WrapperPat<SDNode node, Instruction ORiOp, RegisterClass RC>:
      Pat<(Cpu0Wrapper RC:$gp, node:$in),
              (ORiOp RC:$gp, node:$in)>;

def : WrapperPat<tglobaladdr, ORi, GPROut>;
def : WrapperPat<tjumptable, ORi, GPROut>;

def : Pat<(not CPURegs:$in),
          (XOR CPURegs:$in, (ADDiu ZR, -1))>;

def : Pat<(zextloadi8 addr:$addr),
          (AND (LB addr:$addr), (ADDiu ZR, 0xFF))>;

// br imm     -> beq ZR ZR imm
def : Pat<(br bb:$dst),
              (BEQ ZR, ZR, bb:$dst)>;

// beq $r1 $zr imm
def : Pat<(brcond (i32 (seteq CPURegs:$lhs, 0)), bb:$dst),
              (BEQ CPURegs:$lhs, ZR, bb:$dst)>;

// bne $r1 0 imm
def : Pat<(brcond (i32 (setne CPURegs:$lhs, 0)), bb:$dst),
              (BNE CPURegs:$lhs, ZR, bb:$dst)>;

// beq $r1 $r2 imm
def : Pat<(brcond (i32 (setueq CPURegs:$lhs, CPURegs:$rhs)), bb:$dst),
              (BEQ CPURegs:$lhs, CPURegs:$rhs, bb:$dst)>;

// beq $r1 $r2 imm
def : Pat<(brcond (i32 (setune CPURegs:$lhs, CPURegs:$rhs)), bb:$dst),
              (BNE CPURegs:$lhs, CPURegs:$rhs, bb:$dst)>;

// blt $r1 $r2 imm
def : Pat<(brcond (i32 (setult CPURegs:$lhs, CPURegs:$rhs)), bb:$dst),
              (BLT $lhs, $rhs, $dst)>;

// ble $r1 $r2 imm        lhs <= rhs    -> lhs < rhs + 1
def : Pat<(brcond (i32 (setule CPURegs:$lhs, CPURegs:$rhs)), bb:$dst),
              (BLT $lhs, (ADDiu $rhs, 1), $dst)>;

// bgt $r1 $r2 imm == blt $r2 $r1 imm
def : Pat<(brcond (i32 (setugt CPURegs:$lhs, CPURegs:$rhs)), bb:$dst),
              (BLT $rhs, $lhs, $dst)>;

// bge $r1 $r2 imm == blt $r2 $r1+1 imm
def : Pat<(brcond (i32 (setuge CPURegs:$lhs, CPURegs:$rhs)), bb:$dst),
              (BLT $rhs, (ADDiu $lhs, 1), $dst)>;

