/*
 * Copyright (c) 2006, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2006/12/12 18:22:49 $
 * @author: Jan Hauer
 * ========================================================================
 */

/**
 * 
 * Sensing demo application. See README.txt file in this directory for usage
 * instructions and have a look at tinyos-2.x/doc/html/tutorial/lesson5.html
 * for a general tutorial on sensing in TinyOS.
 *
 * @author Jan Hauer
 */

#include "Timer.h"
#include "Message.h"

#define TIMER_PERIOD 1000

module MySenseC
{
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli>;
    interface Read<uint16_t> as ReadTemperature;
    interface Read<uint16_t> as ReadHumidity;
    interface Read<uint16_t> as ReadIllumination;
    interface Packet;
    interface AMSend;
    interface SplitControl as RadioControl;
  }
}
implementation
{
  bool busy;
  message_t pkt;
  Msg* payload;
  
  event void Boot.booted() {
    busy = FALSE;
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call Timer.startPeriodic(TIMER_PERIOD);
    }
    else {
      call RadioControl.start();
    }
  }

  event void RadioControl.stopDone(error_t err) {
  }

  event void Timer.fired() 
  {
    call ReadTemperature.read();
    call ReadHumidity.read();
    call ReadIllumination.read();
  }

  event void ReadTemperature.readDone(error_t result, uint16_t data) 
  {
    if (result == SUCCESS) {
      if (busy == FALSE) {
        payload = (Msg*)(call Packet.getPayload(&pkt, sizeof(Msg)));
        if (payload == NULL) {
          return;
        }
        payload->temperature = -40.1 + 0.01 * data;
        call Leds.led0Toggle();
      }
    }
  }

  event void ReadHumidity.readDone(error_t result, uint16_t data) 
  {
    if (result == SUCCESS) {
      if (busy == FALSE) {
        payload->humidity = -4 + 4 * data / 100 + (-28 / 1000 / 10000) * (data * data);
        payload->humidity += (payload->temperature - 25) * (1 / 100 + 8 * data / 100 / 1000);
        call Leds.led1Toggle();
      }
    }
  }

  event void ReadIllumination.readDone(error_t result, uint16_t data) 
  {
    if (result == SUCCESS) {
      if (busy == FALSE) {
        payload->illumination = data;
        if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(Msg)) == SUCCESS) {
          busy = TRUE;
        }
        call Leds.led2Toggle();
      }
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
      call Leds.led0Toggle();
      call Leds.led1Toggle();
      call Leds.led2Toggle();
      busy = FALSE;
    }
  }
}