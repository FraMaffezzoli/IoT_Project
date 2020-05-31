

#include "Timer.h"
#include "printf.h"
#include "Activity5.h"

module Activity5C @safe()
{
    uses interface Boot;
	uses interface Packet;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as AMControl;
	uses interface Timer<TMilli> as MilliTimer;
	uses interface Random;
}

implementation
{
	message_t packet;
	bool locked = FALSE;
	  
event void Boot.booted()
	{
		call AMControl.start();								//turns on the controller
	
	}
	
event void AMControl.startDone(error_t err) 
	{
    	if (err == SUCCESS) 
    	{
			if (TOS_NODE_ID == 2)
				call MilliTimer.startPeriodic(5000);
			if (TOS_NODE_ID == 3)
				call MilliTimer.startPeriodic(5000);		
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

	if (TOS_NODE_ID == 2){
		message->topic = 123;
		}
	if (TOS_NODE_ID == 3){
		message->topic = 246;
		
		}
	
	message->value = call Random.rand16() % 101;	
		
	if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(broadcastMsg_t)) == SUCCESS)
		{
		locked = TRUE;
      	}
	}
	
event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
	if (TOS_NODE_ID == 1){
		if (len != sizeof(broadcastMsg_t)) 			//check if received msg is correct
			{return bufPtr;}
		else
		{
			broadcastMsg_t* received = (broadcastMsg_t*) payload;

			printf(", %u, %u\n", received->topic, received->value);
			printfflush();

		return bufPtr;
		}
	}
}
event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }
}
