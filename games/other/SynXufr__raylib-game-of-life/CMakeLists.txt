cmake_minimum_required(VERSION 3.12)
project(raylib_game_of_life)

find_package(raylib 5.1)

set(CMAKE_CXX_STANDARD 20)

if (raylib_FOUND)
    add_executable(raylib_game_of_life src/main.cpp
            src/grid.cpp
            src/grid.h
            src/sidebar.cpp
            src/sidebar.h
    )

    target_link_libraries(${PROJECT_NAME} raylib)
endif()

# Unit tests
enable_testing()
add_executable(grid_tests tests/test_grid.cpp src/grid.cpp)
target_include_directories(grid_tests PRIVATE src)
add_test(NAME grid_tests COMMAND grid_tests)
