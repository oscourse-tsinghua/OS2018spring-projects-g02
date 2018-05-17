
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

    global global_labels
    global_labels = []

    global label_size
    label_size = {}

    global label_type
    label_type = {}

    global data
    data = {} # start from 0x00020000

    global reg
    reg = {}

    global SERIAL_TIME
    SERIAL_TIME = 50

    global out_timecnt
    out_timecnt = 0

    global in_timecnt
    in_timecnt = 0

    global timecnt
    timecnt = 0

    global relocate_info
    relocate_info = []

    global filename
    filename = ""
