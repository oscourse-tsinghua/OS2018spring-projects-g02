import datamanager as dm
import instruction_code


if __name__ == "__main__":
    filename = "extvar.S"
    dm.init()
    import assembler
    assembler.initInstructions()
    assembler.initRegisters()
    assembler.readAssembly(filename)
    assembler.checkForRelocate()
    instruction_code.init()
    output = file(filename[:-1]+"m", "w")
    output.write(filename+"\n")
    output.write("Relocatable\n")
    output.write("text:\n")
    addr = 0x00000000
    while dm.code.has_key(addr):
        sl = dm.code[addr]
        c = sl[0] + "_code"
        cd = getattr(instruction_code, c)(sl + [addr])
        assert(len(cd) == 32)
        output.write(cd + "\n")
        addr += 4
    if len(dm.relocate_info) > 0:
        output.write("rel.text:\n")
        for item in dm.relocate_info:
            output.write(str(item["offset"]))
            output.write(" ")
            output.write(item["type"])
            output.write(" ")
            output.write(item["name"])
            output.write("\n")
    if len(dm.data) > 0:
        output.write("data:\n")
        pass #TODO 
    output.write("comment:\n")
    output.write(".assembler by keavil for recc\n")
    output.write("symtab:\n")
    for item in dm.relocate_info:
        if not item["name"] in dm.global_labels:
            dm.global_labels.append(item["name"])
    for item in dm.global_labels:
        output.write(item)
        output.write(" ")
        if dm.label_size.has_key(item):
            sl = dm.label_size[item].split('-')
            v = dm.labels[sl[0][1:-1]] - dm.labels[sl[1]]
            output.write(str(v))
        else:
            output.write("0")
        output.write(" ")
        if dm.label_type.has_key(item):
            output.write(dm.label_type[item])
        else:
            output.write("NOTYPE")
        output.write("\n")


