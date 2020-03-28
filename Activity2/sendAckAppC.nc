
#include "sendAck.h"

configuration sendAckAppC {}

implementation {

/****** COMPONENTS *****/
	components MainC, sendAckC as App;
	components new TimerMilliC() as msg_t;
	components new FakeSensorC();
	components ActiveMessageC;
	components new AMSenderC(AM_MY_MSG);
	components new AMReceiverC(AM_MY_MSG);

/****** INTERFACES *****/
	//Boot interface
	App.Boot -> MainC.Boot;

	//Timer interface
	App.MsgTimer -> msg_t;

	//Sensor read
	App.Read -> FakeSensorC.Read;

	//Radio Control
	App.SplitControl -> ActiveMessageC;
	App.AMSend -> AMSenderC;
	App.Packet -> AMSenderC;
	App.PacketAcknowledgements -> AMSenderC; 
	App.Receive -> AMReceiverC;

	//Fake Sensor read
	App.Read -> FakeSensorC;
	
}

