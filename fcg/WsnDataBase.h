#ifndef WSN_DATA_BASE_H
#define WSN_DATA_BASE_H

typedef nx_struct wsn_data_msg {
  nx_uint16_t nodeId;
  nx_uint16_t counter;
  nx_uint16_t collectTime;
  nx_uint16_t sequenceNumber;
  nx_uint8_t type;  //0 : msg, 1 : command
  nx_uint16_t newTimePeriod;
} wsn_data_msg_t;

enum {  
  AM_WSN_DATA_BASE_RECEIVE_MSG = 0x90,
  AM_WSN_DATA_BASE_SEND_MSG = 0x88,
  AM_WSN_DATA_MSG = 0x66
};

#endif
