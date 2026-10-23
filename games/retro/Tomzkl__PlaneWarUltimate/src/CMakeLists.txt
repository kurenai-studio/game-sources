cmake_minimum_required(VERSION 3.16)
project(PlaneWarUltimate VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ── Raylib ──────────────────────────────────
# Users can set RAYLIB_PATH or let CMake find it via pkg-config / find_package
if(NOT DEFINED RAYLIB_PATH)
    find_package(raylib QUIET)
    if(NOT raylib_FOUND)
        # Fallback: use FetchContent to download and build raylib
        include(FetchContent)
        FetchContent_Declare(
            raylib
            GIT_REPOSITORY https://github.com/raysan5/raylib.git
            GIT_TAG 6.0
        )
        FetchContent_MakeAvailable(raylib)
        set(RAYLIB_LIBS raylib)
        set(RAYLIB_INCLUDE_DIR ${raylib_SOURCE_DIR}/src)
    else()
        set(RAYLIB_LIBS raylib)
    endif()
else()
    set(RAYLIB_INCLUDE_DIR ${RAYLIB_PATH}/include)
    set(RAYLIB_LIB_DIR ${RAYLIB_PATH}/lib)
    add_library(raylib SHARED IMPORTED)
    set_target_properties(raylib PROPERTIES
        IMPORTED_LOCATION ${RAYLIB_LIB_DIR}/raylib.dll
        IMPORTED_IMPLIB   ${RAYLIB_LIB_DIR}/raylib.lib
    )
    set(RAYLIB_LIBS raylib)
endif()

# ── Sources ──────────────────────────────────
set(SOURCES
    main.cpp
    game.cpp
    ui_manager.cpp
    player.cpp
    enemy.cpp
    boss.cpp
    particle.cpp
    powerup.cpp
    wave_manager.cpp
)

set(HEADERS
    game.h
    ui_manager.h
    player.h
    enemy.h
    boss.h
    particle.h
    powerup.h
    pool.h
    types.h
    constants.h
    input.h
    wave_manager.h
)

add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS})

target_include_directories(${PROJECT_NAME} PRIVATE ${RAYLIB_INCLUDE_DIR})
target_link_libraries(${PROJECT_NAME} PRIVATE ${RAYLIB_LIBS})

# Windows: link additional system libs
if(WIN32)
    target_link_libraries(${PROJECT_NAME} PRIVATE opengl32 winmm gdi32 user32 shell32)
endif()

# Linux / macOS
if(UNIX)
    target_link_libraries(${PROJECT_NAME} PRIVATE
        ${CMAKE_DL_LIBS} m pthread
        ${X11_LIBRARIES}
    )
endif()

# ── Install ──────────────────────────────────
install(TARGETS ${PROJECT_NAME} DESTINATION bin)
install(DIRECTORY resources/ DESTINATION bin/resources)

# Copy resources to build directory for debugging
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/resources
    $<TARGET_FILE_DIR:${PROJECT_NAME}>/resources
)
