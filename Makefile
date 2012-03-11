PROG=moonlime
LPROG=$(PROG)-loc
OBJS=mllexgen.o utils.o regex.o fa.o tmlexgen.o

SAMPLES=sample01-hexdump sample02-testregexes sample03-testNFAregexes
SAMPLES+= sample04-teststates

CC=gcc
CFLAGS=-Wall -Werror

ASCIIDOC=asciidoc
A2X=a2x

INSTALL=install

# Install directories
PREFIX=/usr/local
BINDIR=$(PREFIX)/bin
SHAREDIR=$(PREFIX)/share/moonlime
DOCDIR=$(PREFIX)/share/doc/moonlime
MANDIR=$(PREFIX)/share/man/man1


local: $(LPROG)

all: $(PROG)

.PHONY: local all bootstrap-prep samples doc install install-all clean

.PRECIOUS: %.c

$(LPROG): main-loc.o $(OBJS)
	$(CC) -o $@ main-loc.o $(OBJS)

$(PROG): main.o $(OBJS)
	$(CC) -o $@ main.o $(OBJS)

.c.o:
	$(CC) -c $(CFLAGS) -o $@ -D"SHAREDIR=\"$(SHAREDIR)\"" $<

main-loc.o: main.c mllexgen.h utils.h fa.h tmlexgen.h
	$(CC) -c $(CFLAGS) -o $@ -D"SHAREDIR=\"$$(pwd)\"" main.c

fa.o: utils.h regex.h fa.h
main.o: mllexgen.h utils.h fa.h tmlexgen.h
mllexgen.o: utils.h regex.h
regex.o: utils.h regex.h
tmlexgen.o: utils.h fa.h mllexgen.h
utils.o: utils.h

bootstrap-prep: ml-lexer.c tmpl-lex.c

ml-lexer.c: ml-lexer.l $(LPROG) tmpl.c tmpl.h
	./$(LPROG) $< -o $@ -i

tmpl-lex.c: tmpl-lex.l $(LPROG) tmpl.c tmpl.h
	./$(LPROG) $< -o $@ -i

samples: $(SAMPLES) rpn

$(SAMPLES): %: %.o sample-runner.o
	$(CC) -o $@ $< sample-runner.o

rpn: rpn.o
	$(CC) -o $@ $<

sample01-hexdump.c sample02-testregexes.c sample03-testNFAregexes.c \
  sample04-teststates.c rpn.c: %.c: %.l $(LPROG) tmpl.c
	./$(LPROG) $< -o $@

doc: moonlime.html moonlime.1

moonlime.html: moonlime.txt rpn.l
	$(ASCIIDOC) -b html -o $@ $<

moonlime.1: moonlime.txt rpn.l
	$(A2X) -f manpage $<

install: all
	$(INSTALL) $(PROG) $(BINDIR)
	mkdir -p $(SHAREDIR)
	$(INSTALL) tmpl.c $(SHAREDIR)
	$(INSTALL) tmpl.h $(SHAREDIR)

install-all: install doc
	mkdir -p $(MANDIR) $(DOCDIR)
	$(INSTALL) moonlime.1 $(MANDIR)
	$(INSTALL) moonlime.html $(DOCDIR)

clean:
	rm -f $(PROG) $(SAMPLES) sample[0-9]*.c *-lex*.[ch] *.o *.html *.1
	rm -f $(LPROG) rpn rpn.c
