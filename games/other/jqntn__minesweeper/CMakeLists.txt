cmake_minimum_required(VERSION 3.15)

project(minesweeper LANGUAGES C)

set(CMAKE_MSVC_RUNTIME_LIBRARY "$<$<NOT:$<CONFIG:Debug>>:MultiThreaded>")

add_executable(minesweeper "minesweeper.c")

set_property(TARGET minesweeper PROPERTY C_STANDARD 99)
set_property(TARGET minesweeper PROPERTY C_STANDARD_REQUIRED ON)
set_property(TARGET minesweeper PROPERTY C_EXTENSIONS OFF)

include(FetchContent)
set(FETCHCONTENT_QUIET OFF)
FetchContent_Declare(raylib URL "https://github.com/raysan5/raylib/archive/refs/tags/5.0.tar.gz")
FetchContent_MakeAvailable(raylib)

target_link_libraries(minesweeper PRIVATE raylib)
if (APPLE)
  target_link_libraries(minesweeper PRIVATE "-framework IOKit")
  target_link_libraries(minesweeper PRIVATE "-framework Cocoa")
  target_link_libraries(minesweeper PRIVATE "-framework OpenGL")
endif()

target_compile_options(minesweeper PRIVATE "-Wall")
if(MSVC)
  target_link_options(minesweeper PRIVATE "$<$<NOT:$<CONFIG:Debug>>:LINKER:/SUBSYSTEM:WINDOWS,/ENTRY:mainCRTStartup>")
endif()