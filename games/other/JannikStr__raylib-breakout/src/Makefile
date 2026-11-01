
COMPILER=/opt/homebrew/bin/gcc-14
LIBS="$(shell pkg-config --libs raylib)"
FLAGS="$(shell pkg-config --cflags raylib)"

FILES=src/main.c src/player.c src/game.c

build:
	${COMPILER} ${FILES} $(shell pkg-config --libs raylib) $(shell pkg-config --cflags raylib) -o breakout

clean:
	rm breakout

run: build
	./breakout
