#include "Calculate.h"

configuration CalculateP{

}
implementation{
    components MainC;
    components LedsC;
    components CalculateC as App;
    components new TimerMilliC() as Timer0;
    components ActiveMessageC;
    components new AMSenderC(0) as TerminalSend;
    components new AMReceiverC(0) as TerminalReceive;
    components new AMSenderC(AM_NODE_TO_NODE) as NodeSend;
    components new AMReceiverC(AM_NODE_TO_NODE) as NodeReceive;
    App.Boot -> MainC;
    App.Leds -> LedsC;
    App.Timer0 -> Timer0;
    App.TerminalPacket -> TerminalSend;
    App.NodePacket -> NodeSend;
    App.AMControl -> ActiveMessageC;
    App.TerminalSender -> TerminalSend;
    App.TerminalReceiver -> TerminalReceive;
    App.NodeSender -> NodeSend;
    App.NodeReceiver -> NodeReceive;
    App.TerminalAck -> TerminalSend;
    App.NodeAck->NodeSend;
}