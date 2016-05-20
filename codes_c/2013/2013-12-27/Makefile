SRCS := main.c
OBJS := $(SRCS:.c=.o)
EXEC := main

sinclude .dep

CFLAGS += -g -O -Wall

all: $(EXEC)

$(EXEC): $(OBJS)

dep:
	$(CC) -M $(SRCS) >.dep


clean:
	rm -rf $(OBJS) $(EXEC) .dep *.s *.core
