import datamanager as dm

def init():
    global regcode
    regcode = {"pc": 0, "sp": 1, "fp" :2, "zr": 3, "fp": 4, "wr": 5, "lr": 7, "gp": 8, "v0": 9, "v1": 10, "a0": 11, "a1": 12, "s0": 13, "s1": 14, "t0": 15, "t1": 16, "t2": 17, "t3": 18, "t4": 19, "t5": 20, "t6": 21, "t7": 22, "t8": 23, "t9": 24, "ra":31}

def getreg(s):
    r = regcode[s]
    ret = ""
    while len(ret) < 5:
        ret = str(r&1) + ret
        r = (r >> 1)
    return ret

def getimm(s, pc=0):
    try:
        v = int(s, 0)
    except (ValueError, TypeError):
        if dm.labels.has_key(s):
            v = dm.labels[s]-pc
        elif s[0] == "%":
            st = s.split("(")
            if st[0][1:] == "hi":
                lb = st[1][:-1]
                if dm.labels.has_key(lb):
                    v = (dm.labels[lb] >> 16)-pc
                else:
                    v = 0
                    lbinfo = {"name": lb, "offset": pc, "type": "hi"}
                    dm.relocate_info.append(lbinfo)
            elif st[0][1:] == "lo":
                lb = st[1][:-1]
                if dm.labels.has_key(lb):
                    v = (dm.labels[lb]&((1<<16)-1))-pc
                else:
                    v = 0
                    lbinfo = {"name": lb, "offset": pc, "type": "lo"}
                    dm.relocate_info.append(lbinfo)
            else:
                assert(False)
        else:
            v = 0
            lbinfo = {"name": s, "offset": pc, "type": "full"}
            dm.relocate_info.append(lbinfo)
    ret = ""
    while len(ret) < 16:
        ret = str(v&1) + ret
        v = (v >> 1)
    return ret

def getaddr(s):
    st = s.split("(")
    v = getimm(st[0])
    f = getreg(st[1][1:-1])
    return f + v

def lui_code(args):
    code = "001110"
    code += getreg(args[1][1:])
    code += "00000"
    code += getimm(args[2], args[3])
    return code

def addiu_code(args):
    code = "001101"
    code += getreg(args[1][1:])
    code += getreg(args[2][1:])
    code += getimm(args[3], args[4])
    return code

def or_code(args):
    code = "000101"
    code += getreg(args[1][1:])
    code += getreg(args[2][1:])
    code += getreg(args[3][1:])
    code += "00000000000"
    return code

def ori_code(args):
    code = "010000"
    code += getreg(args[1][1:])
    code += getreg(args[2][1:])
    code += getimm(args[3], args[4])
    return code

def and_code(args):
    code = "000100"
    code += getreg(args[1][1:])
    code += getreg(args[2][1:])
    code += getreg(args[3][1:])
    code += "00000000000"
    return code

def add_code(args):
    code = "000000"
    code += getreg(args[1][1:])
    code += getreg(args[2][1:])
    code += getreg(args[3][1:])
    code += "00000000000"
    return code

def xor_code(args):
    code = "000110"
    code += getreg(args[1][1:])
    code += getreg(args[2][1:])
    code += getreg(args[3][1:])
    code += "00000000000"
    return code

def subu_code(args):
    code = "000001"
    code += getreg(args[1][1:])
    code += getreg(args[2][1:])
    code += getreg(args[3][1:])
    code += "00000000000"
    return code

def addu_code(args):
    code = "000000"
    code += getreg(args[1][1:])
    code += getreg(args[2][1:])
    code += getreg(args[3][1:])
    code += "00000000000"
    return code

def beq_code(args):
    code = "001011"
    code += getreg(args[1][1:])
    code += getreg(args[2][1:])
    code += getimm(args[3], args[4])
    return code

def jr_code(args):
    code = "010100"
    code += getreg(args[1][1:])
    code += "000000000000000000000"
    return code

def loa_code(args):
    code = "000111"
    code += getreg(args[1][1:])
    code += getaddr(args[2])
    return code

def sto_code(args):
    code = "001000"
    code += getreg(args[1][1:])
    code += getaddr(args[2])
    return code

def lb_code(args):
    pass
