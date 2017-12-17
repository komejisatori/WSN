#include <Timer.h>
#include "Myradio.h"

module MyradioC{
    uses interface Boot;
    uses interface Leds;
    uses interface Timer<TMilli> as Timer;
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend;
    uses interface SplitControl as AMControl;
}

implementation{
    uint16_t counter = 0;
    uint16_t sequenceNumber = 0;
    
    bool busy = FALSE;
    bool full = FALSE;
    uint16_t frequence = 1000;
    message_t sendMessage[12];
    message_t* ONE_NOK sendQueue[12];
    uint16_t receive_point = 0;
    uint16_t send_point = 0;

    event void Boot.booted(){
        uint8_t i;
        for(i = 0 ; i < 12; i ++){
            sendQueue[i] = &sendMessage[i];
        }
        call AMControl.start();
    }

    event void AMControl.startDone(error_t err){
        if(err == SUCCESS){
            call Timer.startPeriodic(frequence);
        }
    }

    event void AMControl.stopDone(error_t err){

    }
    
    task void radioSendTask(){
        if(send_point == receive_point && !full){
            busy = FALSE;
            return;
        }
        if(call AMSend.send(AM_BROADCAST_ADDR,sendQueue[send_point],sizeof(my_radio_msg)) == SUCCESS){
            call Leds.led0Toggle();
        }
        else{
            call Leds.led1Toggle();
            post radioSendTask();
        }
    }

    event void Timer.fired(){
        counter ++;
        if(!full){
            my_radio_msg* send_pkt = (my_radio_msg*)(call Packet.getPayload(&sendMessage[receive_point], sizeof(my_radio_msg)));
            if(send_pkt == NULL){
                return;
            }
            send_pkt->nodeId = TOS_NODE_ID;
            send_pkt->data = counter;
            send_pkt->collectTime = counter;
            send_pkt->type = 0;
            send_pkt->sequenceNumber = sequenceNumber;
            sequenceNumber ++;
            send_pkt->newTimerPeriod = 0;
            receive_point ++;
            if(receive_point >= 12){
                receive_point = 0;
            }
            if(receive_point == send_point){
                full = TRUE;
            }
        }
        if(!busy){
            post radioSendTask();
            busy = TRUE;
        }
    }

    event void AMSend.sendDone(message_t* msg, error_t err){
        if(sendQueue[send_point] == msg){
            send_point ++;
            if(send_point >= 12){
                send_point = 0;
            }
            full = FALSE;
        }
        post radioSendTask();
    }
}