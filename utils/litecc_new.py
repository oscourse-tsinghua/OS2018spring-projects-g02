# encoding: utf-8
from __future__ import print_function
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
        return n+5

def general_xyz(opcode, rx, ry, rz):
    t = lambda x, n: bin(x)[2:].rjust(n, '0')
    binrep = t(opcode, 6) + t(rx, 5) + t(ry, 5) + t(rz, 5) + t(0, 11)
    return hex(int(binrep,2))[2:].rjust(8, '0')

def general_ll(rx, liimm):
    t = lambda x, n: bin(x)[2:].rjust(n, '0')
    binrep = t(13, 6) + t(rx, 5) + t(3, 5)
    return (hex(int(binrep, 2))[2:]+liimm).rjust(8	, '0')

def general_xyi(opcode, rx, ry, ii):
    t = lambda x, n: bin(x)[2:].rjust(n, '0')
    inv01 = lambda x: ''.join(['1' if i == '0' else '0' for i in x])
    if (ii >= 0):
        iii = bin(ii)[2:].rjust(16, '0')
    else:
        iii = inv01(bin(-ii-1)[2:].rjust(16, '0'))
    binrep = t(opcode, 6) + t(rx, 5) + t(ry, 5) + iii
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

def _mul(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    ry = reg2rn(toks[1])
    rz = reg2rn(toks[2])
    return general_xyz(2, rx, ry, rz)

def _div(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    ry = reg2rn(toks[1])
    rz = reg2rn(toks[2])
    return general_xyz(3, rx, ry, rz) 
 
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

def _loa(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    ry = reg2rn(toks[1])
    rz = reg2rn("PC")
    return general_xyz(7, rx, ry, rz)

def _sto(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    ry = reg2rn(toks[1])
    rz = reg2rn("PC")
    return general_xyz(8, rx, ry, rz)

def _shr(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    ry = reg2rn(toks[1])
    rz = reg2rn(toks[2])
    return general_xyz(9, rx, ry, rz)

def _shl(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    ry = reg2rn(toks[1])
    rz = reg2rn(toks[2])
    return general_xyz(10, rx, ry, rz)

def _ll(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    liimm = toks[1][2:]
    return general_ll(rx, liimm)

def _beq(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    ry = reg2rn(toks[1])
    ii = int(toks[2])
    return general_xyi(11, rx, ry, ii)

def _blt(inst):
    toks = inst.strip().split()[1:]
    rx = reg2rn(toks[0])
    ry = reg2rn(toks[1])
    ii = int(toks[2])
    return general_xyi(12, rx, ry, ii)

BOOT_PC = 0
pc = BOOT_PC
with open("inst.l2", "r") as fin, open("inst.hex", "w") as fout, open("inst.vhdl", "w") as fv:
    for l in fin:
        if l.strip()[0] == ';':
            continue;
        typ = l.strip().split()[0]
        stmt = "_" + typ + "(l.strip())"
        hex_stmt = eval(stmt)
        print(hex_stmt, file=fout, end='')
        for i in range(3, -1, -1):
            print("mem(%d) <= x\"%s\";" % (pc, str(hex_stmt[i * 2:(i + 1) * 2])), file = fv)
            pc += 1
    print("00300000", file=fout, end='')