#ifndef _CALCULATE_H_INC_
#define _CALCULATE_H_INC_

// structure from test program
enum{
    DATA_NUMBER = 2000,
    TIMER_PERIOD_MILLI = 10,
	STATUS_RECEIVE_TERMINAL = 0,
	STATUS_RECEIVE_NODE = 1,
	STATUS_CALCULATE = 2,
	STATUS_SEND = 3,
	STATUS_END = 4,
	AM_NODE_TO_NODE = 0x88
};
// self defined number

enum
{
	AM_DATA_PACKGE = 10,
	AM_CALCULATE_RESULT = 10
};

typedef nx_struct data_package
{
	nx_uint16_t sequence_number;
	nx_uint32_t random_integer;
} data_package;

typedef nx_struct data_require
{
	nx_uint16_t sequence_number;
}data_require;

typedef nx_struct calculate_result
{
	nx_uint8_t group_id;	//always be 10
	nx_uint32_t max;
	nx_uint32_t min;
	nx_uint32_t sum;
	nx_uint32_t average;
	nx_uint32_t median;
} calculate_result;

//(groupid-1)*3+1/2/3
//node id should be 28, 29, 30

enum
{
	TA_NUM_SOURCE = 1000,
	TA_NUM_DESTINATION = 0,

	CHAOS_GROUP_ID = 10,
	CHAOS_NODE_1 = 28,	//median, max, min. using heap sort
	CHAOS_NODE_2 = 29,	//sum, average. plus them up when receives
	CHAOS_NODE_3 = 30,	//use to look up data.
	
	DATA_ALL_NUM = 2000,
	BUFFER_LENGTH = 6,
};

enum DataType
{
	REQUIRE_DATA = 1,
	RESULT_RECEIVED = 3
};

typedef nx_struct data_transmit
{
	nx_uint8_t data_type;
	nx_uint16_t data_num;
} data_transmit;

#define _INDEX_1_TO_1000_

//#define _DEBUG_2_ALL_NODE_

#endif