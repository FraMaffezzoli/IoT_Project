

#include "Timer.h"
#include "printf.h"
#include "Project1.h"

module Project1C @safe()
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
			call MilliTimer.startPeriodic(500);		//timer of 500ms for sending messages
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
	

event void MilliTimer.fired()	
	{   
	
	broadcastMsg_t* message = (broadcastMsg_t*)call Packet.getPayload(&packet, sizeof(broadcastMsg_t));
	if (locked) {
    	return;
    }

	if (TOS_NODE_ID == 1){
		message->ID = 23401;
		}
	if (TOS_NODE_ID == 2){
		message->ID = 23402;
		}
	if (TOS_NODE_ID == 3){
		message->ID = 23403;
		}
	if (TOS_NODE_ID == 4){
		message->ID = 23404;
		}
	if (TOS_NODE_ID == 5){
		message->ID = 23405;
		}
	if (TOS_NODE_ID == 6){
		message->ID = 23406;
		}
		
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

		printf("Alarm! Near mote: %u\n", received->ID);
		printfflush();

	return bufPtr;
	}
	
	}
event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }
}
