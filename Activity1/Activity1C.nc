

#include "Timer.h"
#include "Activity1.h"
#include "stdbool.h"

module Activity1C @safe()
{
	Interfaces
	uses interface Leds;
    uses interface Boot;
	uses interface Packet;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as AMControl;
}

implementation
{
	message_t packet;
	uint16_t counter = 1;
	bool led0 = false;
	bool led1 = false;
	bool led2 = false;
	
	event void Boot.booted()
	{
		call AMControl.start();								//turns on the controller
		if (TOS_NODE_ID == 1)
			call MilliTimer.startPeriodic(1000);			//set up a 1Hz timer
		if (TOS_NODE_ID == 2)
			call MilliTimer.startPeriodic(333);
		if (TOS_NODE_ID == 3)
			call MilliTimer.startPeriodic(200);			
	}
	
//send a message and react to your own message (es mote0 turns on and off led 0)
//Mote 0 has a node_id = 1

event void MilliTimer.fired()	
	{
	if (TOS_NODE_ID == 1)
	{
		if (led0 == false)
		{
			call Leds.led0On();
			led0 == true;
		}
		else
		{
			call Leds.led0Off();
			led0 = false;
		}
	}
	if (TOS_NODE_ID == 2)
	{
		if (led1 == false)
		{
			call Leds.led1On();
			led1 == true;
		}
		else
		{
			call Leds.led1Off();
			led1 = false;
		}
	}
	if (TOS_NODE_ID == 3)
	{
		if (led2 == false)
		{
			call Leds.led2On();
			led2 == true;
		}
		else
		{
			call Leds.led2Off();
			led2 = false;
		}
	}
		
		BroadcastMsg* message = (BroadcastMsg*) Packet.getPayload(&packet, sizeof(broadcastMsg));
		message.counter = counter;					//send a msg with node id and counter
		message.nodeID = TOS_NODE_ID;
		
		call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(broadcastMsg));
	}
	
event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len)
{
	if (len != sizeof(broadcastMsg)) 			//check if received msg is correct
		return bufPtr;
	else
	{
		broadcastMsg* received = (broadcastMsg*) payload;
		counter++;							//increase counter
		
		if (received.counter % 10 == 0)		//if the rest ofcounter/10 is 0, turn off leds
		{
			call Leds.led0Off();
			led0 = false;
			call Leds.led1Off();
			led1 = false;
			call Leds.led2Off();
			led2 = false;
		}
		else
		{
			if(received.nodeID == 1){			//selectively turn of leds depending on
				if led0 == true					//the sender of the message
					{
						led0 == false;
						call Leds.led0Off;
					}
				else
				{
					led0 == true;
					call Leds.led0On;
				}
			}
			if(received.nodeID == 2){			
				if led1 == true					
					{
						led1 == false;
						call Leds.led1Off;
					}
				else
				{
					led1 == true;
					call Leds.led1On;
				}
			}
			if(received.nodeID == 3){
				if led2 == true
					{
						led2 == false;
						call Leds.led2Off;
					}
				else
				{
					led2 == true;
					call Leds.led2On;
				}
			}	
		}
	}
}
