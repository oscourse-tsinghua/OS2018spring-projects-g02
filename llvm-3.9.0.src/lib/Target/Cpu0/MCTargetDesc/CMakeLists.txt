# MCTargetDesc/CMakeLists.txt
add_llvm_library(LLVMCpu0Desc
  Cpu0ABIInfo.cpp
  Cpu0MCAsmInfo.cpp
  Cpu0AsmBackend.cpp
  Cpu0MCCodeEmitter.cpp
  Cpu0MCExpr.cpp
  Cpu0ELFObjectWriter.cpp
  Cpu0TargetStreamer.cpp
  Cpu0MCTargetDesc.cpp
  )

