#include <setjmp.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>

#include <cmocka.h>

#include "font.h"

// Stub fill_rect: counts calls and remembers the last colour. This allows
// verifying that draw_text walks each glyph and forwards the colour.
static int g_fill_rect_calls;
static UINT32 g_fill_rect_last_color;

void fill_rect(UINTN x, UINTN y, UINTN w, UINTN h, UINT32 color) {
    (void)x;
    (void)y;
    (void)w;
    (void)h;
    g_fill_rect_calls++;
    g_fill_rect_last_color = color;
}

static int reset_counters(void **state) {
    (void)state;
    g_fill_rect_calls = 0;
    g_fill_rect_last_color = 0;
    return 0;
}

static void test_glyph_for_known_chars(void **state) {
    (void)state;
    assert_non_null(glyph_for('A'));
    assert_non_null(glyph_for('N'));
    assert_non_null(glyph_for('Q'));
    assert_non_null(glyph_for('W'));
    assert_non_null(glyph_for('Z'));
    assert_non_null(glyph_for('0'));
    assert_non_null(glyph_for('9'));
    assert_non_null(glyph_for('a'));
    assert_non_null(glyph_for('.'));
    assert_non_null(glyph_for(':'));
    assert_non_null(glyph_for('/'));
    assert_non_null(glyph_for('-'));
    assert_non_null(glyph_for('('));
    assert_non_null(glyph_for(')'));
}

static void test_glyph_for_unknown_chars(void **state) {
    (void)state;
    assert_null(glyph_for(' '));
    assert_null(glyph_for('\n'));
    assert_null(glyph_for('@'));
    // 'q' has no lowercase glyph in the current font (not used in any string).
    assert_null(glyph_for('q'));
}

static void test_text_width_empty(void **state) {
    (void)state;
    assert_int_equal(text_width("", 1), 0);
    assert_int_equal(text_width("", 5), 0);
}

// At scale s a glyph occupies 5*s pixels and an inter-glyph gap is 1*s. For n
// glyphs total width is n*6*s - s (no trailing gap).
static void test_text_width_scaled(void **state) {
    (void)state;
    assert_int_equal(text_width("A", 1), 5);
    assert_int_equal(text_width("AB", 1), 11);
    assert_int_equal(text_width("ABC", 2), 34);
    assert_int_equal(text_width("ABCD", 3), 69);
}

// draw_char_5x5 must call fill_rect once per set bit. A glyph with the top row
// fully set (0x1F) and other rows zero should produce exactly 5 calls.
static void test_draw_char_5x5_fills_per_set_bit(void **state) {
    (void)state;
    UINT8 glyph[5] = {0x1F, 0x00, 0x00, 0x00, 0x00};
    draw_char_5x5(0, 0, 1, glyph, 0xAB);
    assert_int_equal(g_fill_rect_calls, 5);
    assert_int_equal(g_fill_rect_last_color, 0xAB);
}

// Empty glyph (all zero rows) should never call fill_rect.
static void test_draw_char_5x5_empty_glyph(void **state) {
    (void)state;
    UINT8 glyph[5] = {0, 0, 0, 0, 0};
    draw_char_5x5(0, 0, 1, glyph, 0xAB);
    assert_int_equal(g_fill_rect_calls, 0);
}

// draw_text with an unknown character produces no fill_rect calls (the glyph
// is missing); cursor advance still happens so subsequent characters draw.
static void test_draw_text_skips_missing_glyphs(void **state) {
    (void)state;
    draw_text(0, 0, 1, "@", 0x12);
    assert_int_equal(g_fill_rect_calls, 0);
}

// draw_text on a known string produces some fill_rect calls and forwards the
// caller's colour.
static void test_draw_text_forwards_color(void **state) {
    (void)state;
    draw_text(0, 0, 1, "A", 0xCAFE);
    assert_true(g_fill_rect_calls > 0);
    assert_int_equal(g_fill_rect_last_color, 0xCAFE);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test_setup(test_glyph_for_known_chars, reset_counters),
        cmocka_unit_test_setup(test_glyph_for_unknown_chars, reset_counters),
        cmocka_unit_test_setup(test_text_width_empty, reset_counters),
        cmocka_unit_test_setup(test_text_width_scaled, reset_counters),
        cmocka_unit_test_setup(test_draw_char_5x5_fills_per_set_bit, reset_counters),
        cmocka_unit_test_setup(test_draw_char_5x5_empty_glyph, reset_counters),
        cmocka_unit_test_setup(test_draw_text_skips_missing_glyphs, reset_counters),
        cmocka_unit_test_setup(test_draw_text_forwards_color, reset_counters),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}
