#include "Calculate.h"

configuration CalculateP{

}
implementation{
    components MainC;
    components LedsC;
    components CalculateC as App;
    components ActiveMessageC;
    components new AMSenderC(10) as TerminalSend;
    components new AMReceiverC(10) as TerminalReceive;
    components new AMSenderC(AM_NODE_TO_NODE) as NodeSend;
    components new AMReceiverC(AM_NODE_TO_NODE) as NodeReceive;
    App.Boot -> MainC;
    App.Leds -> LedsC;
    App.TerminalPacket -> TerminalSend;
    App.NodePacket -> NodeSend;
    App.AMControl -> ActiveMessageC;
    App.TerminalSender -> TerminalSend;
    App.TerminalReceiver -> TerminalReceive;
    App.NodeSender -> NodeSend;
    App.NodeReceiver -> NodeReceive;
}