cmake_minimum_required(VERSION 3.31)

project(Snake)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_BUILD_TYPE DEBUG)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(FetchContent)
set(RAYLIB_VERSION 5.5)

FetchContent_Declare(
    raylib
    URL https://github.com/raysan5/raylib/archive/refs/tags/${RAYLIB_VERSION}.tar.gz 
    FIND_PACKAGE_ARGS ${RAYLIB_VERSION} EXACT
)

set(BUILD_EXAMPLES OFF CACHE INTERNAL "")

FetchContent_MakeAvailable(raylib)

add_executable(${CMAKE_PROJECT_NAME} main.cpp)

target_link_libraries(
    ${CMAKE_PROJECT_NAME}
    raylib
)
