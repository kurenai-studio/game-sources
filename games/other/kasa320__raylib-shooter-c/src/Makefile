# コンパイラと基本設定
CC      = gcc
EXT     = 
TARGET  = game
SRCS    = main.c utils.c scene_menu.c scene_1v5.c
OBJS    = $(SRCS:.c=.o)

# 基本フラグ (デバッグ情報 -g を追加)
CFLAGS  = -Wall -Wextra -g -O0
LDFLAGS = 

# OS判別とライブラリ設定
UNAME_S := $(shell uname -s)

# macOS
ifeq ($(UNAME_S), Darwin)
    CFLAGS  += -I/opt/homebrew/include -I/usr/local/include -I.
    LDFLAGS += -L/opt/homebrew/lib -L/usr/local/lib
    LDLIBS   = -lraylib -framework IOKit -framework Cocoa -framework OpenGL

# Windows
else ifneq (,$(findstring MINGW,$(UNAME_S)))
    EXT      = .exe
    # raylibのインストールパスが特殊な場合は -Iや-Lで指定してください
    # 例: CFLAGS += -I C:/raylib/include
    # 例: LDFLAGS += -L C:/raylib/lib
    LDLIBS   = -lraylib -lopengl32 -lgdi32 -lwinmm

# Linux
else
    CFLAGS  += -I/usr/local/include -I/usr/include
    LDFLAGS += -L/usr/local/lib -L/usr/lib
    LDLIBS   = -lraylib -lGL -lm -lpthread -ldl -lrt -lX11
endif

TARGET_NAME = $(TARGET)$(EXT)

# ビルドルール
all: $(TARGET_NAME)

$(TARGET_NAME): $(OBJS)
	$(CC) $(OBJS) -o $(TARGET_NAME) $(LDFLAGS) $(LDLIBS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# 掃除用
clean:
	rm -f $(TARGET_NAME) $(OBJS)

.PHONY: all clean