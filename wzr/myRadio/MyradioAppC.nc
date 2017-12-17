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
    components new AMSenderC(AM_RADIO_TO_RADIO_MSG);
    
    App.Boot -> MainC;
    App.Leds -> LedsC;
    App.Timer -> Timer;
    App.Packet -> AMSenderC;
    App.AMPacket -> AMSenderC;
    App.AMControl -> ActiveMessageC;
    App.AMSend -> AMSenderC;
}