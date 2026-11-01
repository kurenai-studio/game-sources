main: main.o snake.o
	gcc -o main main.o snake.o -lraylib -lGL -lm -lpthread -ldl -lrt -lX11

main.o: main.c
	gcc -c main.c

snake.o: snake.c
	gcc -c snake.c
