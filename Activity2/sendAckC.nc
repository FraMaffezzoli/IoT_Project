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
		  
		counter++;
		mess->value = 0;
		mess->type = REQ;
		mess->counter = counter;

		dbg("radio_pack","Preparing the message... \n");

		if(call PacketAcknowledgements.requestAck(&packet) == SUCCESS) {
			dbg("radio_ack","Ack requested\n");
		}else{
			dbgerror("radio_ack","Ack request not supported\n");
		}

		if(call AMSend.send(2, &packet,sizeof(my_msg_t)) == SUCCESS) {
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
			if (TOS_NODE_ID == 1) {
				dbg("timer","Message timer start\n");
				call MsgTimer.startPeriodic( 1000 );
			}
		}else{
			call SplitControl.start();
		}
	}
  
  	event void SplitControl.stopDone(error_t err){
    /*empty event*/
    }

	//***************** MilliTimer interface ********************//
	event void MsgTimer.fired() {
		dbg("timer","Message timer fired at %s.\n", sim_time_string());
		sendReq();
	}
  

	//********************* AMSend interface ****************//
	event void AMSend.sendDone(message_t* buf,error_t err) {
		if (&packet == buf && err == SUCCESS) {
			dbg("radio_send", "Packet sent...");
			dbg_clear("radio_send", " at time %s \n", sim_time_string());
		}else{
			dbgerror("radio_send", "Send done error!");
		}
		if (call PacketAcknowledgements.wasAcked(buf) == TRUE && TOS_NODE_ID == 1){
			dbg("radio_ack", "Acknowledged packet\n");
			call MsgTimer.stop();
			dbg("timer","Message timer stop\n");
		}
	}

	//***************************** Receive interface *****************//
	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
		if (len != sizeof(my_msg_t)) {
			return buf;
		}else{
			my_msg_t* mess = (my_msg_t*)payload;

			dbg("radio_rec", "Received packet at time %s\n", sim_time_string());
			dbg("radio_pack"," Payload length %hhu \n", call Packet.payloadLength( buf ));
			dbg("radio_pack", ">>>Pack \n");
			dbg_clear("radio_pack","\t\t Payload Received\n" );
			dbg_clear("radio_pack", "\t\t counter: %hhu \n", mess->counter);	      
			dbg_clear("radio_pack", "\t\t type: %hhu \n ", mess->type);
			dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);

			rec_id = mess->counter;

			if(mess->type == REQ){
				sendResp();
			}
			  
			return buf;
		}
		dbgerror("radio_rec", "Receiving error \n");
	}
  
	//************************* Read interface **********************//
	event void Read.readDone(error_t result, uint16_t data) {
		my_msg_t* mess = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
		double value = ((double)data/65535)*100;
		if (mess == NULL) {
			return;
		}

		dbg("value","value read done %f\n",value);  	
	  
		mess->value = value;
		mess->type = RESP;
		mess->counter = rec_id;
	  
		dbg("radio_pack","Preparing the response... \n");

		if(call PacketAcknowledgements.requestAck(&packet) == SUCCESS){
			dbg("radio_ack","Ack requested\n");
		}else{
			dbgerror("radio_ack","Ack request not supported\n");
		}
	  
		if(call AMSend.send(1, &packet,sizeof(my_msg_t)) == SUCCESS){
			dbg("radio_send", "Packet passed to lower layer successfully!\n");
			dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
			dbg_clear("radio_pack","\t Payload Sent\n" );
			dbg_clear("radio_pack", "\t\t counter: %hhu \n", mess->counter);
			dbg_clear("radio_pack", "\t\t type: %hhu \n ", mess->type);
			dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
		}
	}
}

