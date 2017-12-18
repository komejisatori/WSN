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
    components new AMReceiverC(AM_RADIO_TO_RADIO_MSG);
    components new SensirionSht11C() as Sensor1;
    components new HamamatsuS1087ParC() as Sensor2;

    
    App.Boot -> MainC;
    App.Leds -> LedsC;
    App.Timer -> Timer;
    App.Packet -> AMSenderC;
    App.AMPacket -> AMSenderC;
    App.AMControl -> ActiveMessageC;
    App.AMSend -> AMSenderC;
    App.Receive->AMReceiverC;
    App.ReadTemperature -> Sensor1.Temperature;
    App.ReadHumidity -> Sensor1.Humidity;
    App.ReadIllumination ->Sensor2;
}