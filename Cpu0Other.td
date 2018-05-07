//===-- Cpu0Other.td - Describe the Cpu0 Target Machine ----*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//


// Target-independent interfaces
include "llvm/Target/Target.td"


// Target-dependent interfaces
include "Cpu0RegisterInfo.td"
include "Cpu0.td"

