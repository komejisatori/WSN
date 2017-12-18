#include <Timer.h>
#include "Myradio.h"

configuration MyradioAppC{

} 
implementation{
    components MainC;
    components LedsC;
    components MyradioC as App;
    components new TimerMilliC() as Timer1;
    components new TimerMilliC() as Timer2;
    components ActiveMessageC;
    components new AMSenderC(AM_RADIO_TO_STATION_MSG) as PacketSend;
    components new AMSenderC(AM_RADIO_TO_RADIO_MSG) as ACKSend;
    components new AMReceiverC(AM_RADIO_TO_RADIO_MSG);
    components new SensirionSht11C() as Sensor1;
    components new HamamatsuS1087ParC() as Sensor2;

    App.Boot -> MainC;
    App.Leds -> LedsC;
    App.Timer1 -> Timer1;
    App.Timer2 -> Timer2;
    App.Packet -> PacketSend;
    App.AMPacket -> PacketSend;
    App.AMControl -> ActiveMessageC;
    App.PackSend -> PacketSend;
    App.ACKSend -> ACKSend;
    App.Receive -> AMReceiverC;
    App.ReadTemperature -> Sensor1.Temperature;
    App.ReadHumidity -> Sensor1.Humidity;
    App.ReadIllumination ->Sensor2;
}