"""
增加指令: 比如增加 add
那么实现一个函数, 输入是 str (指令, 如 "add r1 PC PC")
输出是指令的编码 (8位16进制)
"""
def reg2rn(regexpr):
    if regexpr == "PC":
        return 0;
    elif regexpr == "SP":
        return 1;
    elif regexpr == "FP":
        return 2;
    elif regexpr == "ZR":
        return 3;
    elif regexpr == "FR":
        return 4;
    elif regexpr == "WR":
        return 5;
    else:
        assert(regexpr[0].lower() == 'r')
        n = int(regexpr[1:])
        assert(n > 0)
        assert(n <= 10)
        return n+5

def general_xyz(opcode, rx, ry, rz):
    t = lambda x, n: bin(x)[2:].rjust(n, '0')
    binrep = t(opcode, 5) + t(rx, 9) + t(ry, 9) + t(rz, 9)
    return hex(int(binrep,2))[2:].rjust(8, '0')

def _add(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    ry = reg2rn(toks[1])
    rz = reg2rn(toks[2])
    return general_xyz(0, rx, ry, rz)

def _sub(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    ry = reg2rn(toks[1])
    rz = reg2rn(toks[2])
    return general_xyz(1, rx, ry, rz)
    
def _and(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    ry = reg2rn(toks[1])
    rz = reg2rn(toks[2])
    return general_xyz(4, rx, ry, rz)
   
def _or(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    ry = reg2rn(toks[1])
    rz = reg2rn(toks[2])
    return general_xyz(5, rx, ry, rz)
    
def _not(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    ry = reg2rn(toks[1])
    rz = reg2rn("PC")
    return general_xyz(6, rx, ry, rz)
    
def _shr(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    ry = reg2rn(toks[1])
    rz = reg2rn("PC")
    return general_xyz(9, rx, ry, rz)

def _shl(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    ry = reg2rn(toks[1])
    rz = reg2rn("PC")
    return general_xyz(10, rx, ry, rz)

    
with open("inst.l2", "r") as fin, open("inst.hex", "w") as fout:
    for l in fin:
        if l.strip()[0] == ';':
            continue;
        typ = l.strip().split()[0]
        stmt = "_" + typ + "(l.strip())"
        print(eval(stmt), file=fout)

