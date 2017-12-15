COMPONENT=WsnDataBaseAppC
BUILD_EXTRA_DEPS += WsnDataBase.class
CLEAN_EXTRA = *.class WsnDataBaseMsg.java

CFLAGS += -I$(TOSDIR)/lib/T2Hack

WsnDataBase.class: $(wildcard *.java) WsnDataBaseMsg.java
	javac -target 1.4 -source 1.4 *.java

WsnDataBaseMsg.java:
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=WsnDataBaseMsg WsnDataBase.h wsn_data_msg -o $@


include $(MAKERULES)

