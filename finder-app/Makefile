#  Write a Makefile which includes:
#    - A default target which builds the “writer” application
#    - A clean target which removes the “writer” application and all .o files
#    - Support for cross-compilation.  
#	   You should be able to generate an application for the native build platform when GNU make variable 
#	   CROSS_COMPILE is not specified on the make command line.  When CROSS_COMPILE is specified with aarch64-none-linux-gnu- 
#	   (note the trailing -)your makefile should compile successfully using the cross compiler installed in step 1
# e.g 
#		Clean              : make clean
#		Native Build 	   : make
#		CROSS Compile Build: make CROSS_COMPILE=aarch64-none-linux-gnu-	
# Author: Ebenezer Olatuyi
# Date  :1-26-2024
CC := gcc
CFLAGS := -Wall -Wextra

ifeq ($(CROSS_COMPILE),aarch64-none-linux-gnu-)
	CC := $(CROSS_COMPILE)gcc
endif

.PHONY: all clean

all: writer

writer: writer.o
	$(CC) $(CFLAGS) -o $@ $^

writer.o: writer.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f writer writer.o
