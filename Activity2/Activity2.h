#ifndef ACTIVITY2_H
#define ACTIVITY2_H

typedef nx_struct sensor_msg {
  nx_uint16_t type;
  nx_uint16_t counter;
  nx_uint16_t data;
} sensor_msg_t;

enum {
  AM_SEND_MSG = 6,
};

#endif
