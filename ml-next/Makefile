PROG=moonlime
OBJS=ml-lexer.o main.o utils.o regex.o fa.o tmpl-lex.o
HEADER_DEPS=utils.h regex.h fa.h

CC=gcc
CFLAGS=-Wall -Werror

all: $(PROG)

.PHONY: all clean

.PRECIOUS: %.c

$(PROG): $(OBJS)
	$(CC) -o $@ $(OBJS)

.c.o: $(HEADER_DEPS)
	$(CC) -c $(CFLAGS) -o $@ $<

fa.o: utils.h regex.h fa.h
main.o: ml-lexer.c utils.h fa.h tmpl-lex.c
ml-lexer.o: utils.h regex.h
regex.o: utils.h regex.h
tmpl-lex.o: utils.h fa.h ml-lexer.c
utils.o: utils.h

.l.c:
	../moonlime $< -o $@ -i

clean:
	rm -f $(PROG) *-lex*.[ch] *.o
