#ifndef MESSAGE_H
#define MESSAGE_H

typedef nx_struct Msg{
    nx_uint16_t temperature;
    nx_uint16_t humidity;
    nx_uint16_t illumination;
}Msg;

enum {AM_MSG = 6};

#endif
