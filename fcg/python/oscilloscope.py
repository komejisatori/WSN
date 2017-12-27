#!/usr/bin/env python

import sys
import tos
import matplotlib.pyplot as plt
import threading
import matplotlib.pyplot as plt
import numpy as np

AM_WSN_DATA_MSG = 0x66
READ_FLAG = False
READ_TYPE = 0
WRITE_TO_FILE_FLAG = True
am = tos.AM()

class OscilloscopeMsg(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self,
                            [('nodeId',  'int', 2),
                             ('temperature', 'int', 2),
                             ('humidity', 'int', 2),
                             ('illumination', 'int', 2),
                             ('collectTime', 'int', 4),
                             ('sequenceNumber', 'int', 2),
                             ('type', 'int', 2),
                             ('newTimerPeriod', 'int', 2)],
                            packet)

def receiveData():
    global READ_FLAG, READ_TYPE, am
    x1 = []
    y1 = []
    x2 = []
    y2 = []
    count1 = 0
    count2 = 0
    
    max_x = 4
    max_y = -100
    min_y = -100
    if READ_TYPE == 1 :
        y_label_name = "temperature"
    elif READ_TYPE == 2:
        y_label_name = "humidity"
    elif READ_TYPE == 3:
        y_label_name = "illumination"
    plt.plot(x1,y1,label='Frist line',linewidth=2,color='r')
    plt.plot(x2,y2,label='second line')
    plt.xlabel('num')
    plt.ylabel( y_label_name)
    plt.title('my graph')
    plt.legend()
    plt.ion()
    plt.show()
    while READ_FLAG:
        p = am.read()
        if p and p.type == AM_WSN_DATA_MSG:
            msg = OscilloscopeMsg(p.data)
            if READ_TYPE == 1 :
                input_y = msg.temperature
                y_label = "temperature"
            elif READ_TYPE == 2:
                input_y = msg.humidity
                y_label_name = "humidity"
            elif READ_TYPE == 3:
                input_y = msg.illumination
                y_label_name = "illumination"
            
            if msg.nodeId == 2 :
                y1.append(input_y)
                x1.append(count1)
                if count1 >= max_x:
                    max_x = int(count1 * 4 / 3)
                if input_y >= max_y or max_y == -100:
                    max_y = input_y * 5 / 4
                if input_y <= min_y or min_y == -100:
                    min_y = input_y * 4 / 5
                plt.clf()
                plt.axis([0, max_x, min_y-1, max_y+1])
                plt.xlabel('num')
                plt.ylabel(y_label_name)
                plt.plot(x1,y1,label='node 2',linewidth=2,color='r')
                plt.plot(x2,y2,label='node 3')
                plt.legend()
                plt.pause(0.1)
                count1 += 1
                
            elif msg.nodeId == 3:
                y2.append(input_y)
                x2.append(count2)
                if count2 >= max_x:
                    max_x = int(count1 * 4 / 3)
                if input_y >= max_y or max_y == -100:
                    max_y = input_y * 5 / 4
                if input_y <= min_y or min_y == -100:
                    min_y = input_y * 4 / 5
                plt.clf() 
                plt.axis([0, max_x, min_y-1, max_y+1])
                plt.xlabel('num')
                plt.ylabel(y_label_name)
                plt.plot(x1,y1,label='node 2',linewidth=2,color='r')
                # plt.plot(x1,y1,label='node 2',linewidth=3,color='r',marker='o', markerfacecolor='blue',markersize=12)
                plt.plot(x2,y2,label='node 3')
                plt.legend()
                plt.pause(0.1)
                count2 += 1
    plt.ioff()
    plt.close()
def writeToFile() :
    global WRITE_TO_FILE_FLAG
    output = open("result.txt", "w")
    output.write("nodeId temperature humidity illumination collectTime sequenceNumber type newTimerPeriod\n")
    while WRITE_TO_FILE_FLAG:
        p = am.read()
        if p and p.type == AM_WSN_DATA_MSG:
            msg = OscilloscopeMsg(p.data)
            msgList = [str(msg.nodeId), str(msg.temperature), str(msg.humidity), str(msg.illumination), 
                        str(msg.collectTime), str(msg.sequenceNumber), str(msg.type), str(msg.newTimerPeriod)]
            writeStr = ' '.join(msgList)
            writeStr += '\n'
            output.write(writeStr)
    output.close()

def sendMessage(packet) :
    global am
    am.write(packet, AM_WSN_DATA_MSG)
    

while True:
    command = raw_input("please enter your command: ")
    if command == "start":
        READ_FLAG = False
        WRITE_TO_FILE_FLAG = True
        t = threading.Thread(target= writeToFile)
        t.start()
    elif command == "stop":
        WRITE_TO_FILE_FLAG = False
    elif (command == "temperature") or (command == "temp"):
        WRITE_TO_FILE_FLAG = False
        READ_TYPE = 1
        READ_FLAG = True
        t = threading.Thread(target=receiveData)
        t.start()
    elif (command == "humidity") or (command == "humi"):
        WRITE_TO_FILE_FLAG = False
        READ_TYPE = 2
        READ_FLAG = True
        t = threading.Thread(target=receiveData)
        t.start()
    elif (command == "illumination") or (command == "illu"):
        WRITE_TO_FILE_FLAG = False
        READ_TYPE = 3
        READ_FLAG = True
        t = threading.Thread(target=receiveData)
        t.start()
    elif (command.startswith("time")):
        newPeriod = int(command.split(" ")[1])
        newPacket = OscilloscopeMsg()
        newPacket.nodeId = 0
        newPacket.temperature = 0
        newPacket.humidity = 0 
        newPacket.illumination = 0
        newPacket.collectTime = 0 
        newPacket.sequenceNumber = 0
        print(newPeriod)
        newPacket.type = 1
        newPacket.newTimerPeriod = newPeriod
        am.write(newPacket, AM_WSN_DATA_MSG)
        # t = threading.Thread(target=sendMessage, args=(newPacket))
        # t.start()
    elif command == "stopgui":
        READ_FLAG = False
    elif command == "exit":
        READ_FLAG = False
        WRITE_TO_FILE_FLAG = False
        break






'''
while True:
        
        p = am.read()

        if p and p.type == AM_WSN_DATA_MSG:
            msg = OscilloscopeMsg(p.data)
            print msg.nodeId, msg.temperature
            y = np.random.random()
            if msg.nodeId == 1 :
                y1.append(y)
                x1.append(count1)
                plt.clf()
                plt.axis([0, 100, 0, 1])
                plt.xlabel('Plot Number')
                plt.ylabel('Important var')
                plt.plot(x1,y1,label='Frist line',linewidth=3,color='r',marker='o', markerfacecolor='blue',markersize=12)
                plt.plot(x2,y2,label='second line')
                plt.pause(0.1)
                count1 += 1
            elif msg.nodeId == 2:
                y2.append(y)
                x2.append(count2)
                plt.clf() 
                plt.axis([0, 100, 0, 1])
                plt.xlabel('Plot Number')
                plt.ylabel('Important var')
                plt.plot(x1,y1,label='Frist line',linewidth=3,color='r',marker='o', markerfacecolor='blue',markersize=12)
                plt.plot(x2,y2,label='second line')
                plt.pause(0.1)
                count2 += 1
'''

