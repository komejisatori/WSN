#include <Timer.h>
#include "Myradio.h"

module MyradioC{
    uses interface Boot;
    uses interface Leds;
    uses interface Timer<TMilli> as Timer;
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend as PackSend;
    uses interface AMSend as ACKSend;
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
    message_t receive_pkt;
    message_t* ONE_NOK receive_pkt_pointer;
    message_t pkt;
    message_t* ONE_NOK pkt_pointer;
    uint16_t receive_point = 0;
    uint16_t send_point = 0;

    event void Boot.booted(){
        uint8_t i;
        for(i = 0 ; i < 12; i ++){
            sendQueue[i] = &sendMessage[i];
        }
        pkt_pointer = &pkt;
        receive_pkt_pointer = &receive_pkt;
        call AMControl.start();
    }

    event void AMControl.startDone(error_t err){
        if(err == SUCCESS){
            call Timer.startPeriodic(frequence);
        }
    }

    event void AMControl.stopDone(error_t err){

    }

    task void ackSendTask(){
        atomic{
            if(call ACKSend.send(AM_BROADCAST_ADDR,pkt_pointer,sizeof(my_radio_msg)) == SUCCESS){
                call Leds.led2Toggle();
            }
            else{
                post ackSendTask();
            }
        }
    }
    
    task void radioSendTask(){
        atomic{
            if(send_point == receive_point && !full){
                busy = FALSE;
                return;
            }
            if(call PackSend.send(AM_BROADCAST_ADDR,sendQueue[send_point],sizeof(my_radio_msg)) == SUCCESS){
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
            send_pkt->counter = counter;
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
                my_radio_msg* ack_pkt = (my_radio_msg*)(call Packet.getPayload(&pkt, sizeof(my_radio_msg)));
                my_radio_msg* node_pkt = (my_radio_msg*)(call Packet.getPayload(msg, sizeof(my_radio_msg)));
                //node_pkt->sequenceNumber = sequenceNumber;
                my_radio_msg* this_pkt = (my_radio_msg*)(call Packet.getPayload(&sendMessage[receive_point], sizeof(my_radio_msg)));
                //sendMessage[receive_point] = *node_pkt;
                this_pkt->nodeId = node_pkt->nodeId;
                this_pkt->counter = node_pkt->counter;
                this_pkt->collectTime = node_pkt->collectTime;
                this_pkt->sequenceNumber = sequenceNumber;
                sequenceNumber ++;
                this_pkt->type = node_pkt->type;
                this_pkt->newTimerPeriod = node_pkt->newTimerPeriod;
                //sendQueue[receive_point] = node_pkt;
                receive_point ++;
                if(receive_point >= 12){
                    receive_point = 0;
                }
                if(receive_point == send_point){
                    full = TRUE;
                }
                
                if(ack_pkt == NULL){
                    return;
                }
                ack_pkt->nodeId = node_pkt->nodeId;
                ack_pkt->type = 1;
                ack_pkt->ack = 1;
                ack_pkt->newTimerPeriod = 0;
                call Leds.led1Toggle();
                post ackSendTask();
        }
        return msg;
        }
    }

    event void ACKSend.sendDone(message_t* msg, error_t err){
        if(err == SUCCESS){
            
        }
        else{
            post ackSendTask();
        }
    }

    event void PackSend.sendDone(message_t* msg, error_t err){
        if(err == SUCCESS){
            atomic{
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
        else{
            
        }
    }
}