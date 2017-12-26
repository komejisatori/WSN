#include <Timer.h>
#include "Calculate.h"

module CalculateC{
    uses interface Boot;
    uses interface Leds;
    uses interface Timer<TMilli> as Timer0;
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
    uint16_t count = 0;
    uint16_t send_point = 0;
    uint16_t receive_point = 0;
    uint16_t check_point = 0;
    message_t pkt;
    message_t send_message[12];
    message_t* ONE_NOK send_queue[12];
    bool busy = FALSE;
    bool full = FALSE;
    uint16_t status = STATUS_RECEIVE_TERMINAL;
    event void Boot.booted(){
        uint16_t i = 0;
        call AMControl.start();
        for(i = 0 ; i < 12; i ++){
            send_queue[i] = &send_message[i];
        }
    }

    event void AMControl.startDone(error_t err){
        if(err == SUCCESS){
            call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
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
        if(err == SUCCESS){
            send_point ++;
            if(send_point == 12){
                send_point = 0;
            }
        }
    }

    void sort(){

    }

    task void packageSend(){

    }

    task void calculate(){
        sort();
        //calculate
        status = STATUS_SEND;
        post packageSend();
        status = STATUS_END;
    }



    task void packageRequire(){
        if(TOS_NODE_ID == 1){
            //to othernode
        }
        else{
            //to mainnode
        }//pkt
    }

    task void packageCheck(){
        data_require* send_pkt = (data_require*)(call NodePacket.getPayload(&pkt,sizeof(data_require)));
        uint16_t i = 0;
        for(i = check_point; i < DATA_NUMBER; i ++){
            check_point ++;
            if(number_storage[i] == 0xffffffff){
                send_pkt->sequence_number = i;
                receive_point ++;
                if(receive_point == 12){
                    receive_point = 0;
                }
                if(!busy){
                    post packageRequire();
                    busy = TRUE;
                }
                return;
            }
        }
        if(TOS_NODE_ID == 1){
            status = STATUS_CALCULATE;
            post calculate();
        }
        else{
            status = STATUS_END;
        }
    }

    event void Timer0.fired(){
        count ++;
        if(status == STATUS_RECEIVE_NODE){
            post packageCheck();
        }
    }

    event message_t* NodeReceiver.receive(message_t* msg, void* payload, uint8_t len){
        if(status == STATUS_RECEIVE_NODE){
            if(len == sizeof(data_package)){
                data_package* btrpkt = (data_package*)payload;
                number_storage[btrpkt->sequence_number - 1] = btrpkt->random_integer;
            }
            else if(len == sizeof(data_require)){
                data_package* send_pkt = (data_package*)(call NodePacket.getPayload(&pkt,sizeof(data_require)));
                data_require* btrpkt = (data_require*)payload;
                //----------
                post packageRequire();
            }
        }
    }

    event message_t* TerminalReceiver.receive(message_t* msg, void* payload, uint8_t len){
        if(status == STATUS_RECEIVE_TERMINAL && len == sizeof(data_package)){
            data_package* btrpkt = (data_package*)payload;
            number_storage[btrpkt->sequence_number - 1] = btrpkt->random_integer;
            if(btrpkt->sequence_number == 2000 || count == 2001){
                status = STATUS_RECEIVE_NODE;
            }
            call Leds.led0Toggle();
        }
        return msg;
    }
}