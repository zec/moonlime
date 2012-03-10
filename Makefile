PROG=moonlime
OBJS=mllexgen.o main.o utils.o regex.o fa.o tmlexgen.o
HEADER_DEPS=utils.h regex.h fa.h

SAMPLES=sample01-hexdump sample02-testregexes sample03-testNFAregexes
SAMPLES+= sample04-teststates

CC=gcc
CFLAGS=-Wall -Werror

all: $(PROG)

.PHONY: all bootstrap-prep samples clean

.PRECIOUS: %.c

$(PROG): $(OBJS)
	$(CC) -o $@ $(OBJS)

.c.o:
	$(CC) -c $(CFLAGS) -o $@ $<

fa.o: utils.h regex.h fa.h
main.o: mllexgen.h utils.h fa.h tmlexgen.h
mllexgen.o: utils.h regex.h
regex.o: utils.h regex.h
tmlexgen.o: utils.h fa.h mllexgen.h
utils.o: utils.h

bootstrap-prep: ml-lexer.c tmpl-lex.c

ml-lexer.c: ml-lexer.l $(PROG)
	./$(PROG) $< -o $@ -i

tmpl-lex.c: tmpl-lex.l $(PROG)
	./$(PROG) $< -o $@ -i

samples: $(SAMPLES)

$(SAMPLES): %: %.o sample-runner.o
	$(CC) -o $@ $< sample-runner.o

sample01-hexdump.c sample02-testregexes.c sample03-testNFAregexes.c \
  sample04-teststates.c: %.c: %.l $(PROG) tmpl.c
	./$(PROG) $< -o $@

clean:
	rm -f $(PROG) $(SAMPLES) sample[0-9]*.c *-lex*.[ch] *.o
