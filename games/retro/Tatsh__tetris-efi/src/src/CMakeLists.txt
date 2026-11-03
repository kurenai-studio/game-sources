set(TETRIS_EFI_COMPILE_OPTIONS -fno-stack-protector -fpic -fshort-wchar -mno-red-zone -Wall)
set(TETRIS_EFI_INCLUDE_DIRS /usr/include/efi /usr/include/efi/protocol)
if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86_64")
  list(APPEND TETRIS_EFI_INCLUDE_DIRS /usr/include/efi/${CMAKE_HOST_SYSTEM_PROCESSOR})
endif()

# Game logic, separate from the entry point so tests can link it without pulling in efi_main.
add_library(tetris_core OBJECT font.c piece.c game.c loop.c render.c)
target_compile_definitions(
  tetris_core PRIVATE GOP TETRIS_VERSION_STR="${PROJECT_VERSION}"
                      TETRIS_WEBSITE_STR="github.com/tatsh/tetris-efi")
target_compile_options(tetris_core PRIVATE ${TETRIS_EFI_COMPILE_OPTIONS})
target_include_directories(tetris_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(tetris_core PRIVATE ${TETRIS_EFI_INCLUDE_DIRS})
if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86_64")
  target_compile_definitions(tetris_core PRIVATE EFI_FUNCTION_WRAPPER)
endif()

# Entry point only. Linked into tetris.so alongside tetris_core.
add_library(tetris_main OBJECT main.c)
target_compile_options(tetris_main PRIVATE ${TETRIS_EFI_COMPILE_OPTIONS})
target_include_directories(tetris_main PRIVATE ${TETRIS_EFI_INCLUDE_DIRS}
                                               ${CMAKE_CURRENT_SOURCE_DIR})
if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86_64")
  target_compile_definitions(tetris_main PRIVATE EFI_FUNCTION_WRAPPER)
endif()

# Build pipeline: object files -> tetris.so (gnu-efi linked PIC shared object) -> tetris.efi
# (PE32+ via objcopy) -> tetris.iso (minimal UEFI ISO via El Torito with no bootloader). All
# artifacts land at the top-level build directory.
add_custom_target(
  ${TETRIS_SO} ALL
  COMMAND
    ld -nostdlib -znocombreloc -T ${EFI_LDS} -shared -Bsymbolic -L /usr/lib64 -L /usr/lib
    ${EFI_CRT_OBJS} $<TARGET_OBJECTS:tetris_core> $<TARGET_OBJECTS:tetris_main> -o
    ${CMAKE_BINARY_DIR}/${TETRIS_SO} -lefi -lgnuefi
  DEPENDS tetris_core tetris_main
  COMMAND_EXPAND_LISTS)

add_custom_target(
  ${TETRIS_EFI} ALL
  COMMAND objcopy -I ${EFI_OBJCOPY_ELF} -O ${EFI_OBJCOPY_EFI}
          -j .text -j .sdata -j .data -j .rodata -j .dynamic -j .dynsym -j .rel -j .rela -j .reloc
          ${CMAKE_BINARY_DIR}/${TETRIS_SO} ${CMAKE_BINARY_DIR}/${TETRIS_EFI}
  DEPENDS ${TETRIS_SO})

# Minimal UEFI-bootable ISO. No bootloader: the EFI System Partition image is exposed via El
# Torito (platform 0xEF) and UEFI firmware loads \EFI\BOOT\BOOTX64.EFI directly.
find_program(MFORMAT mformat REQUIRED)
find_program(MMD mmd REQUIRED)
find_program(MCOPY mcopy REQUIRED)
find_program(MKISOFS NAMES xorrisofs mkisofs genisoimage REQUIRED)
add_custom_target(
  ${TETRIS_ISO} ALL
  COMMAND ${CMAKE_COMMAND} -E rm -rf iso_root
  COMMAND ${CMAKE_COMMAND} -E make_directory iso_root
  COMMAND dd if=/dev/zero of=iso_root/efi.img bs=1024 count=1024 status=none
  COMMAND ${MFORMAT} -i iso_root/efi.img -v EFIBOOT
  COMMAND ${MMD} -i iso_root/efi.img ::/EFI ::/EFI/BOOT
  COMMAND ${MCOPY} -i iso_root/efi.img ${CMAKE_BINARY_DIR}/${TETRIS_EFI} ::/EFI/BOOT/BOOTX64.EFI
  COMMAND ${MKISOFS} -V tetris -o ${CMAKE_BINARY_DIR}/${TETRIS_ISO}
          -eltorito-platform efi -eltorito-boot efi.img -no-emul-boot
          iso_root
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  DEPENDS ${TETRIS_EFI}
  COMMENT "Building minimal UEFI ISO ${TETRIS_ISO} (no bootloader).")
set_property(DIRECTORY ${CMAKE_BINARY_DIR} APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES iso_root)
