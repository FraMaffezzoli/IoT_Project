

#include "Timer.h"
#include "Activity1.h"

module Activity1C @safe()
{
	uses interface Leds;
    uses interface Boot;
	uses interface Packet;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as AMControl;
	uses interface Timer<TMilli> as MilliTimer;
}

implementation
{
	message_t packet;
	uint16_t counter = 0;
	bool locked = FALSE;
	  
event void Boot.booted()
	{
		call AMControl.start();								//turns on the controller
	
	}
	
event void AMControl.startDone(error_t err) 
	{
    	if (err == SUCCESS) 
    	{
			if (TOS_NODE_ID == 1)
				call MilliTimer.startPeriodic(1000);			//set up a 1Hz timer
			if (TOS_NODE_ID == 2)
				call MilliTimer.startPeriodic(333);
			if (TOS_NODE_ID == 3)
				call MilliTimer.startPeriodic(200);		
    	}
    	else
    	{
      		call AMControl.start();
    	}
  	}

event void AMControl.stopDone(error_t err) 
	{
    // do nothing
  	}
	
//send a message and react to your own message (es mote0 turns on and off led 0)
//Mote 0 has a node_id = 1

event void MilliTimer.fired()	
	{   
	
	broadcastMsg_t* message = (broadcastMsg_t*)call Packet.getPayload(&packet, sizeof(broadcastMsg_t));
	if (locked) {
    	return;
    }
    dbg("wee");
    if (TOS_NODE_ID == 1){
		call Leds.led0Toggle();
		}
	if (TOS_NODE_ID == 2){
		call Leds.led1Toggle();
		}
	if (TOS_NODE_ID == 3){
		call Leds.led2Toggle();
		}
		message->counter = counter;					//send a msg with node id and counter
		message->nodeID = TOS_NODE_ID;
		
	if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(broadcastMsg_t)) == SUCCESS)
		{
		locked = TRUE;
      	}
	}
	
event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
	if (len != sizeof(broadcastMsg_t)) 			//check if received msg is correct
		{return bufPtr;}
	else
	{
		broadcastMsg_t* received = (broadcastMsg_t*) payload;

		counter++;							//increase counter
		
		if (received->counter % 10 == 0)		//if the rest ofcounter/10 is 0, turn off leds
		{
			call Leds.led0Off();
			call Leds.led1Off();
			call Leds.led2Off();
		}
		else
		{
			if(received->nodeID == 1){			//selectively turn of leds depending on
				call Leds.led0Toggle();				//the sender of the message
			}
			if(received->nodeID == 2){			
				call Leds.led1Toggle();
			}
			if(received->nodeID == 3){
				call Leds.led2Toggle();
			}	
		}
	}
}
event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }
}
