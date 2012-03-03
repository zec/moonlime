PROG=moonlime
OBJS=ml-lexer.o main.o utils.o regex.o
HEADER_DEPS=utils.h regex.h

CC=gcc
CFLAGS=-Wall -Werror

all: $(PROG)

.PHONY: all clean

.PRECIOUS: .c

$(PROG): $(OBJS)
	$(CC) -o $@ $(OBJS)

.c.o: $(HEADER_DEPS)
	$(CC) -c $(CFLAGS) -o $@ $<

main.o: ml-lexer.c

.l.c:
	../moonlime $< -o $@ -i

clean:
	rm -f $(PROG) ml-lexer.[ch] *.o
