#include "render.h"
#include "font.h"
#include "game.h"

#include <efilib.h>

#ifndef TETRIS_VERSION_STR
#define TETRIS_VERSION_STR "0.0.0"
#endif
#ifndef TETRIS_WEBSITE_STR
#define TETRIS_WEBSITE_STR "github.com/tatsh/tetris-efi"
#endif

static EFI_GRAPHICS_OUTPUT_PROTOCOL *gop;
UINTN screen_width;
UINTN screen_height;
UINT32 *backbuffer;
UINTN cell_w;
UINTN cell_h;
UINTN board_origin_x;
UINTN board_origin_y;

void fill_rect(UINTN x, UINTN y, UINTN w, UINTN h, UINT32 color) {
    UINTN x0 = x, y0 = y, x1 = x + w, y1 = y + h;
    if (x0 >= screen_width || y0 >= screen_height) {
        return;
    }
    if (x1 > screen_width) {
        x1 = screen_width;
    }
    if (y1 > screen_height) {
        y1 = screen_height;
    }
    for (UINTN dy = y0; dy < y1; dy++) {
        UINT32 *row = backbuffer + dy * screen_width + x0;
        for (UINTN dx = x0; dx < x1; dx++) {
            *row++ = color;
        }
    }
}

void present(void) {
    uefi_call_wrapper(gop->Blt,
                      10,
                      gop,
                      (EFI_GRAPHICS_OUTPUT_BLT_PIXEL *)backbuffer,
                      EfiBltBufferToVideo,
                      0,
                      0,
                      0,
                      0,
                      screen_width,
                      screen_height,
                      0);
}

void draw_block(UINTN bx, UINTN by, UINT32 color) {
    UINTN x = board_origin_x + bx * cell_w;
    UINTN y = board_origin_y + by * cell_h;
    UINTN gap = (cell_w > 4 && cell_h > 4) ? 1 : 0;
    fill_rect(x + gap, y + gap, cell_w - 2 * gap, cell_h - 2 * gap, color);
}

EFI_STATUS init_gop_highest_mode(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
    (void)ImageHandle;
    (void)SystemTable;
    EFI_GUID gop_guid = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;
    EFI_STATUS status = uefi_call_wrapper(BS->LocateProtocol, 3, &gop_guid, NULL, (void **)&gop);
    if (EFI_ERROR(status)) {
        Print(L"Tetris: Unable to locate GOP.\n");
        return status;
    }

    // Start GOP if not started (required before Mode is valid).
    if (gop->Mode == NULL) {
        EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *info;
        UINTN size_of_info = 0;
        status = uefi_call_wrapper(gop->QueryMode, 4, gop, 0, &size_of_info, &info);
        if (status == EFI_NOT_STARTED) {
            status = uefi_call_wrapper(gop->SetMode, 2, gop, 0);
        }
        if (EFI_ERROR(status)) {
            Print(L"Tetris: Unable to query/set initial mode.\n");
            return status;
        }
    }

    // Use current mode only (no SetMode). Avoids hangs when chainloaded in VirtualBox.
    EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *info = gop->Mode->Info;
    if (info->PixelFormat != PixelRedGreenBlueReserved8BitPerColor &&
        info->PixelFormat != PixelBlueGreenRedReserved8BitPerColor) {
        status = uefi_call_wrapper(gop->SetMode, 2, gop, 0);
        if (EFI_ERROR(status)) {
            Print(L"Tetris: Unsupported pixel format.\n");
            return status;
        }
        info = gop->Mode->Info;
    }
    screen_width = info->HorizontalResolution;
    screen_height = info->VerticalResolution;

    UINTN bb_bytes = screen_width * screen_height * 4;
    status = uefi_call_wrapper(BS->AllocatePool, 3, EfiLoaderData, bb_bytes, (void **)&backbuffer);
    if (EFI_ERROR(status)) {
        Print(L"Tetris: AllocatePool for backbuffer failed.\n");
        return status;
    }

    // Scale: fit 10 columns and 20 rows with margin. Leave space for hold/next boxes.
    UINTN margin = 80;
    UINTN max_cell_w = (screen_width - 2 * margin) / (BOARD_WIDTH + 8);
    UINTN max_cell_h = (screen_height - 2 * margin) / VISIBLE_ROWS;
    cell_w = max_cell_w < max_cell_h ? max_cell_w : max_cell_h;
    if (cell_w < 8) {
        cell_w = 8;
    }
    cell_h = cell_w;

    board_origin_x = margin + 4 * cell_w;
    board_origin_y = margin;

    return EFI_SUCCESS;
}

void render(void) {
    UINT32 bg = 0x00101010;
    fill_rect(0, 0, screen_width, screen_height, bg);

    // Board area border
    UINTN bw = BOARD_WIDTH * cell_w;
    UINTN bh = VISIBLE_ROWS * cell_h;
    UINT32 border = 0x00404040;
    fill_rect(board_origin_x - 2, board_origin_y - 2, bw + 4, bh + 4, border);

    for (int row = 0; row < VISIBLE_ROWS; row++) {
        for (int column = 0; column < BOARD_WIDTH; column++) {
            UINT8 cell = board[row][column];
            draw_block(column, row, TETRIS_COLORS[cell]);
        }
    }

    /*
     * Ghost piece: where the current piece would land on a hard drop. Drawn
     * first so the live piece overdraws it when they coincide.
     */
    int ghost_y = current_y;
    while (!collision(current_piece, current_rot, current_x, ghost_y + 1)) {
        ghost_y++;
    }
    if (ghost_y > current_y) {
        UINT32 ghost_color = (TETRIS_COLORS[current_piece + 1] >> 2) & 0x3F3F3F3F;
        for (int r = 0; r < 4; r++) {
            for (int c = 0; c < 4; c++) {
                if (SHAPES[current_piece][current_rot][r][c]) {
                    int bx = current_x + c;
                    int by = ghost_y + r;
                    if (by >= 0) {
                        draw_block(bx, by, ghost_color);
                    }
                }
            }
        }
    }

    // Current piece
    for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
            if (SHAPES[current_piece][current_rot][r][c]) {
                int bx = current_x + c;
                int by = current_y + r;
                if (by >= 0) {
                    draw_block(bx, by, TETRIS_COLORS[current_piece + 1]);
                }
            }
        }
    }

    // Hold box (left of board)
    UINTN hold_x = (board_origin_x >= 8 * cell_w) ? board_origin_x - 6 * cell_w : 10;
    UINTN hold_y = board_origin_y;
    fill_rect(hold_x - 2, hold_y - 2, 4 * cell_w + 4, 4 * cell_h + 4, border);
    if (hold_piece >= 0) {
        for (int r = 0; r < 4; r++) {
            for (int c = 0; c < 4; c++) {
                if (SHAPES[hold_piece][0][r][c]) {
                    fill_rect(hold_x + c * cell_w + 1,
                              hold_y + r * cell_h + 1,
                              cell_w - 2,
                              cell_h - 2,
                              TETRIS_COLORS[hold_piece + 1]);
                }
            }
        }
    }

    // Next box (right of board)
    UINTN next_x = board_origin_x + bw + 2 * cell_w;
    if (next_x + 4 * cell_w > screen_width) {
        next_x = board_origin_x - 6 * cell_w;
    }
    fill_rect(next_x - 2, hold_y - 2, 4 * cell_w + 4, 4 * cell_h + 4, border);
    for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
            if (SHAPES[next_piece][0][r][c]) {
                fill_rect(next_x + c * cell_w + 1,
                          hold_y + r * cell_h + 1,
                          cell_w - 2,
                          cell_h - 2,
                          TETRIS_COLORS[next_piece + 1]);
            }
        }
    }

    // Score: 'SCORE' label and digit string below the next box.
    UINTN font_scale = cell_w / 4;
    if (font_scale < 2) {
        font_scale = 2;
    }
    UINT32 white = 0x00FFFFFF;
    UINTN score_x = next_x;
    UINTN score_y = hold_y + 4 * cell_h + cell_h;
    draw_text(score_x, score_y, font_scale, "SCORE", white);

    char score_buf[16];
    UINTN n = score;
    int len = 0;
    if (n == 0) {
        score_buf[len++] = '0';
    } else {
        char tmp[16];
        int t = 0;
        while (n) {
            tmp[t++] = (char)('0' + n % 10);
            n /= 10;
        }
        while (t > 0) {
            score_buf[len++] = tmp[--t];
        }
    }
    score_buf[len] = '\0';
    UINTN digits_y = score_y + 5 * font_scale + 2 * font_scale;
    draw_text(score_x, digits_y, font_scale, score_buf, white);

    /*
     * Version + project URL stacked below the score, in a smaller dim font.
     * Floor of 2 keeps it readable on small GOP modes.
     */
    UINTN info_scale = font_scale / 3 + 1;
    if (info_scale < 2) {
        info_scale = 2;
    }
    UINTN info_line_h = 5 * info_scale + 2 * info_scale;
    UINTN info_y = digits_y + 5 * font_scale + 3 * font_scale;
    UINT32 dim = 0x00808080;
    draw_text(score_x, info_y, info_scale, "v" TETRIS_VERSION_STR, dim);
    draw_text(score_x, info_y + 1 * info_line_h, info_scale, TETRIS_WEBSITE_STR, dim);
    draw_text(
        score_x, info_y + 2 * info_line_h, info_scale, "Copyright (c) 2026 Andrew Udvare.", dim);
    draw_text(
        score_x, info_y + 3 * info_line_h, info_scale, "Released under the MIT license.", dim);

    if (game_over) {
        /*
         * Overlay confined to the playfield columns so it doesn't cover the
         * next box or the SCORE display on the right.
         */
        UINTN box_w = bw + 4;
        UINTN box_h = 8 * cell_h;
        UINTN bx = board_origin_x - 2;
        UINTN by = board_origin_y + (bh - box_h) / 2;
        fill_rect(bx, by, box_w, box_h, 0x00202030);
        fill_rect(bx + 2, by + 2, box_w - 4, box_h - 4, 0x00404050);

        UINTN inner_x = bx + 2;
        UINTN inner_w = box_w - 4;
        UINTN max_text_w = (inner_w > 8) ? inner_w - 8 : inner_w;

        const char *title = "GAME OVER";
        const char *new_game = "N: NEW GAME";
        const char *quit = "Q: QUIT";

        UINTN title_scale = font_scale + 1;
        while (title_scale > 1 && text_width(title, title_scale) > max_text_w) {
            title_scale--;
        }

        UINTN sub_scale = font_scale;
        while (sub_scale > 1 && text_width(new_game, sub_scale) > max_text_w) {
            sub_scale--;
        }

        UINTN title_h = 5 * title_scale;
        UINTN sub_h = 5 * sub_scale;
        UINTN sub_gap = 3 * sub_scale;
        UINTN block_h = title_h + 4 * title_scale + sub_h + sub_gap + sub_h;
        UINTN start_y = by + (box_h - block_h) / 2;

        UINTN title_x = inner_x + (inner_w - text_width(title, title_scale)) / 2;
        draw_text(title_x, start_y, title_scale, title, 0x00FFFFFF);

        UINTN new_y = start_y + title_h + 4 * title_scale;
        UINTN new_x = inner_x + (inner_w - text_width(new_game, sub_scale)) / 2;
        draw_text(new_x, new_y, sub_scale, new_game, 0x00E0E0E0);

        UINTN quit_y = new_y + sub_h + sub_gap;
        UINTN quit_x = inner_x + (inner_w - text_width(quit, sub_scale)) / 2;
        draw_text(quit_x, quit_y, sub_scale, quit, 0x00E0E0E0);
    }

    // Controls hint along the bottom. Scale shrinks if the line wouldn't fit.
    const char *controls = "Z:ROT L  X:ROT R  SPACE:DROP  C:HOLD";
    UINTN ctrl_scale = cell_w / 6;
    if (ctrl_scale < 2) {
        ctrl_scale = 2;
    }
    while (ctrl_scale > 1 && text_width(controls, ctrl_scale) > screen_width - 40) {
        ctrl_scale--;
    }
    UINTN ctrl_w = text_width(controls, ctrl_scale);
    UINTN ctrl_y = screen_height - 5 * ctrl_scale - 2 * ctrl_scale;
    UINTN ctrl_x = (screen_width - ctrl_w) / 2;
    draw_text(ctrl_x, ctrl_y, ctrl_scale, controls, 0x00B0B0B0);

    present();
}
