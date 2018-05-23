//===-- Cpu0CallingConv.td - Calling Conventions for Cpu0 --*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
// This describes the calling conventions for Cpu0 architecture.
//===----------------------------------------------------------------------===//

// i32 are returned in registers V0, V1, A0, A1
def RetCC_Cpu0EABI : CallingConv<[
  CCIfType<[i32], CCAssignToReg<[V0, V1, A0, A1]>>
]>;


def RetCC_Cpu0 : CallingConv<[
  CCDelegateTo<RetCC_Cpu0EABI>
]>;


def CSR_O32 : CalleeSavedRegs<(add LR, FP, S0, S1)>;

