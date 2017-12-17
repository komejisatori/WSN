#ifndef MY_RADIO_H
#define MY_RADIO_H

typedef nx_struct my_radio_msg{
    nx_uint16_t nodeId;
    nx_uint16_t data;
    nx_uint16_t collectTime;
    nx_uint16_t sequenceNumber;
    nx_uint16_t type;
    nx_uint16_t newTimerPeriod;
}my_radio_msg;

enum{
    AM_RADIO_TO_RADIO_MSG = 0x92,
    AM_RADIO_TO_STATION_MSG = 0x90,
};

#endif