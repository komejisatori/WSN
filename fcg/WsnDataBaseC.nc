#include <Timer.h>
#include "WsnDataBase.h"

module WsnDataBaseC {
  uses {
    interface Boot;
    interface Leds;

    interface SplitControl as SerialControl;
    interface SplitControl as RadioControl;

    interface AMSend as UartSend;
    interface Receive as UartReceive;
    interface Packet as UartPacket;
    interface AMPacket as UartAMPacket;
    
    interface AMSend as RadioSend;
    interface Receive as RadioReceive;
    interface Packet as RadioPacket;
    interface AMPacket as RadioAMPacket;
  }
}
implementation {
  enum {
    UART_QUEUE_LEN = 12,
  };

  message_t  uartQueueBufs[UART_QUEUE_LEN];
  message_t  * ONE_NOK uartQueue[UART_QUEUE_LEN];
  uint8_t    uartIn, uartOut;
  bool       uartBusy, uartFull;
  
  message_t radioPacket;
  bool radioLocked;

  uint16_t timePeriod = 250;

  task void uartSendTask();
  
  void dropBlink() {
    call Leds.led2Toggle();
  }

  void failBlink() {
    call Leds.led2Toggle();
  }

  event void Boot.booted () {
    uint8_t i;
    for (i = 0; i < UART_QUEUE_LEN; i++)
      uartQueue[i] = &uartQueueBufs[i];
    uartIn = uartOut = 0;
    uartBusy = FALSE;
    uartFull = TRUE;
    call RadioControl.start();
    call SerialControl.start();
  }

  event void RadioControl.startDone(error_t err) {
    if (err == SUCCESS) {
      radioLocked = FALSE;
    }
  }

  event void SerialControl.startDone(error_t err) {
    if (err == SUCCESS) {
      uartFull = FALSE;
    }
  }

  event void SerialControl.stopDone(error_t error) {}
  event void RadioControl.stopDone(error_t error) {}

  event message_t* RadioReceive.receive(message_t* msg, void* payload, uint8_t len) {
    message_t *ret = msg;
    call Leds.led0Toggle();
    atomic {
      if(!uartFull) {
        ret = uartQueue[uartIn];
        uartQueue[uartIn] = msg;

        uartIn = (uartIn + 1) % UART_QUEUE_LEN;

        if (uartIn == uartOut)
          uartFull = TRUE;
        
        if (!uartBusy) {
          post uartSendTask();
          uartBusy = TRUE;
        }
      }
      else {
        dropBlink();
      }
    }
    return ret;
  }

  task void uartSendTask() {
    uint8_t len;
    am_addr_t addr, src;
    message_t* msg;
    atomic{
      if (uartIn == uartOut && !uartFull)
      {
        uartBusy = FALSE;
        return;
      }

      msg = uartQueue[uartOut];
      len = call RadioPacket.payloadLength(msg);
      addr = call RadioAMPacket.destination(msg);
      src = call RadioAMPacket.source(msg);
      call UartPacket.clear(msg);
      call UartAMPacket.setSource(msg, src);

      if (call UartSend.send(AM_BROADCAST_ADDR, uartQueue[uartOut], len) == SUCCESS)
        call Leds.led1Toggle();
      else{
        failBlink();
        post uartSendTask();
      }
    }
  }

  event void UartSend.sendDone(message_t* msg, error_t error) {
    if (error != SUCCESS)
      failBlink();
    else {
      atomic {
        if (msg == uartQueue[uartOut])
        {
          if (++uartOut >= UART_QUEUE_LEN)
            uartOut = 0;
          if (uartFull)
            uartFull = FALSE;
        }
      }
      post uartSendTask();
    }
  }

  event message_t *UartReceive.receive(message_t *msg, void *payload, uint8_t len) {
    if (radioLocked) {
      return msg;
    }
    else {
      am_addr_t addr, source;
      len = call UartPacket.payloadLength(msg);
      addr = call UartAMPacket.destination(msg);
      source = call UartAMPacket.source(msg);

      call RadioPacket.clear(msg);
      call RadioAMPacket.setSource(msg, source);

      if (call RadioSend.send(addr, msg, len) == SUCCESS) {
        call Leds.led1Toggle();
        radioLocked = TRUE;
      }
      else {
        failBlink();
      }      
    }
    return msg;
  }

  event void RadioSend.sendDone(message_t* msg, error_t error) {
    if (error != SUCCESS)
      failBlink();
    radioLocked = FALSE;
  }
}
