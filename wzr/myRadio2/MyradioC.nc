#include <Timer.h>
#include "Myradio.h"

module MyradioC{
    uses interface Boot;
    uses interface Leds;
    uses interface Timer<TMilli> as Timer;
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend;
    uses interface Receive;
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
        atomic{
            if(send_point == receive_point && !full){
                busy = FALSE;
                return;
            }
            if(call AMSend.send(AM_BROADCAST_ADDR,sendQueue[send_point],sizeof(my_radio_msg)) == SUCCESS){
                call Leds.led0Toggle();
            }
            else{
                post radioSendTask();
            }
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

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
        atomic {
            if(len == sizeof(my_radio_msg)){
                my_radio_msg* node_pkt = (my_radio_msg*)(call Packet.getPayload(&msg, sizeof(my_radio_msg)));
                //node_pkt->sequenceNumber = sequenceNumber;
                
                //sendMessage[receive_point] = *node_pkt;
                sendMessage[receive_point].nodeId = node_pkt->nodeId;
                sendMessage[receive_point].collectTime = node_pkt->collectTime;
                sendMessage[receive_point].sequenceNumber = sequenceNumber;
                sequenceNumber ++;
                sendMessage[receive_point].type = node_pkt->type;
                sendMessage[receive_point].newTimerPeriod = node_pkt->newTimerPeriod;
                //sendQueue[receive_point] = node_pkt;
                receive_point ++;
                if(receive_point >= 12){
                    receive_point = 0;
                }
                if(receive_point == send_point){
                    full = TRUE;
                }
                call Leds.led1Toggle();
            }
        }
        return msg;
    }

    event void AMSend.sendDone(message_t* msg, error_t err){
        if(err == SUCCESS){
            atomic{
                if(sendQueue[send_point] == msg){
                    send_point ++;
                    if(send_point >= 12){
                        send_point = 0;
                    }
                    full = FALSE;
                    call Leds.led2Toggle();
                }
                post radioSendTask();
            }
        }
        else{
            
        }
    }
}