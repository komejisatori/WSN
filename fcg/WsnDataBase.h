#ifndef WSN_DATA_BASE_H
#define WSN_DATA_BASE_H

typedef nx_struct wsn_data_msg {
  nx_uint16_t nodeId;
  nx_uint16_t temperature;
  nx_uint16_t humidity;
  nx_uint16_t illumination;
  nx_uint32_t collectTime;
  nx_uint16_t sequenceNumber;
  nx_uint16_t type;
  nx_uint16_t newTimerPeriod;
} wsn_data_msg_t;

enum {  
  AM_WSN_DATA_BASE_RECEIVE_MSG = 0x90,
  AM_WSN_DATA_BASE_SEND_MSG = 0x90,
  AM_WSN_DATA_MSG = 0x66
};

#endif
