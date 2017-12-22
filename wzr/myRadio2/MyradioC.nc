#include <Timer.h>
#include "Myradio.h"

module MyradioC{
    uses interface Boot;
    uses interface Leds;
    uses interface Timer<TMilli> as Timer1;
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend as PackSend;
    uses interface Receive;
    uses interface SplitControl as AMControl;
    uses interface Read<uint16_t> as ReadTemperature;
    uses interface Read<uint16_t> as ReadHumidity;
    uses interface Read<uint16_t> as ReadIllumination;
    uses interface PacketAcknowledgements as PacketAck;
}

implementation{
    uint16_t counter = 0;
    uint16_t sequenceNumber = 0;
    
    bool busy = FALSE;
    bool full = FALSE;
    uint16_t frequence =1000;
    uint16_t read_check = 0;
    uint16_t messageDest[12];
    message_t sendMessage[12];
    message_t* ONE_NOK sendQueue[12];
    message_t receive_pkt;
    message_t* ONE_NOK receive_pkt_pointer;
    message_t pkt;
    message_t* ONE_NOK pkt_pointer;
    uint16_t receive_point = 0;
    uint16_t send_point = 0;
    my_radio_msg collected_data;

    event void Boot.booted(){
        uint8_t i;
        for(i = 0 ; i < 12; i ++){
            sendQueue[i] = &sendMessage[i];
            messageDest[i] = 0;
        }
        pkt_pointer = &pkt;
        receive_pkt_pointer = &receive_pkt;
        call AMControl.start();
    }

    event void AMControl.startDone(error_t err){
        if(err == SUCCESS){
            call Timer1.startPeriodic(frequence);
        }
    }

    event void AMControl.stopDone(error_t err){

    }
    
    task void timerRestart () {
        call Timer1.stop();
        call Timer1.startPeriodic(frequence);
    }

    task void radioSendTask(){
        atomic{
            if(send_point == receive_point && !full){
                busy = FALSE;
                return;
            }
            call PacketAck.requestAck(sendQueue[send_point]); // require for ack
            if(call PackSend.send(messageDest[send_point],sendQueue[send_point],sizeof(my_radio_msg)) == SUCCESS){
                busy = FALSE;
            }
            else{
                post radioSendTask();
            }
        }
    }

    task void collectedDataSendTask () {
        my_radio_msg* send_pkt = (my_radio_msg*)(call Packet.getPayload(&sendMessage[receive_point], sizeof(my_radio_msg)));
        atomic{
            if(full){
                return;
            }
            send_pkt->nodeId = collected_data.nodeId;
            send_pkt->collectTime = collected_data.collectTime;
            send_pkt->newTimerPeriod = collected_data.newTimerPeriod;
            send_pkt->temperature = collected_data.temperature;
            send_pkt->illumination = collected_data.illumination;
            send_pkt->humidity = collected_data.humidity;
            send_pkt->type = collected_data.type;
            send_pkt->sequenceNumber = sequenceNumber;
            sequenceNumber ++;

            messageDest[receive_point] = TOS_NODE_ID - 1;
            receive_point ++;
            if (receive_point >= 12)
                receive_point = 0;
            if (receive_point == send_point) 
                full = TRUE;
            if(!busy){
                post radioSendTask(); 
                busy = TRUE;
            }
        }
    }

    event void Timer1.fired(){
        if(!full){
            counter += frequence;
            collected_data.nodeId = TOS_NODE_ID;
            collected_data.collectTime = counter;
            collected_data.newTimerPeriod = 0;
            collected_data.type = 0;
            call ReadTemperature.read();
            call ReadHumidity.read();
            call ReadIllumination.read();
        }
    }

    event void ReadTemperature.readDone(error_t result, uint16_t data){
        if (result == SUCCESS) {
            collected_data.temperature = -40.1 + 0.01 * data;
            read_check += 1;
            if(read_check == 3){
                post collectedDataSendTask();
                read_check = 0;
            }
            //call Leds.led0Toggle();
        }
    }

    event void ReadHumidity.readDone(error_t result, uint16_t data){
        if (result == SUCCESS) {
            collected_data.humidity = -4 + 4 * data / 100 + (-28 / 1000 / 10000) * (data * data);
            collected_data.humidity += (collected_data.temperature - 25) * (1 / 100 + 8 * data / 100 / 1000);
            read_check += 1;
            if(read_check == 3){
                post collectedDataSendTask();
                read_check = 0;
            }
        }
    }

    event void ReadIllumination.readDone(error_t result, uint16_t data){
        if(result == SUCCESS){
            collected_data.illumination = data;
            read_check += 1;
            if(read_check == 3){
                post collectedDataSendTask();
                read_check = 0;
            }
        }
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
        atomic {
            if(len == sizeof(my_radio_msg)){
                my_radio_msg* node_pkt = (my_radio_msg*)(call Packet.getPayload(msg, sizeof(my_radio_msg)));
                my_radio_msg* this_pkt = (my_radio_msg*)(call Packet.getPayload(&sendMessage[receive_point], sizeof(my_radio_msg)));
                this_pkt->nodeId = node_pkt->nodeId;
                this_pkt->temperature = node_pkt->temperature;
                this_pkt->humidity = node_pkt->humidity;
                this_pkt->illumination = node_pkt->illumination;
                this_pkt->collectTime = node_pkt->collectTime;
                this_pkt->sequenceNumber = sequenceNumber;
                if (node_pkt->type == 0) {
                    sequenceNumber ++;
                    messageDest[receive_point] = TOS_NODE_ID - 1;
                }
                else {
                    messageDest[receive_point] = TOS_NODE_ID + 1;
                    frequence = node_pkt->newTimerPeriod;
                    post timerRestart();
                }
                this_pkt->type = node_pkt->type;
                this_pkt->newTimerPeriod = node_pkt->newTimerPeriod;
                receive_point ++;
                if(receive_point >= 12){
                    receive_point = 0;
                }
                if(receive_point == send_point){
                    full = TRUE;
                }
                call Leds.led1Toggle();
                if(!busy){
                    post radioSendTask();
                    busy = TRUE;
                }
                return msg;
        }
        return msg;
        }
    }

    event void PackSend.sendDone(message_t* msg, error_t error){
        if (call PacketAck.wasAcked(msg) && error == SUCCESS) {
            call Leds.led0Toggle();
            send_point ++;
            if(send_point >= 12){
                send_point = 0;
                full = FALSE;
            }
        } 
        else {
            call Leds.led2Toggle();
        }

        post radioSendTask();
    }
}