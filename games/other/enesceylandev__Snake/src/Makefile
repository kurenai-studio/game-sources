CC = gcc
CFLAGS = -Wall -Wextra -Iinclude -std=c99
LDFLAGS = -lraylib -lm -ldl -lpthread
SRCS = src/main.c
OBJS = $(SRCS:.c=.o)
TARGET = build/snake

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(CFLAGS) $(LDFLAGS) -o $(TARGET)

clean:
	rm -f $(OBJS) $(TARGET)

test:
	@echo "Running tests..."

