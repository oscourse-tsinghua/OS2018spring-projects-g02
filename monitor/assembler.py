import datamanager as dm
nowcodeaddr = 0x00000000
nowdataaddr = 0x00020000
nowmode = "none"

def initInstructions():
    dm.instructions["lui"] = ["Reg", "Imm"]
    dm.instructions["addiu"] = ["Reg", "Reg", "Imm"]
    dm.instructions["or"] = ["Reg", "Reg", "Reg"]
    dm.instructions["ori"] = ["Reg", "Reg", "Imm"]
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
    dm.registers = ["a0", "a1", "v0", "v1", "ra", "zr", "wr", "pc", "sp", "fr", "fp", "lr",\
                "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7", "t8", "t9", "s0", "s1"]

def panic(lnum, line, inst):
    print "assembly code error in line ", lnum
    print "\"" + line + "\""
    print inst
    exit(0)

def checkReg(s, lnum, relocate):
    if s[0] == '$' and s[1:].lower() in dm.registers:
        return True
    return s + " is not a register (maybe lose $)."

def checkImm(s, lnum, relocate):
    try:
        int(s, 0)
        return True
    except ValueError:
        if dm.labels.has_key(s):
            return True
        elif s[0] == "%":
            st = s.split("(")
            if st[0][1:] != "hi" and st[0][1:] != "lo":
                return st[0] + "in unknown."
            lb = st[1][:-1]
            if dm.labels.has_key(lb):
                return True
            else:
                if relocate:
                    return True
                else:
                    return lb + "is an unknown label."
        return s + " is not a immediate number."

def checkBranch(s, lnum, relocate):
    if dm.labels.has_key(s):
        return True
    else:
        return s + "is not a label."

def checkAddr(s, lnum, relocate):
    st = s.split("(")
    st[1] = st[1][:-1]
    c1 = checkImm(st[0], lnum, relocate)
    c2 = checkReg(st[1], lnum, relocate)
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
        line = line.replace(',', ' ')
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
        elif sl[0] == ".section": # section control, not used here
            pass
        elif sl[0] == ".data": # 
            nowmode = "data"
        elif sl[0] == ".text": # 
            nowmode = "code"
        elif sl[0] == ".globl": # global control, not used for now
            dm.global_labels += [sl[1]]
        elif sl[0] == ".asciz": # const string
            if nowmode != "data":
                panic(lnum, line, "asciz not in data section")
            s = " ".join(sl[1:])
            for item in s[1:-1]:
                dm.data[nowdataaddr] = ord(item)
                nowdataaddr += 1
            dm.data[nowdataaddr] = 0
            nowdataaddr += 1
        elif sl[0] == ".type": # size for label
            dm.label_type[sl[1]] = sl[2][1:]
        elif sl[0] == ".size":
            dm.label_size[sl[1]] = sl[2]
        elif sl[0] == ".previous":
            pass #TODO I don't understand this for now
        elif sl[0] == ".file":
            dm.filename = sl[1][1:-1]
        elif sl[0] == ".frame":
            pass
        elif sl[0] == ".mask":
            pass
        elif sl[0] == ".end": # .ent and .end are used for debugger
            pass
        elif sl[0] == ".ent":
            pass
        elif sl[0] == ".ident": # ignore compiler info
            pass
        elif sl[0] == ".p2align":
            t = (1 << int(sl[1])) - 1
            if nowmode == "data":
                if (nowdataaddr & t) != 0:
                    nowdataaddr |= t
                    nowdataaddr += 1
            elif nowmode == "code":
                if (nowcodeaddr & t) != 0:
                    nowcodeaddr |= t
                    nowcodeaddr += 1
            else:
                panic(lnum, line, "align not in any section")
        elif sl[0][0] == ".": # control sequence, but not implemented here
            panic(lnum, line, "undefined control sequence")
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
                sl[pos] = sl[pos].lower()
                f = checkAddr
            msg = f(sl[pos], lnum, False)
            if msg != True:
                panic(lnum, line, "Usage for "+sl[0]+" incorrect: " + msg)
            pos += 1
        addr += 4
    print "Program Executable"

def checkForRelocate():
    addr = 0x10000
    while addr < nowcodeaddr:
        sl = dm.code[addr]
        lnum, line = dm.codeinfo[addr]
        form = dm.instructions[sl[0]]
        if len(sl) != len(form) + 1:
            panic(lnum, line, "Usage for " + sl[0] + " incorrect")
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
                sl[pos] = sl[pos].lower()
                f = checkAddr
            msg = f(sl[pos], lnum, True)
            if msg != True:
                panic(lnum, line, "Usage for " + sl[0] + " incorrect: " + msg)
            pos += 1
        addr += 4
    print "Programe Relocatable"

