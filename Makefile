SAMPLES=sample01-hexdump sample02-testregexes sample03-testNFAregexes
CC=gcc
LUAFILES=moonlime limeparse.lua limefa.lua limegen.lua limeutil.lua

all: $(SAMPLES)

.PHONY: all clean

.PRECIOUS: %.c

$(SAMPLES): %: %.o sample-runner.o
	$(CC) -o $@ $< sample-runner.o

%.o: %.c
	$(CC) -c -o $@ $<

%.c: %.l $(LUAFILES)
	./moonlime $< -o $@

clean:
	rm -f tmp.* *.o $(SAMPLES) sample[0-9]*.c
