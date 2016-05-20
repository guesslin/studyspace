SRCS := $(shell ls *.c)
OBJS := $(SRCS:.c=.o)
EXEC := main
CC   := clang

all: $(OBJS)
	$(CC) $(OBJS) -o $(EXEC)

clean:
	@rm -rf $(OBJS) $(EXEC)
