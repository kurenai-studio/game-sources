cmake_minimum_required(VERSION 3.29)
project(Pong)

set(CMAKE_CXX_STANDARD 20)

if(APPLE)
    set(SDL2_DIR "/opt/homebrew/lib/cmake/SDL2")
endif()
find_package(SDL2 REQUIRED)

find_package(glm REQUIRED)

add_executable(Pong main.cpp)

target_include_directories(Pong PRIVATE ${SDL2_INCLUDE_DIRS} ${GLM_INCLUDE_DIRS})
target_link_libraries(Pong PRIVATE SDL2::SDL2 glm::glm)