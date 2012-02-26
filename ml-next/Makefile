PROG=moonlime
OBJS=ml-lexer.o main.o utils.o
HEADER_DEPS=utils.h ml-lexer.c

CC=gcc

all: $(PROG)

.PHONY: all clean

.PRECIOUS: .c

$(PROG): $(OBJS)
	$(CC) -o $@ $(OBJS)

.c.o: $(HEADER_DEPS)
	$(CC) -c -o $@ $<

.l.c:
	../moonlime $< -o $@ -i

clean:
	rm -f $(PROG) ml-lexer.[ch] *.o
