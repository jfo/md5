CFLAGS = -Wall -Werror -g
CC = cc
vpath %.c src

main: src/main.c md5.o
	$(CC) $(CFLAGS) -o main md5.o src/main.c

md5.o: src/md5.c
	$(CC) $(CFLAGS) src/md5.c -c

opencl:  src/hello.c
	$(CC) -o hello src/hello.c -framework opencl


.PHONY:
clean:
	rm -r main* 
	rm src/*.o 

runcl: opencl
	./hello

run: main
	./main
