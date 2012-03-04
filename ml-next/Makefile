PROG=moonlime
OBJS=ml-lexer.o main.o utils.o regex.o fa.o
HEADER_DEPS=utils.h regex.h fa.h

CC=gcc
CFLAGS=-Wall -Werror

all: $(PROG)

.PHONY: all clean

.PRECIOUS: .c

$(PROG): $(OBJS)
	$(CC) -o $@ $(OBJS)

.c.o: $(HEADER_DEPS)
	$(CC) -c $(CFLAGS) -o $@ $<

fa.o: utils.h regex.h fa.h
main.o: ml-lexer.c utils.h fa.h
ml-lexer.o: utils.h regex.h
regex.o: utils.h regex.h
utils.o: utils.h

.l.c:
	../moonlime $< -o $@ -i

clean:
	rm -f $(PROG) ml-lexer.[ch] *.o
