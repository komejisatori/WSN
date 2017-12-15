#include <Timer.h>
#include "WsnDataBase.h"

configuration WsnDataBaseAppC {}
implementation {
  components WsnDataBaseC as App, LedsC, MainC;
  components SerialActiveMessageC as Serial;
  components ActiveMessageC as Radio;

  App.Boot -> MainC.Boot;

  App.RadioControl -> Radio;
  App.RadioReceive -> Radio.Receive[AM_WSN_DATA_BASE_RECEIVE_MSG];
  App.RadioSend -> Radio.AMSend[AM_WSN_DATA_BASE_SEND_MSG];
  App.RadioPacket -> Radio;
  App.RadioAMPacket -> Radio;

  App.SerialControl -> Serial;
  App.UartSend -> Serial.AMSend[AM_WSN_DATA_MSG];
  App.UartReceive -> Serial.Receive[AM_WSN_DATA_MSG];
  App.UartPacket -> Serial;
  App.UartAMPacket -> Serial;

  App.Leds -> LedsC;
}
