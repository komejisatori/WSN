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
    uses interface PacketAcknowledgements as TerminalAck;
    uses interface PacketAcknowledgements as NodeAck;
}

implementation{
    task void packageSend();
    task void packageCheck();
    uint32_t number_storage[DATA_NUMBER] = {0xffffffff};
    uint32_t max = 0;
    uint32_t min = 0;
    uint32_t sum = 0;
    uint32_t average = 0;
    uint32_t median = 0;

    uint16_t last_sequence = 0;
    bool correct = TRUE;
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
        for(i = 0; i < 2000; i++){
            number_storage[i] = 0xffffffff;
        }
        call AMControl.start();
    }

    event void AMControl.startDone(error_t err){
        if(err == SUCCESS){
            // call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
        }
        else{
            call AMControl.start();
        }
    }

    event void AMControl.stopDone(error_t err){

    }

    event void NodeSender.sendDone(message_t* msg, error_t err){
        if(status == STATUS_RECEIVE_NODE){
            //post packageCheck();
            //call Leds.led2Toggle();
        }
    }

    event void TerminalSender.sendDone(message_t* msg, error_t err){
        if (call TerminalAck.wasAcked(msg) && err == SUCCESS) {
            status = STATUS_END;
        }
        else{
        post packageSend();
        //call Leds.led1Toggle();  
        }
    }

    void sort(uint32_t *number, int left, int right){
        uint16_t i = 0;
        uint16_t j = 0;
        uint16_t key = 0;
        if(left >= right){
            return;
        }
        i = left;
        j = right;
        key = number[left];
     
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
        send_pkt->max = max;
        send_pkt->min = min;
        send_pkt->average = average;
        send_pkt->sum = sum;
        send_pkt->median = median;
        send_pkt->group_id = 1;
        call TerminalAck.requestAck(&pkt);
        if (call TerminalSender.send(0, &pkt, sizeof(calculate_result)) == SUCCESS) {
           
        }
        else{
            post packageSend();
            //call Leds.led2Toggle();
        }
    }

    task void calculate(){
        uint16_t i = 0;
        sort(number_storage, 0, 1999);
        max = number_storage[1999];
        min = number_storage[0];
        for (i = 0; i < 2000; i++){
            sum += number_storage[i];
        }
        average = sum / 2000;
        median = (number_storage[999] + number_storage[1000]) / 2;
        /*if(min == 0 && max == 1999 && sum == 1999000 && average == 999 && median == 999){
            call Leds.led1Off();
            call Leds.led2Off();
            call Leds.led0Off();
            call Timer0.startPeriodic(1000);
        }*/
        //call Timer0.startPeriodic(500);
        call Timer0.startPeriodic(1000);
        status = STATUS_SEND;
        post packageSend();
        
    }



    task void packageRequire(){
        if(TOS_NODE_ID == 1){
            if (call NodeSender.send(AM_BROADCAST_ADDR, &pkt, sizeof(data_require)) == SUCCESS){
                call Leds.led2Toggle();
            }
        }
    }

    task void packageCheck(){
        uint16_t i = 0;
        data_require* send_pkt = (data_require*)(call NodePacket.getPayload(&pkt,sizeof(data_require)));
        for(i = check_point; i < DATA_NUMBER; i ++){
            check_point ++;
            if(number_storage[i] == 0xffffffff){
                correct = FALSE;
                send_pkt->sequence_number = i + 1;
                post packageRequire();
                return;
            }
        }
        if(correct){
            status = STATUS_CALCULATE;
            call Leds.led1On();
            call Leds.led0On();
            call Leds.led2On();
            post calculate();
        }
        else{
            check_point = 0;
            correct = TRUE;
        }
    }

    event void Timer0.fired(){
        if(status == STATUS_RECEIVE_NODE){
            post packageCheck();
        }
        if(status == STATUS_CALCULATE || status == STATUS_SEND){
            call Leds.led0Toggle();
            call Leds.led2Toggle();
            call Leds.led1Toggle();
        }
        if(status == STATUS_END){
            call Leds.led0Toggle();
            call Leds.led1Toggle();
        }
    }

    event message_t* NodeReceiver.receive(message_t* msg, void* payload, uint8_t len){
        if(status == STATUS_RECEIVE_NODE){
            if(len == sizeof(data_package)){
                data_package* btrpkt = (data_package*)payload;
                number_storage[btrpkt->sequence_number - 1] = btrpkt->random_integer;
                call Leds.led1Toggle();
            }
        }
        return msg;
    }

    event message_t* TerminalReceiver.receive(message_t* msg, void* payload, uint8_t len){
        if(status == STATUS_RECEIVE_TERMINAL && len == sizeof(data_package)){
            data_package* btrpkt = (data_package*)payload;
            if(btrpkt->sequence_number < last_sequence){
                status = STATUS_RECEIVE_NODE;
                call Timer0.startPeriodic(50);
                call Leds.led0On();
            }
            number_storage[btrpkt->sequence_number - 1] = btrpkt->random_integer;
            last_sequence = btrpkt->sequence_number;
            call Leds.led0Toggle();
        }
        return msg;
    }
}