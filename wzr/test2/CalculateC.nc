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
    uint32_t max = 0;
    uint32_t min = 0;
    uint32_t sum = 0;
    uint32_t average = 0;
    uint32_t median = 0;
    uint16_t count = 0;
    //uint16_t send_point = 0;
    //uint16_t receive_point = 0;
    uint16_t check_point = 0;
    message_t pkt;
    //message_t send_message[12];
    //message_t* ONE_NOK send_queue[12];
    bool busy = FALSE;
    bool full = FALSE;
    uint16_t status = STATUS_RECEIVE_TERMINAL;
    event void Boot.booted(){
        uint16_t i = 0;
        call AMControl.start();
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

    }

    void sort(uint32_t *number, int left, int right){
        if(left >= right){
            return;
        }
        int i = left;
        int j = right;
        uint32_t key = number[left];
     
        while(i < j){
            while(i < j && key <= number[j]){
                j--;
            }
            number[i] = number[j];
            while(i < j && key >= number[i]){
                i++;
            }
            number[j] = number[i];
        }
     
        number[i] = key;
        sort(number, left, i - 1);
        sort(number, i + 1, right);
    }

    task void packageSend(){
        calculate_result* send_pkt = (calculate_result*)(call NodePacket.getPayload(&pkt,sizeof(calculate_result)));

        if (call TerminalSender.send(AM_BROADCAST_ADDR, &pkt, sizeof(calculate_result)) == SUCCESS) {

        }
        else{
            post packageSend();
        }
    }

    task void calculate(){
        sort(number_storage, 0, 1999);
        max = number_storage[1999];
        min = number_storage[0];
        int i = 0;
        for (i = 0; i < 2000; i++){
            sum += number_storage[i];
        }
        average = sum / 2000;
        median = (number_storage[999] + number_storage[1000]) / 2;
        status = STATUS_SEND;
        post packageSend();
        status = STATUS_END;
    }



    task void packageRequire(){
        if(TOS_NODE_ID == 1){
            if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(data_require)) == SUCCESS){
                busy = FALSE;
            }
        }
        else{
            if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(data_package)) == SUCCESS){
                busy = FALSE;
            }
        }
    }

    task void packageCheck(){
        data_require* send_pkt = (data_require*)(call NodePacket.getPayload(&pkt,sizeof(data_require)));
        uint16_t i = 0;
        for(i = check_point; i < DATA_NUMBER; i ++){
            check_point ++;
            if(number_storage[i] == 0xffffffff){
                send_pkt->sequence_number = i;
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
                send_pkt->sequence_number = btrpkt->sequence_number;
                send_pkt->random_integer = number_storage[btrpkt->sequence_number - 1];
                if(send_pkt->random_integer != 0xffffffff){
                    post packageRequire();
                }
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