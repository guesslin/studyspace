SRCS := m1.c
OBJS := $(SRCS:.c=.o)
EXEC := math

all: $(OBJS)
	$(CC) -lm -o $(EXEC) $(OBJS)

clean:
	rm -rf $(OBJS) $(EXEC)
