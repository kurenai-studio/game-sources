cmake_minimum_required(VERSION 3.12)

project(tetris LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Raylib library and header
find_library(RAYLIB_LIBRARY NAMES raylib REQUIRED)
find_path(RAYLIB_INCLUDE_DIR NAMES raylib.h REQUIRED)

# Executable
add_executable(tetris
    src/main.cpp
    src/canvas.cpp
    src/tetris.cpp
)

# Compiler warnings and debug information
target_compile_options(tetris PRIVATE
    -Wall
    -Wextra
    -g
)

# Project headers
target_include_directories(tetris PRIVATE
    include
    config
    ${RAYLIB_INCLUDE_DIR}
)

# Raylib
target_link_libraries(tetris PRIVATE
    ${RAYLIB_LIBRARY}
)

# 'make run' / 'cmake --build build --target run'
add_custom_target(run
    COMMAND tetris
    DEPENDS tetris
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    COMMENT "Building and running the game..."
)
