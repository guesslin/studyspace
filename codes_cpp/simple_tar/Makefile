SRCS 	:=	$(shell ls *.cpp)
OBJS	:=	$(SRCS:.cpp=.o)
EXEC	:=	mytar
CXXFLAGS += -Wall

ifdef DEBUG
CXXFLAGS += -D__DEBUG__ -ggdb
endif

all: $(EXEC)

$(EXEC):	$(OBJS) mytar.h
	$(CXX) -o $(EXEC) $(OBJS)
dep:
	$(CXX) -M $(SRCS) > .dep

-include .dep

clean:
	rm -rf *.o *.core $(OBJS) $(EXEC) .dep

