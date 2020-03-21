#ifndef RADIO_COUNT_TO_LEDS_H
#define RADIO_COUNT_TO_LEDS_H

typedef nx_struct broadcastMsg
{
	nx_uint16_t counter;
	nx_uint16_t nodeID;
}broadcastMsg_t;
enum {
  AM_RADIO_COUNT_MSG = 6,
};
#endif
