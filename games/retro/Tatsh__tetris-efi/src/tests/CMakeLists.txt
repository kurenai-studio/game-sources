find_package(cmocka REQUIRED)

set(_TETRIS_TEST_INCLUDES /usr/include/efi /usr/include/efi/protocol)
if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86_64")
  list(APPEND _TETRIS_TEST_INCLUDES /usr/include/efi/${CMAKE_HOST_SYSTEM_PROCESSOR})
endif()

set(_TETRIS_TEST_DEFS GOP)
if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86_64")
  list(APPEND _TETRIS_TEST_DEFS EFI_FUNCTION_WRAPPER)
endif()

# Test executables compile their own copy of the relevant src/*.c files. This keeps cmocka tests
# independent of the gnu-efi runtime: if a source file references Print() or BS->..., link a stub
# or use -Wl,--wrap as needed.
function(add_tetris_test name)
  add_executable(${name} ${ARGN})
  target_compile_definitions(${name} PRIVATE ${_TETRIS_TEST_DEFS})
  target_compile_options(${name} PRIVATE -fshort-wchar --coverage -ggdb)
  target_include_directories(
    ${name} PRIVATE ${_TETRIS_TEST_INCLUDES} ${cmocka_INCLUDE_DIRS} ${CMAKE_SOURCE_DIR}/src)
  target_link_libraries(${name} PRIVATE cmocka gcov)
  add_test(NAME ${name} COMMAND ${name})
endfunction()

add_tetris_test(test_piece test_piece.c ${CMAKE_SOURCE_DIR}/src/piece.c)
add_tetris_test(test_game test_game.c ${CMAKE_SOURCE_DIR}/src/piece.c
                ${CMAKE_SOURCE_DIR}/src/game.c)
add_tetris_test(test_font test_font.c ${CMAKE_SOURCE_DIR}/src/font.c)

# test_render exercises fill_rect/draw_block/present/init_gop_highest_mode/render. The wraps
# below let cmocka drive every UEFI call render.c makes.
add_tetris_test(test_render test_render.c ${CMAKE_SOURCE_DIR}/src/render.c
                ${CMAKE_SOURCE_DIR}/src/font.c
                ${CMAKE_SOURCE_DIR}/src/piece.c
                ${CMAKE_SOURCE_DIR}/src/game.c)
target_link_options(
  test_render PRIVATE -Wl,--wrap=Print -Wl,--wrap=InitializeLib -Wl,--wrap=efi_call2
                      -Wl,--wrap=efi_call3 -Wl,--wrap=efi_call4 -Wl,--wrap=efi_call10)

# efi_main calls InitializeLib + init_gop_highest_mode + run_game. Wrap all three so the test
# fully drives the entry point without linking gnu-efi or the rest of src/.
add_tetris_test(test_main test_main.c ${CMAKE_SOURCE_DIR}/src/main.c)
target_link_options(test_main PRIVATE -Wl,--wrap=InitializeLib
                                      -Wl,--wrap=init_gop_highest_mode
                                      -Wl,--wrap=run_game)

# run_game uses BS, ST, Print, render and the efi_call* family. Wrap each so cmocka can drive
# every loop iteration. game.c + piece.c link cleanly (no UEFI calls).
add_tetris_test(test_loop test_loop.c ${CMAKE_SOURCE_DIR}/src/loop.c
                ${CMAKE_SOURCE_DIR}/src/game.c
                ${CMAKE_SOURCE_DIR}/src/piece.c)
target_link_options(
  test_loop PRIVATE -Wl,--wrap=Print -Wl,--wrap=render -Wl,--wrap=efi_call1 -Wl,--wrap=efi_call2
                    -Wl,--wrap=efi_call3 -Wl,--wrap=efi_call5)
