#include <Timer.h>
#include "Myradio.h"

configuration MyradioAppC{

} 
implementation{
    components MainC;
    components LedsC;
    components MyradioC as App;
    components new TimerMilliC() as Timer;
    components ActiveMessageC;
    components new AMSenderC(AM_RADIO_TO_STATION_MSG) as PacketSend;
    components new AMSenderC(AM_RADIO_TO_RADIO_MSG) as ACKSend;
    components new AMReceiverC(AM_RADIO_TO_RADIO_MSG);

    App.Boot -> MainC;
    App.Leds -> LedsC;
    App.Timer -> Timer;
    App.Packet -> PacketSend;
    App.AMPacket -> PacketSend;
    App.AMControl -> ActiveMessageC;
    App.PackSend -> PacketSend;
    App.ACKSend -> ACKSend;
    App.Receive -> AMReceiverC;
}