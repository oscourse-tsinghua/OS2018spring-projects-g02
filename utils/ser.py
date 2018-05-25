from __future__ import print_function
import serial
import threading
import time

def listen(seri):
    while (True):
    #    print(hex(ord(seri.read()))[2:].zfill(2), end=' ')
		print(seri.read(), end='')
        

ser = serial.Serial('COM3', 9600)
lis = ser
send = ser

threads = []
t1 = threading.Thread(target=listen, args=(lis,))
threads.append(t1) 

if __name__ == '__main__':
    for t in threads:
        t.setDaemon(True)
        t.start()
input_format = "hex"
while (True):
    inp = raw_input("input: ").strip()
    if inp.split()[0] == "file":
        with open(inp.split()[1], 'rb') as fp: 
            hex_list = ["{:02x}".format(ord(c)) for c in fp.read()]
            print(hex_list)
            inp = ''.join(hex_list)
    else:
        if inp.split()[0] == "set":
            if inp.split()[1] == "input":
                if inp.split()[2] == "hex":
                    input_format = "hex"
                    print("change input format into HEX")
                elif inp.split()[2] == "ascii":
                    input_format = "ascii"
                    print("change input format into ASCII")
            continue;
    if input_format == "hex":
        while (len(inp) % 8 != 0):
            inp = inp + "0"
        print(len(inp))
        for j in range(0, len(inp) / 8):
            for i in range(4, 0, -1):
                ser.write(chr(int(inp[j*8+i*2-2:j*8+i*2], 16)))
                time.sleep(0.001)
            time.sleep(0.001)
    elif input_format == "ascii":
        for ch in inp:
            ser.write(ch)
            time.sleep(0.001)
        time.sleep(0.001)