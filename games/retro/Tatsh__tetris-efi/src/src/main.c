/*
 * UEFI Tetris entry point. Game logic lives in src/.
 */
#include "loop.h"
#include "render.h"

#include <efilib.h>

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
    InitializeLib(ImageHandle, SystemTable);
    EFI_STATUS status = init_gop_highest_mode(ImageHandle, SystemTable);
    if (EFI_ERROR(status)) {
        return status;
    }
    return run_game();
}
