
def init():

    global instructions
    instructions = {}

    global registers
    registers = []

    global code
    code = {} # start from 0x00010000

    global codeinfo
    codeinfo = {}

    global labels
    labels = {}

    global data
    data = {} # start from 0x00020000

    global reg
    reg = {}
