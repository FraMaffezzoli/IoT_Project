/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"
#include "Timer.h"

module sendAckC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	
	interface SplitControl;
	interface Packet;
	interface PacketAcknowledgements;
    interface AMSend;
    interface Receive;
    
    interface Timer<TMilli> as MsgTimer;
    
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t counter=0;
  uint8_t rec_id;
  message_t packet;

  void sendReq();
  void sendResp();
  
  
  //***************** Send request function ********************//
  void sendReq() {
  	my_msg_t* mess = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	  if (mess == NULL) {
		return;
	  }
	  
	  counter++
	  mess->value = 0;
	  mess->type = "REQ";
	  mess->counter = counter;
	  
	  dbg("radio_pack","Preparing the message... \n");
	  
  	  if(call PacketAcknowledgements.requestAck(&mess) == SUCCESS)
  	  {
  	  dbg("radio_ack","Ack requested\n");
  	  }
  	  else{
  	  dbg_error("radio_ack","Ack request not supported\n");
  	  }
  	  
  	  if(call AMSend.send(2, &packet,sizeof(my_msg_t)) == SUCCESS){
	     dbg("radio_send", "Packet passed to lower layer successfully!\n");
	     dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	     dbg_clear("radio_pack","\t Payload Sent\n" );
	     dbg_clear("radio_pack", "\t\t counter: %hhu \n", mess->counter);
		 dbg_clear("radio_pack", "\t\t type: %hhu \n ", mess->type);
		 dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
	}
 }        

  //****************** Task send response *****************//
  void sendResp() {
	call Read.read();
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
    if(err == SUCCESS) {
    	dbg("radio", "Radio on!\n");
	if (TOS_NODE_ID == 1){
		   dbg("timer","Message timer stop\n");
           call MsgTimer.startPeriodic( 1000 );
  	}
    }
    else{
	//dbg for error
	call SplitControl.start();
    }
  }
  
  event void SplitControl.stopDone(error_t err){
    /*empty event*/
      }

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
   	dbg("timer","Message timer fired at %s.\n", sim_time_string());
  	sendReq();
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
   if (&packet == buf && error == SUCCESS) {
      dbg("radio_send", "Packet sent...");
      dbg_clear("radio_send", " at time %s \n", sim_time_string());
    }
    else{
      dbgerror("radio_send", "Send done error!");
    }
    if (call PacketAcknowledgements.wasAcked(&buf) == TRUE && TOS_NODE_ID == 1){
      dbg("radio_ack", "Packet acknowlegde\n");
      call MsgTimer.stop();
      dbg("timer","Message timer stop\n");
  }
  
	/* This event is triggered when a message is sent 
	 *
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, stop the timer. The program is done
	 * 2b. Otherwise, send again the request
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	
	    if (len != sizeof(my_msg_t)) {return bufPtr;}
    else {
      my_msg_t* mess = (my_msg_t*)payload;
      
      dbg("radio_rec", "Received packet at time %s\n", sim_time_string());
      dbg("radio_pack"," Payload length %hhu \n", call Packet.payloadLength( bufPtr ));
      dbg("radio_pack", ">>>Pack \n");
      dbg_clear("radio_pack","\t\t Payload Received\n" );
	  dbg_clear("radio_pack", "\t\t counter: %hhu \n", mess->counter);	      
      dbg_clear("radio_pack", "\t\t type: %hhu \n ", mess->type);
	  dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
	  
	  rec_id = mess->counter;

		if(mess->type == "REQ"){
		  sendResp();
		  }
		  
		return bufPtr;
		
	    }
		{
		  dbgerror("radio_rec", "Receiving error \n");
		}
	  }
	
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */

  }
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
		double value = ((double)data/65535)*100;
	dbg("value","value read done %f\n",value);
	
  	my_msg_t* mess = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	  if (mess == NULL) {
		return;
	  }
	  
	  mess->value = value;
	  mess->type = "RESP";
	  mess->counter = rec_id;
	  
	  dbg("radio_pack","Preparing the response... \n");
	  
	  if(call PacketAcknowledgements.requestAck(&mess) == SUCCESS)
  	  {
  	  dbg("radio_ack","Ack requested\n");
  	  }
  	  else{
  	  dbg_error("radio_ack","Ack request not supported\n");
  	  }
	  
	if(call AMSend.send(1, &packet,sizeof(my_msg_t)) == SUCCESS){
	  dbg("radio_send", "Packet passed to lower layer successfully!\n");
	  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	  dbg_clear("radio_pack","\t Payload Sent\n" );
	  dbg_clear("radio_pack", "\t\t counter: %hhu \n", mess->counter);
	  dbg_clear("radio_pack", "\t\t type: %hhu \n ", mess->type);
	  dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
	}
	/* This event is triggered when the fake sensor finish to read (after a Read.read()) 
	 *
	 * STEPS:
	 * 1. Prepare the response (RESP)
	 * 2. Send back (with a unicast message) the response
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */

}

