//===-- Cpu0Other.td - Describe the Cpu0 Target Machine ----*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

// Used for bc -> .s/.o

// Target-independent interfaces
include "llvm/Target/Target.td"


// Target-dependent interfaces
include "Cpu0RegisterInfo.td"
def GPROut : RegisterClass<"Cpu0", [i32], 32, (add (sub CPURegs, SW))>;
include "Cpu0.td"

