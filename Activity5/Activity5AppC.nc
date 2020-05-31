#include "Activity5.h"
#include "printf.h"

configuration Activity5AppC {}
implementation {
  components MainC, Activity5C as App;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components new TimerMilliC();
  components PrintfC;
  components SerialStartC;
  components ActiveMessageC;
  components RandomC;
  
  App.Boot -> MainC.Boot;
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.MilliTimer -> TimerMilliC;
  App.Packet -> AMSenderC;
  App.Random -> RandomC;
}

