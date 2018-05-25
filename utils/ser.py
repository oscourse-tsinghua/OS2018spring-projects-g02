from __future__ import print_function
import serial
import threading
import time

def listen(seri):
    while (True):
        print(hex(ord(seri.read()))[2:].zfill(2), end=' ')
	#	print(seri.read(), end='')
        

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
while (True):
    inp = raw_input("input: ").strip()
    if inp.split()[0] == "file":
        with open(inp.split()[1], 'r') as fp: 
            hex_list = ["{:02x}".format(ord(c)) for c in fp.read()]
            print(hex_list)
            inp = ''.join(hex_list)
    for i in range(0, len(inp), 2):
        ser.write(chr(int(inp[i:i+2], 16)))
        time.sleep(0.01)
    time.sleep(0.01)