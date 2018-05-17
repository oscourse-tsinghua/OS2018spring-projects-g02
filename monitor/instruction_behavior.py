from __future__ import print_function
import datamanager as dm
def next_timestep():
    interrupt = False
    if (dm.reg["fr"] & 0x4) != 0:
        dm.reg["fr"] |= 0x2
        dm.reg["fr"] ^= 0x4
        dm.reg["pc"] = dm.data[dm.reg["sp"]]
        dm.reg["sp"] += dm.reg["wr"]
    if dm.out_timecnt > 0:
        dm.out_timecnt -= 1
        if dm.out_timecnt == 0:
            dm.reg["fr"] |= 0x240
            interrupt = True
    if dm.in_timecnt > 0:
        dm.in_timecnt -= 1
        if dm.in_timecnt == 0:
            dm.reg["fr"] |= 0x500
            interrupt = True
    if dm.timecnt > 0:
        dm.timecnt -= 1
        if dm.timecnt == 0:
            dm.reg["fr"] |= 0x10
            interrupt = True
    if interrupt:
        dm.reg["fr"] ^= 0x2
        dm.reg["sp"] -= dm.reg["wr"]
        dm.data[dm.reg["sp"]] = dm.reg["pc"]
        dm.reg["pc"] = dm.data[0x300020]

def getimm(s):
    try:
        v = int(s, 0)
    except ValueError:
        v = dm.labels[s]
    return v

def getaddr(s):
    st = s.split("(")
    v = getimm(st[0])
    f = dm.reg[st[1][1:-1]]
    return v + f

def serial_write(x):
    print(chr(x), end='')
    dm.out_timecnt = dm.SERIAL_TIME

def lui_run(args):
    t = args[1][1:]
    v = getimm(args[2])
    dm.reg[t] = (v << 16)
    dm.reg["pc"] += 4

def addiu_run(args):
    t = args[1][1:]
    f = args[2][1:]
    v = getimm(args[3])
    dm.reg[t] = dm.reg[f] + v
    dm.reg["pc"] += 4

def or_run(args):
    t = args[1][1:]
    f1 = args[2][1:]
    f2 = args[3][1:]
    dm.reg[t] = (dm.reg[f1] | dm.reg[f2])
    dm.reg["pc"] += 4

def ori_run(args):
    t = args[1][1:]
    f = args[2][1:]
    v = getimm(args[3])
    dm.reg[t] = (dm.reg[f] | v)
    dm.reg["pc"] += 4

def and_run(args):
    t = args[1][1:]
    f1 = args[2][1:]
    f2 = args[3][1:]
    dm.reg[t] = (dm.reg[f1] & dm.reg[f2])
    dm.reg["pc"] += 4

def add_run(args):
    t = args[1][1:]
    f1 = args[2][1:]
    f2 = args[3][1:]
    dm.reg[t] = (dm.reg[f1] + dm.reg[f2])
    dm.reg["pc"] += 4

def xor_run(args):
    t = args[1][1:]
    f1 = args[2][1:]
    f2 = args[3][1:]
    dm.reg[t] = (dm.reg[f1] ^ dm.reg[f2])
    dm.reg["pc"] += 4

def subu_run(args):
    t = args[1][1:]
    f1 = args[2][1:]
    f2 = args[3][1:]
    dm.reg[t] = (dm.reg[f1] - dm.reg[f2])
    dm.reg["pc"] += 4

def addu_run(args):
    t = args[1][1:]
    f1 = args[2][1:]
    f2 = args[3][1:]
    dm.reg[t] = (dm.reg[f1] + dm.reg[f2])
    dm.reg["pc"] += 4

def beq_run(args):
    f1 = args[1][1:]
    f2 = args[2][1:]
    v = getimm(args[3])
    if(dm.reg[f1] == dm.reg[f2]):
        dm.reg["pc"] = v
    else:
        dm.reg["pc"] += 4

def jr_run(args):
    f = args[1][1:]
    dm.reg["pc"] = dm.reg[f]

def loa_run(args):
    t = args[1][1:]
    addr = getaddr(args[2])
    dm.reg[t] = dm.data[addr]
    dm.reg["pc"] += 4
    pass

def sto_run(args):
    t = args[1][1:]
    addr = getaddr(args[2])
    if addr == 0x300000:
        serial_write(dm.reg[t])
    else:
        dm.data[addr] = dm.reg[t]
    dm.reg["pc"] += 4
    pass

def lb_run(args):
    t = args[1][1:]
    addr = getaddr(args[2])
    dm.reg[t] = dm.data[addr]
    dm.reg["pc"] += 4
    pass

