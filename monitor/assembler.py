import datamanager as dm
nowcodeaddr = 0x00010000
nowdataaddr = 0x00020000
nowmode = "none"

def initInstructions():
    dm.instructions["lui"] = ["Reg", "Imm"]
    dm.instructions["addiu"] = ["Reg", "Reg", "Imm"]
    dm.instructions["or"] = ["Reg", "Reg", "Reg"]
    dm.instructions["and"] = ["Reg", "Reg", "Reg"]
    dm.instructions["add"] = ["Reg", "Reg", "Reg"]
    dm.instructions["xor"] = ["Reg", "Reg", "Reg"]
    dm.instructions["subu"] = ["Reg", "Reg", "Reg"]
    dm.instructions["addu"] = ["Reg", "Reg", "Reg"]
    dm.instructions["beq"] = ["Reg", "Reg", "Branch"]
    dm.instructions["jr"] = ["Reg"]
    dm.instructions["loa"] = ["Reg", "Addr"]
    dm.instructions["sto"] = ["Reg", "Addr"]
    dm.instructions["lb"] = ["Reg", "Addr"]

def initRegisters():
    dm.registers = ["a0", "a1", "v0", "v1", "ra", "zr", "wr", "pc", "sp", "fr",\
                "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7", "t8", "t9"]

def panic(lnum, line, inst):
    print "assembly code error in line ", lnum
    print "\"" + line + "\""
    print inst
    exit(0)

def checkReg(s, lnum):
    if s[0] == '$' and s[1:].lower() in dm.registers:
        return True
    return s + " is not a register (maybe lose $)."

def checkImm(s, lnum):
    try:
        int(s, 0)
        return True
    except ValueError:
        if dm.labels.has_key(s):
            return True
        return s + " is not a immediate number."

def checkBranch(s, lnum):
    if dm.labels.has_key(s):
        return True
    else:
        return s + "is not a label."

def checkAddr(s, lnum):
    st = s.split("(")
    st[1] = st[1][:-1]
    c1 = checkImm(st[0], lnum)
    c2 = checkReg(st[1], lnum)
    if c1 != True:
        return c1
    if c2 != True:
        return c2
    return True

def readAssembly(filename):
    global nowdataaddr, nowcodeaddr
    f = open(filename, 'r')
    for lnum, line in enumerate(f.readlines()):
        line = line.strip()
        for i, item in enumerate(line):
            if item == '#':
                line = line[:i]
                break
        sl = line.split()
        if len(sl) == 0: # empty line
            pass
        elif sl[0][-1] == ':': # label
            if nowmode == "data":
                dm.labels[sl[0][:-1]] = nowdataaddr
            elif nowmode == "code":
                dm.labels[sl[0][:-1]] = nowcodeaddr
            else:
                panic(lnum, line, "label is not in any section")
        elif sl[0] == ".set": # control sequence, not used here
            pass
        elif sl[0] == ".section":
            if sl[1] == ".data":
                nowmode = "data"
            elif sl[1] == ".text":
                nowmode = "code"
            else:
                panic(lnum, line, "section is not data or text")
        elif sl[0] == ".global": # global control, not used for now
            pass
        elif sl[0] == ".asciz": # const string
            if nowmode != "data":
                panic(lnum, line, "asciz not in data section")
            s = " ".join(sl[1:])
            for item in s[1:-1]:
                dm.data[nowdataaddr] = item
                nowdataaddr += 1
            dm.data[nowdataaddr] = 0
            nowdataaddr += 1
        else:
            if not dm.instructions.has_key(sl[0]):
                panic(lnum, line, "instruction not exist")
            dm.code[nowcodeaddr] = sl
            dm.codeinfo[nowcodeaddr] = (lnum, line)
            nowcodeaddr += 4
    print "Read Assembly file "+ filename +" success."

def checkForExecute():
    addr = 0x10000
    while addr < nowcodeaddr:
        sl = dm.code[addr]
        lnum, line = dm.codeinfo[addr]
        form = dm.instructions[sl[0]]
        if len(sl) != len(form) + 1:
            panic(lnum, line, "Usage for "+sl[0]+" incorrect")
        pos = 1
        for item in form:
            if item == "Reg":
                sl[pos] = sl[pos].lower()
                f = checkReg
            elif item == "Imm":
                f = checkImm
            elif item == "Branch":
                f = checkBranch
            elif item == "Addr":
                f = checkAddr
            msg = f(sl[pos], lnum)
            if msg != True:
                panic(lnum, line, "Usage for "+sl[0]+" incorrect: " + msg)
            pos += 1
        addr += 4
    print "Program Executable"

