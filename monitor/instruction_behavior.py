import datamanager as dm

def getimm(s):
    try:
        v = int(s, 0)
    except ValueError:
        v = dm.labels[s]
    return v

def lui_(args):
    t = args[1][1:]
    v = getimm(args[2])
    dm.reg[t] = (v << 16)
    dm.reg["pc"] += 4

def addiu_(args):
    t = args[1][1:]
    f = args[2][1:]
    v = getimm(args[3])
    dm.reg[t] = dm.reg[f] + v
    dm.reg["pc"] += 4

def or_(args):
    t = args[1][1:]
    f1 = args[2][1:]
    f2 = args[3][1:]
    dm.reg[t] = (dm.reg[f1] | dm.reg[f2])
    dm.reg["pc"] += 4

def and_(args):
    t = args[1][1:]
    f1 = args[2][1:]
    f2 = args[3][1:]
    dm.reg[t] = (dm.reg[f1] & dm.reg[f2])
    dm.reg["pc"] += 4

def add_(args):
    t = args[1][1:]
    f1 = args[2][1:]
    f2 = args[3][1:]
    dm.reg[t] = (dm.reg[f1] + dm.reg[f2])
    dm.reg["pc"] += 4

def xor_(args):
    t = args[1][1:]
    f1 = args[2][1:]
    f2 = args[3][1:]
    dm.reg[t] = (dm.reg[f1] ^ dm.reg[f2])
    dm.reg["pc"] += 4

def subu_(args):
    t = args[1][1:]
    f1 = args[2][1:]
    f2 = args[3][1:]
    dm.reg[t] = (dm.reg[f1] - dm.reg[f2])
    dm.reg["pc"] += 4

def addu_(args):
    t = args[1][1:]
    f1 = args[2][1:]
    f2 = args[3][1:]
    dm.reg[t] = (dm.reg[f1] - dm.reg[f2])
    dm.reg["pc"] += 4

def beq_(args):
    f1 = args[1][1:]
    f2 = args[2][1:]
    v = getimm(args[3])
    if(dm.reg[f1] == dm.reg[f2]):
        dm.reg["pc"] = v
    else:
        dm.reg["pc"] += 4

def jr_(args):
    f = args[1][1:]
    dm.reg["pc"] = dm.reg[f]

def loa_(args):
    dm.reg["pc"] += 4
    pass

def sto_(args):
    dm.reg["pc"] += 4
    pass

def lb_(args):
    dm.reg["pc"] += 4
    pass

