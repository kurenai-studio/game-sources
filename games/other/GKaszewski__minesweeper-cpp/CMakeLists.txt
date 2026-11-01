cmake_minimum_required(VERSION 3.27)

project(minesweeper CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(SOURCES 
    main.cpp
    MinesweeperGame.cpp
    RaylibRenderer.cpp
    RaylibApp.cpp
)

if(EMSCRIPTEN)
    # Web Build: Output .html instead of .exe
    add_executable(${PROJECT_NAME} ${SOURCES})
    set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".html")
    
    # Emscripten specific flags (Shell file is optional but recommended for custom styling)
    target_link_options(${PROJECT_NAME} PRIVATE 
        "-sUSE_GLFW=3"
        "-sWASM=1"
        "-sALLOW_MEMORY_GROWTH=1"
    )
    # Define PLATFORM_WEB so your main.cpp knows to switch to runOneFrame
    target_compile_definitions(${PROJECT_NAME} PRIVATE PLATFORM_WEB)
else()
    # Desktop Build
    # WIN32 hides the console window on launch (remove if you want to see printf debugs)
    add_executable(${PROJECT_NAME} WIN32 ${SOURCES})
    
    # Only use static-libgcc if using GCC/MinGW
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_link_options(${PROJECT_NAME} PRIVATE "-static-libgcc" "-static-libstdc++")
    endif()
endif()

target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/include)

# raylib library
include(FetchContent)
set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE) # don't build the supplied examples
set(BUILD_GAMES    OFF CACHE BOOL "" FORCE) # don't build the supplied example games

if(EMSCRIPTEN)
    set(PLATFORM "Web" CACHE STRING "Raylib build platform" FORCE)
    set(GRAPHICS "GRAPHICS_API_OPENGL_ES2" CACHE STRING "Graphics API" FORCE)
endif()

FetchContent_Declare(raylib GIT_REPOSITORY https://github.com/raysan5/raylib.git GIT_TAG 5.5)
FetchContent_MakeAvailable(raylib)
target_link_libraries(${PROJECT_NAME} PRIVATE raylib)

if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /W3)
    target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Release>:/O2>)
else()
    target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra)
    target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Release>:-O3>)
endif()

target_compile_definitions(${PROJECT_NAME} PRIVATE $<$<CONFIG:Debug>:DEBUG>)

include(CheckIPOSupported)
check_ipo_supported(RESULT result OUTPUT output)

if(result)
    # This enables "whole program optimization"
    set_property(TARGET ${PROJECT_NAME} PROPERTY INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
else()
    message(WARNING "LTO not supported: ${output}")
endif()

# Strip symbols in Release (Linux/Mac/Web) to reduce file size
if(NOT MSVC AND CMAKE_BUILD_TYPE STREQUAL "Release")
    target_link_options(${PROJECT_NAME} PRIVATE -s)
endif()