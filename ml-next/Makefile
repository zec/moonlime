PROG=moonlime
OBJS=ml-lexer.o main.o utils.o
HEADERS=utils.h ml-lexer.h

CC=gcc

all: $(PROG)

.PHONY: all clean

.PRECIOUS: .c

$(PROG): $(OBJS)
	$(CC) -o $@ $(OBJS)

.c.o: $(HEADERS)
	$(CC) -c -o $@ $<

.l.c:
	../moonlime $< -o $@ -i

ml-lexer.h: ml-lexer.c

clean:
	rm -f $(PROG) ml-lexer.[ch] *.o
