cmake_minimum_required(VERSION 3.28 FATAL_ERROR)
project(
  tetris-efi
  DESCRIPTION "A Tetris clone that runs as a UEFI application."
  HOMEPAGE_URL "https://github.com/Tatsh/tetris-efi"
  LANGUAGES C
  VERSION 0.0.1)

option(BUILD_TESTS "Build tests." OFF)

set(TETRIS tetris)
set(TETRIS_EFI ${TETRIS}.efi)
set(TETRIS_ISO ${TETRIS}.iso)
set(TETRIS_SO ${TETRIS}.so)

set(POSSIBLE_GNUEFI_LIBDIRS
    /lib
    /lib/gnuefi
    /lib64
    /lib64/gnuefi
    /usr/lib
    /usr/lib/gnuefi
    /usr/lib64
    /usr/lib64/gnuefi)
find_file(EFI_CRT_OBJS crt0-efi-${CMAKE_HOST_SYSTEM_PROCESSOR}.o PATHS ${POSSIBLE_GNUEFI_LIBDIRS}
                                                                       REQUIRED)
find_file(EFI_LDS elf_${CMAKE_HOST_SYSTEM_PROCESSOR}_efi.lds PATHS ${POSSIBLE_GNUEFI_LIBDIRS}
                                                                   REQUIRED)
if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86_64")
  set(EFI_OBJCOPY_ELF "elf64-x86-64")
  set(EFI_OBJCOPY_EFI "efi-app-x86_64")
else()
  set(EFI_OBJCOPY_ELF "elf64-${CMAKE_HOST_SYSTEM_PROCESSOR}")
  set(EFI_OBJCOPY_EFI "efi-app-${CMAKE_HOST_SYSTEM_PROCESSOR}")
endif()

# Game logic, entry point, and the ${TETRIS_SO} / ${TETRIS_EFI} / ${TETRIS_ISO} targets all live
# in src/.
add_subdirectory(src)

find_program(QEMU qemu-system-x86_64)
if(NOT QEMU-NOTFOUND)
  find_file(
    OVMF_CODE
    NAMES OVMF_CODE.fd
    PATHS /usr/share/edk2/ovmf/x64
          /usr/share/edk2/ovmf
          /usr/share/edk2/OvmfX64
          /usr/share/edk2-ovmf
          /usr/share/edk2-ovmf/x64
          /usr/share/OVMF
    NO_DEFAULT_PATH)
  if(OVMF_CODE)
    add_custom_target(
      run-qemu
      COMMAND ${QEMU} -bios "${OVMF_CODE}" -cdrom ${CMAKE_BINARY_DIR}/${TETRIS_ISO} -m 128
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
      DEPENDS ${TETRIS_ISO}
      COMMENT "Launching Tetris ISO in QEMU (UEFI).")
  else()
    message(
      STATUS
      "OVMF not found; run-qemu target not added. Install edk2-ovmf (or similar) for UEFI boot in "
      "QEMU.")
  endif()
endif()

if(BUILD_TESTS)
  enable_testing()
  add_subdirectory(tests)
endif()
