CXX = g++

CXXFLAGS = -std=c++17 -Iinclude -Isrc
LDFLAGS = -Llib
LIBS = -lraylib

TARGET = sokoban
SOURCES = src/main.cpp src/direction.cpp src/map.cpp src/player.cpp src/game.cpp

DEL_CMD = rm

ifeq ($(OS),Windows_NT)
	LIBS += -lgdi32 -lwinmm
	TARGET = sokoban.exe
	DEL_CMD = del
endif

$(TARGET): $(SOURCES)
	$(CXX) -o $(TARGET) $(SOURCES) $(CXXFLAGS) $(LDFLAGS) $(LIBS)

clean:
	$(DEL_CMD) $(TARGET)
