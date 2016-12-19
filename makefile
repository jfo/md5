CFLAGS = -Wall -Werror -g
CC = cc
vpath %.c src

main: src/main.c src/md5.o
	$(CC) $(CFLAGS) -o main src/md5.o src/main.c

md5.o: src/md5.c
	$(CC) $(CFLAGS) src/md5.c -c

.PHONY:
clean:
	rm main*


