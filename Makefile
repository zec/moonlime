PROG=moonlime
OBJS=ml-lexer.o main.o utils.o regex.o fa.o tmpl-lex.o
HEADER_DEPS=utils.h regex.h fa.h

SAMPLES=sample01-hexdump sample02-testregexes sample03-testNFAregexes
SAMPLES+= sample04-teststates

CC=gcc
CFLAGS=-Wall -Werror

all: $(PROG)

.PHONY: all samples clean

.PRECIOUS: %.c

$(PROG): $(OBJS)
	$(CC) -o $@ $(OBJS)

.c.o:
	$(CC) -c $(CFLAGS) -o $@ $<

fa.o: utils.h regex.h fa.h
main.o: ml-lexer.c utils.h fa.h tmpl-lex.c
ml-lexer.o: utils.h regex.h
regex.o: utils.h regex.h
tmpl-lex.o: utils.h fa.h ml-lexer.c
utils.o: utils.h

ml-lexer.c: ml-lexer.l
	ml-old/moonlime $< -o $@ -i

tmpl-lex.c: tmpl-lex.l
	ml-old/moonlime $< -o $@ -i

samples: $(SAMPLES)

$(SAMPLES): %: %.o sample-runner.o
	$(CC) -o $@ $< sample-runner.o

sample01-hexdump.c sample02-testregexes.c sample03-testNFAregexes.c \
  sample04-teststates.c: %.c: %.l $(PROG) tmpl.c
	./$(PROG) $< -o $@

clean:
	rm -f $(PROG) $(SAMPLES) sample[0-9]*.c *-lex*.[ch] *.o
