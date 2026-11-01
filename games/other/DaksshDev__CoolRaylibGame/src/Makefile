CXX = g++
CXXFLAGS = -I/mingw64/include -Iinclude
LDFLAGS = -L/mingw64/lib -lraylib -lopengl32 -lgdi32 -lwinmm

SRC = src/main.cpp src/game.cpp src/physics.cpp src/ui.cpp
OUT = build/game.exe

all: $(OUT)

$(OUT): $(SRC) game_res.o
	$(CXX) $(SRC) game_res.o -o $(OUT) $(CXXFLAGS) $(LDFLAGS)
	cp game.ico build/ 2>/dev/null || true

game_res.o: game.rc game.ico game16.ico game32.ico game48.ico
	windres game.rc -o game_res.o

run: all
	./$(OUT)

clean:
	rm -f build/*.exe game_res.o
