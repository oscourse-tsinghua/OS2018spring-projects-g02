//===-- Cpu0AnalyzeImmediate.cpp - Analyze Immediates ---------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include "Cpu0AnalyzeImmediate.h"
#include "Cpu0.h"

#include "llvm/Support/MathExtras.h"

using namespace llvm;

Cpu0AnalyzeImmediate::Inst::Inst(unsigned O, unsigned I) : Opc(O), ImmOpnd(I) {}

const Cpu0AnalyzeImmediate::InstSeq
&Cpu0AnalyzeImmediate::Analyze(uint64_t Imm, unsigned Size,
                               bool LastInstrIsADDiu) {
  this->Size = Size;

  ADDiu = Cpu0::ADDiu;
  LUi = Cpu0::LUi;

  assert(Imm <= (((uint64_t)1)<<32) && "too large stack size!!");

//  InstSeqLs SeqLs;
//
//  // Get the list of instruction sequences.
//  if (LastInstrIsADDiu | !Imm)
//    GetInstSeqLsADDiu(Imm, Size, SeqLs);
//  else
//    GetInstSeqLs(Imm, Size, SeqLs);
//
//  // Set Insts to the shortest instruction sequence.
//  GetShortestSeq(SeqLs, Insts);

// My loader only uses AND ADDIU
//	LOAD(imm):
//		[hi, lo] = imm		# higher and lower 16 bits
//		IF lo & 0x8000		# becomes negative when signed-extended
//							#	lo ->	0xFFFF0000  + lo
//							#	FFFF 0000 + lo + (hi<<16) + 0001 0000
//							#		= lo + (hi<<16)   (modadd commutativity)
//			LUI		hi+1
//			ADDIU	lo
//		ELSE
//			IF hi == 0
//				ADDIU lo
//			else
//				LUI hi
//				ADDIU lo
//

  Insts.clear();

  unsigned lo = (Imm & 0xFFFF);
  unsigned hi = ((Imm>>16) & 0xFFFF);
  unsigned hiplus1 = ((hi+1) & 0xFFFF);
  if (lo & 0x8000) {
    Insts.push_back(Inst(LUi, hiplus1));
	Insts.push_back(Inst(ADDiu, lo));
  } else {
	  if (hi == 0) {
		  Insts.push_back(Inst(ADDiu, lo));
	  } else {
		  Insts.push_back(Inst(LUi, hi));
		  Insts.push_back(Inst(ADDiu, lo));
	  }
  }
  return Insts;
}

