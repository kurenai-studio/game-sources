#include "font.h"
#include "render.h"

/*
 * 5x5 bitmap font glyphs. Each byte's low 5 bits encode one row, MSB =
 * leftmost column. Only the characters we need are defined.
 */
static const UINT8 FONT_A[5] = {0x0E, 0x11, 0x1F, 0x11, 0x11};
static const UINT8 FONT_B[5] = {0x1E, 0x11, 0x1E, 0x11, 0x1E};
static const UINT8 FONT_C[5] = {0x0E, 0x10, 0x10, 0x10, 0x0E};
static const UINT8 FONT_D[5] = {0x1E, 0x11, 0x11, 0x11, 0x1E};
static const UINT8 FONT_E[5] = {0x1F, 0x10, 0x1E, 0x10, 0x1F};
static const UINT8 FONT_F[5] = {0x1F, 0x10, 0x1E, 0x10, 0x10};
static const UINT8 FONT_G[5] = {0x0F, 0x10, 0x17, 0x11, 0x0F};
static const UINT8 FONT_H[5] = {0x11, 0x11, 0x1F, 0x11, 0x11};
static const UINT8 FONT_I[5] = {0x1F, 0x04, 0x04, 0x04, 0x1F};
static const UINT8 FONT_L[5] = {0x10, 0x10, 0x10, 0x10, 0x1F};
static const UINT8 FONT_M[5] = {0x11, 0x1B, 0x15, 0x11, 0x11};
static const UINT8 FONT_N[5] = {0x11, 0x19, 0x15, 0x13, 0x11};
static const UINT8 FONT_O[5] = {0x0E, 0x11, 0x11, 0x11, 0x0E};
static const UINT8 FONT_P[5] = {0x1E, 0x11, 0x1E, 0x10, 0x10};
static const UINT8 FONT_Q[5] = {0x0E, 0x11, 0x11, 0x15, 0x0F};
static const UINT8 FONT_R[5] = {0x1E, 0x11, 0x1E, 0x12, 0x11};
static const UINT8 FONT_S[5] = {0x0E, 0x10, 0x0E, 0x01, 0x1E};
static const UINT8 FONT_T[5] = {0x1F, 0x04, 0x04, 0x04, 0x04};
static const UINT8 FONT_U[5] = {0x11, 0x11, 0x11, 0x11, 0x0E};
static const UINT8 FONT_V[5] = {0x11, 0x11, 0x11, 0x0A, 0x04};
static const UINT8 FONT_W[5] = {0x11, 0x11, 0x15, 0x15, 0x0A};
static const UINT8 FONT_X[5] = {0x11, 0x0A, 0x04, 0x0A, 0x11};
static const UINT8 FONT_Z[5] = {0x1F, 0x02, 0x04, 0x08, 0x1F};
/*
 * Lowercase glyphs (only the letters used in the info row). 4-row x-height for
 * a/c/e/m/o/r/s/u/v; 5-row ascenders for b/f/h/i/t; wraparound g for descender.
 */
static const UINT8 FONT_a[5] = {0x00, 0x0C, 0x12, 0x12, 0x0F};
static const UINT8 FONT_b[5] = {0x10, 0x10, 0x1C, 0x12, 0x1C};
static const UINT8 FONT_c[5] = {0x00, 0x0C, 0x10, 0x10, 0x0C};
static const UINT8 FONT_d[5] = {0x02, 0x02, 0x0E, 0x12, 0x0E};
static const UINT8 FONT_e[5] = {0x00, 0x0C, 0x12, 0x1C, 0x0C};
static const UINT8 FONT_f[5] = {0x0C, 0x08, 0x1C, 0x08, 0x08};
static const UINT8 FONT_g[5] = {0x00, 0x0E, 0x12, 0x0F, 0x01};
static const UINT8 FONT_h[5] = {0x10, 0x10, 0x1C, 0x12, 0x12};
static const UINT8 FONT_i[5] = {0x08, 0x00, 0x08, 0x08, 0x08};
static const UINT8 FONT_l[5] = {0x08, 0x08, 0x08, 0x08, 0x08};
static const UINT8 FONT_m[5] = {0x00, 0x1A, 0x15, 0x15, 0x15};
static const UINT8 FONT_n[5] = {0x00, 0x1C, 0x12, 0x12, 0x12};
static const UINT8 FONT_o[5] = {0x00, 0x0C, 0x12, 0x12, 0x0C};
static const UINT8 FONT_p[5] = {0x00, 0x1C, 0x12, 0x1C, 0x10};
static const UINT8 FONT_r[5] = {0x00, 0x14, 0x1C, 0x10, 0x10};
static const UINT8 FONT_s[5] = {0x00, 0x0E, 0x18, 0x06, 0x1C};
static const UINT8 FONT_t[5] = {0x08, 0x1C, 0x08, 0x08, 0x0C};
static const UINT8 FONT_u[5] = {0x00, 0x12, 0x12, 0x12, 0x0E};
static const UINT8 FONT_v[5] = {0x00, 0x00, 0x11, 0x0A, 0x04};
static const UINT8 FONT_w[5] = {0x00, 0x11, 0x11, 0x15, 0x0A};
static const UINT8 FONT_y[5] = {0x00, 0x12, 0x12, 0x0E, 0x02};
static const UINT8 FONT_DOT[5] = {0x00, 0x00, 0x00, 0x00, 0x04};
static const UINT8 FONT_COLON[5] = {0x00, 0x04, 0x00, 0x04, 0x00};
static const UINT8 FONT_DASH[5] = {0x00, 0x00, 0x0E, 0x00, 0x00};
static const UINT8 FONT_SLASH[5] = {0x01, 0x02, 0x04, 0x08, 0x10};
static const UINT8 FONT_LPAREN[5] = {0x04, 0x08, 0x08, 0x08, 0x04};
static const UINT8 FONT_RPAREN[5] = {0x04, 0x02, 0x02, 0x02, 0x04};
static const UINT8 FONT_DIGITS[10][5] = {
    {0x0E, 0x13, 0x15, 0x19, 0x0E}, // 0
    {0x04, 0x0C, 0x04, 0x04, 0x0E}, // 1
    {0x1E, 0x01, 0x0E, 0x10, 0x1F}, // 2
    {0x1E, 0x01, 0x0E, 0x01, 0x1E}, // 3
    {0x11, 0x11, 0x1F, 0x01, 0x01}, // 4
    {0x1F, 0x10, 0x1E, 0x01, 0x1E}, // 5
    {0x0E, 0x10, 0x1E, 0x11, 0x0E}, // 6
    {0x1F, 0x01, 0x02, 0x04, 0x04}, // 7
    {0x0E, 0x11, 0x0E, 0x11, 0x0E}, // 8
    {0x0E, 0x11, 0x0F, 0x01, 0x0E}, // 9
};

// LCOV_EXCL_START
const UINT8 *glyph_for(char c) {
    switch (c) {
    case 'A':
        return FONT_A;
    case 'B':
        return FONT_B;
    case 'C':
        return FONT_C;
    case 'D':
        return FONT_D;
    case 'E':
        return FONT_E;
    case 'F':
        return FONT_F;
    case 'G':
        return FONT_G;
    case 'H':
        return FONT_H;
    case 'I':
        return FONT_I;
    case 'L':
        return FONT_L;
    case 'M':
        return FONT_M;
    case 'N':
        return FONT_N;
    case 'O':
        return FONT_O;
    case 'P':
        return FONT_P;
    case 'Q':
        return FONT_Q;
    case 'R':
        return FONT_R;
    case 'S':
        return FONT_S;
    case 'T':
        return FONT_T;
    case 'U':
        return FONT_U;
    case 'V':
        return FONT_V;
    case 'W':
        return FONT_W;
    case 'X':
        return FONT_X;
    case 'Z':
        return FONT_Z;
    case 'a':
        return FONT_a;
    case 'b':
        return FONT_b;
    case 'c':
        return FONT_c;
    case 'd':
        return FONT_d;
    case 'e':
        return FONT_e;
    case 'f':
        return FONT_f;
    case 'g':
        return FONT_g;
    case 'h':
        return FONT_h;
    case 'i':
        return FONT_i;
    case 'l':
        return FONT_l;
    case 'm':
        return FONT_m;
    case 'n':
        return FONT_n;
    case 'o':
        return FONT_o;
    case 'p':
        return FONT_p;
    case 'r':
        return FONT_r;
    case 's':
        return FONT_s;
    case 't':
        return FONT_t;
    case 'u':
        return FONT_u;
    case 'v':
        return FONT_v;
    case 'w':
        return FONT_w;
    case 'y':
        return FONT_y;
    case '.':
        return FONT_DOT;
    case ':':
        return FONT_COLON;
    case '-':
        return FONT_DASH;
    case '/':
        return FONT_SLASH;
    case '(':
        return FONT_LPAREN;
    case ')':
        return FONT_RPAREN;
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
        return FONT_DIGITS[c - '0'];
    default:
        return NULL;
    }
}
// LCOV_EXCL_STOP

void draw_char_5x5(UINTN x, UINTN y, UINTN scale, const UINT8 rows[5], UINT32 color) {
    for (int r = 0; r < 5; r++) {
        UINT8 row = rows[r];
        for (int c = 0; c < 5; c++) {
            if (row & (1u << (4 - c))) {
                fill_rect(x + c * scale, y + r * scale, scale, scale, color);
            }
        }
    }
}

void draw_text(UINTN x, UINTN y, UINTN scale, const char *s, UINT32 color) {
    UINTN advance = 6 * scale;
    while (*s) {
        const UINT8 *g = glyph_for(*s);
        if (g) {
            draw_char_5x5(x, y, scale, g, color);
        }
        x += advance;
        s++;
    }
}

UINTN text_width(const char *s, UINTN scale) {
    UINTN n = 0;
    for (const char *p = s; *p; p++) {
        n++;
    }
    if (n == 0) {
        return 0;
    }
    return n * 6 * scale - scale; // Drop the trailing inter-glyph gap.
}
