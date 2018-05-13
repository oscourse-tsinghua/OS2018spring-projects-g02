import datamanager as dm
import instruction_behavior

def startup():
    for item in dm.registers:
        dm.reg[item] = 0
    dm.reg["wr"] = 4
    dm.reg["fr"] = 0x200
    dm.reg["pc"] = dm.labels["START"]
    #prepare registers

def step():
    pc = dm.reg["pc"]
    sl = dm.code[pc]
    code = sl[0]+"_"
    print pc, sl
    getattr(instruction_behavior, code)(sl)


if __name__ == "__main__":
    dm.init()
    import assembler
    assembler.initInstructions()
    assembler.initRegisters()
    assembler.readAssembly("monitor.S")
    assembler.checkForExecute()
    startup()
    for i in range(5):
        step()
    print dm.reg
