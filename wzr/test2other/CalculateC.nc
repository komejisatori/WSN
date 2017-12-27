#include <Timer.h>
#include "Calculate.h"

module CalculateC{
    uses interface Boot;
    uses interface Leds;
    uses interface Packet as TerminalPacket;
    uses interface Packet as NodePacket;
    uses interface AMSend as TerminalSender;
    uses interface Receive as TerminalReceiver;
    uses interface AMSend as NodeSender;
    uses interface Receive as NodeReceiver;
    uses interface SplitControl as AMControl;
}

implementation{
    uint32_t number_storage[DATA_NUMBER] = {0xffffffff};
    message_t pkt;
    //message_t send_message[12];
    //message_t* ONE_NOK send_queue[12];
    bool busy = FALSE;
    event void Boot.booted(){
        uint16_t i = 0;
        for(i = 0; i < 2000; i++){
            number_storage[i] = 0xffffffff;
        }
        call AMControl.start();
    }

    event void AMControl.startDone(error_t err){
        if(err == SUCCESS){
            
        }
        else{
            call AMControl.start();
        }
    }

    event void AMControl.stopDone(error_t err){

    }

    event void NodeSender.sendDone(message_t* msg, error_t err){

    }

    event void TerminalSender.sendDone(message_t* msg, error_t err){

    }

    task void packageRequire(){
        if (call NodeSender.send(AM_BROADCAST_ADDR, &pkt, sizeof(data_package)) == SUCCESS){
            call Leds.led1Toggle();
            busy = FALSE;
        }
    }

    event message_t* NodeReceiver.receive(message_t* msg, void* payload, uint8_t len){
        if(len == sizeof(data_require)){
            data_package* send_pkt = (data_package*)(call NodePacket.getPayload(&pkt,sizeof(data_require)));
            data_require* btrpkt = (data_require*)payload;
            call Leds.led2Toggle();
            send_pkt->sequence_number = btrpkt->sequence_number;
            send_pkt->random_integer = number_storage[btrpkt->sequence_number - 1];
            if(send_pkt->random_integer != 0xffffffff){
                post packageRequire();
            }
        }
        return msg;
    }

    event message_t* TerminalReceiver.receive(message_t* msg, void* payload, uint8_t len){
        if(len == sizeof(data_package)){
            data_package* btrpkt = (data_package*)payload;
            number_storage[btrpkt->sequence_number - 1] = btrpkt->random_integer;
            call Leds.led0Toggle();
        }
        return msg;
    }
}