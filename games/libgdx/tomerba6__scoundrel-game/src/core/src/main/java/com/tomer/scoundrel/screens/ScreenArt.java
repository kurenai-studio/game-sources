package com.tomer.scoundrel.screens;

/**
 * The menu screens' kit: the five parts every screen outside the board is
 * assembled from, and where each screen puts them.
 *
 * <p>The six screens are built from a frame, a face, a bevel, a label and a
 * rule, and nothing else. That is what this holds. Learn these and each screen
 * is assembly work rather than design.
 *
 * <p>Coordinates are 1280×720 with y measured downward, as the art is
 * specified; {@link CardArt#toWorldY} converts when drawing.
 *
 * <p>Every {@code int} below that is not a colour is in design pixels; every
 * {@code _Y}, {@code _TOP} and {@code _DY} is measured downward, and a
 * {@code _DX} or {@code _DY} is an offset from its panel's or row's own
 * top-left. Colours are {@code 0xRRGGBB}.
 */
final class ScreenArt {

    /** The frame, the bevel and the rule are all the same 2px. */
    static final int THICK = 2;

    // --- the five parts ----------------------------------------------------

    /** The recess every widget sits in — the thing that unifies the screens. */
    static final int FRAME = 0x0f1410;
    /** The face of a panel: the mode panels, the dialogs, the run-end panel, the callout. */
    static final int FACE_PANEL = 0x161210;
    /** The face of a table: the ledger's totals and the run-end panel's figures. */
    static final int FACE_TABLE = 0x141110;

    /** A gold plate's face. */
    static final int GOLD = 0xd9a441;
    /** A gold plate's light bevel. */
    static final int GOLD_LIGHT = 0xf2cf7a;
    /** A gold plate's dark bevel. */
    static final int GOLD_DARK = 0xb5651f;
    /** A gold plate's label. */
    static final int GOLD_LABEL = 0x12161a;

    /** A dark plate's face. */
    static final int DARK = 0x1a1410;
    /** A dark plate's light bevel. */
    static final int DARK_LIGHT = 0x2f2620;
    /** A dark plate's dark bevel. */
    static final int DARK_DARK = 0x0a0806;
    /** A dark plate's label: bone, drawn at {@link #DARK_LABEL_ALPHA}. */
    static final int DARK_LABEL = 0xe8ddc7;
    /** A dark plate's label alpha. */
    static final float DARK_LABEL_ALPHA = 0.72f;

    /**
     * The two plate faces with the light off them, for a plate held down.
     * Inverting the bevel alone moves the highlight but leaves 12,000 pixels of
     * face at full brightness, so the plate reads as relit rather than pushed
     * in. Both are the wood ramp's own steps — the accent row the gold lives on
     * is a row of accents, not a ramp, so there is no darker gold in it; wood is
     * the material next door and its top step is that colour in shadow. Nothing
     * outside the eighty, per the palette rule.
     */
    static final int GOLD_PRESSED = 0xa67f4a;
    /** A dark plate's face, held down. */
    static final int DARK_PRESSED = 0x100a07;

    /** Section headings. */
    static final int HEADING = 0xd9a441;
    /** Descriptions and secondary readings. */
    static final int BODY = 0xe8ddc7;
    /** Body text's usual alpha, where it is secondary. */
    static final float BODY_ALPHA = 0.55f;
    /** Dividers. */
    static final int RULE = 0xe8ddc7;
    /** A divider's alpha: barely there. */
    static final float RULE_ALPHA = 0.08f;

    // --- buttons -----------------------------------------------------------

    /**
     * 268 wide over a `frame 2 · bevel 2 · plate · bevel 2 · frame 2`
     * structure, on a 56 pitch. The board's Avoid button is the same shape at
     * its own size — see {@link Chrome#plate}.
     */
    static final int BUTTON_W = 268;
    /** A menu button's height, frame included. */
    static final int BUTTON_H = 46;
    /** From one menu button's top to the next. */
    static final int BUTTON_PITCH = 56;

    /**
     * How far a pressed plate's label travels, down and to the right — the
     * bevel's own thickness, so the label lands exactly where the recess puts
     * it. {@link Chrome#plate} says why a pressed state exists and why it is not
     * a hover glow.
     */
    static final int SINK = THICK;

    // --- the title ---------------------------------------------------------

    /** The portrait well, whose field is a 216 square inside the frame. */
    static final int WELL_X = 317;
    /** The portrait well's top edge. */
    static final int WELL_Y = 235;
    /** The portrait field's size, square, inside the frame. */
    static final int FIELD = 216;
    /** The Debt at ×3 — the only sprite on any menu, and why the screen is this game. */
    static final int PORTRAIT = Sprites.SIZE * 3;
    /** The band beneath the portrait, in the frame's own colour so the two merge. */
    static final int CAPTION_H = 23;
    /** The portrait field's fill behind The Debt. */
    static final int PORTRAIT_FIELD = 0x0e050c;
    /** The caption under the portrait. */
    static final int CAPTION = 0x6b5f4c;

    /** Everything in the right-hand column shares this left edge. */
    static final int COLUMN_X = 597;
    /** The line over the wordmark. */
    static final int EYEBROW_TOP = 176;
    /** The wordmark's top. */
    static final int WORDMARK_TOP = 215;
    /** A hard offset, not a blur — the same rule the card's value numeral follows. */
    static final int WORDMARK_SHADOW_DY = 4;
    /** The wordmark's shadow. */
    static final int WORDMARK_SHADOW = 0x0a0806;
    /** The rule under the wordmark. */
    static final int TITLE_RULE_Y = 276;
    /** The rule under the wordmark's colour. */
    static final int TITLE_RULE = 0x4a3524;
    /** The cleared-and-best line under the rule. */
    static final int BEST_TOP = 290;
    /** The first menu button's top. */
    static final int BUTTONS_Y = 326;
    /** The credit line at the foot of the title. */
    static final int CREDIT_TOP = 680;
    /** The credit's alpha: present, and no more. */
    static final float CREDIT_ALPHA = 0.22f;

    // The MUSIC and SOUND plates: the menu column's own measures, reused. One row
    // under the fourth button, the column's gap above and between, together exactly
    // its width; the back plate's height, because they are settings, not places to go.
    private static final int AUDIO_GAP = BUTTON_PITCH - BUTTON_H;
    /** The audio plates' top: one row under the four menu buttons. */
    static final int AUDIO_Y = BUTTONS_Y + 4 * BUTTON_PITCH;
    /** An audio plate's width: two of them and a gap span a menu button. */
    static final int AUDIO_W = (BUTTON_W - AUDIO_GAP) / 2;
    /** An audio plate's height, the back plate's. */
    static final int AUDIO_H = ScreenArt.BACK_H;
    /** Inside the bevel: before the label on the left, after the last pip on the right. */
    static final int AUDIO_PAD = 10;
    /** The line under the row that says what M does ({@link Labels#muteHint}). */
    static final int MUTE_HINT_TOP = AUDIO_Y + AUDIO_H + 12;
    /** A level is three pips, whole-pixel bars; a pip lit per step. */
    static final int PIP_W = 6;
    /** A pip's height. */
    static final int PIP_H = 12;
    private static final int PIP_GAP = 4;
    /** How many pips a level plate has: one per step. */
    static final int PIPS = 3;
    /** Lit: the gold every other live thing on the menus is. */
    static final int PIP_ON = GOLD;
    /** A step the level has not reached: a slot sunk into the plate. */
    static final int PIP_OFF = DARK_DARK;
    /** A step reached but muted: the unlit digit's grey, remembered but silent. */
    static final int PIP_MUTED = ScreenArt.WELL_DIGIT_OFF;

    // --- the header band, on every screen except the title -----------------

    /** The header band's height; its rule is drawn from here down, {@link #THICK} thick. */
    static final int HEADER_H = 89;
    /** The screen name's left edge. */
    static final int HEADER_X = 40;
    /** The screen name's top. */
    static final int HEADER_TITLE_TOP = 39;
    /** The caption sits on the title's baseline, not its top. */
    static final int HEADER_CAPTION_TOP = 48;
    /** Between the screen name and its caption. */
    static final int HEADER_CAPTION_GAP = 20;
    /** The caption's colour. */
    static final int HEADER_CAPTION = 0x9a8b70;
    /**
     * The back plate, as a hit-test id. A screen with more than one kind of
     * target hit-tests into one id space — {@link PressGesture} matches a
     * release against a press by equality and cannot know which family an index
     * came from. Panels and buttons are their own index and −1 is nothing, so
     * shared chrome takes the negatives below that.
     */
    static final int BACK = -2;

    /** The back plate's left edge. */
    static final int BACK_X = 1111;
    /** The back plate's top edge. */
    static final int BACK_Y = 27;
    /** The back plate's width. */
    static final int BACK_W = 127;
    /** The back plate's height. */
    static final int BACK_H = 36;

    // --- new game ----------------------------------------------------------

    /** The mode panels' left edge. */
    static final int PANEL_X = 38;
    /** A mode panel's width. */
    static final int PANEL_W = 1200;
    /** A mode panel's height. */
    static final int PANEL_H = 89;
    /** The first mode panel's top. */
    static final int PANEL_Y = 115;
    /** 89 of panel and 14 of gap. */
    static final int PANEL_PITCH = 103;

    /** The numbered well, from the panel's corner. */
    static final int WELL_DX = 20;
    /** The numbered well, from the panel's top. */
    static final int WELL_DY = 18;
    /** The numbered well's size, square. */
    static final int WELL_SIZE = 24;
    /** The mode's name, from the panel's left. */
    static final int NAME_DX = 59;
    /** The mode's name, from the panel's top. */
    static final int NAME_DY = 26;
    /** The trophies badge, from the panel's top. */
    static final int BADGE_DY = 21;
    /** The trophies badge's height. */
    static final int BADGE_H = 19;
    /** Between the mode's name and its badge. */
    static final int BADGE_GAP = 18;
    /** Padding either side of the badge's label. */
    static final int BADGE_PAD_X = 11;
    /** TROPHIES COUNT: the badge's face. */
    static final int BADGE_ON = 0xd9a441;
    /** NO TROPHIES: the badge's face. */
    static final int BADGE_OFF = 0x241d16;
    /** The label on an unearned badge, and on an unselected panel's number. */
    static final int BADGE_OFF_LABEL = 0x6b5f4c;
    /** An unselected panel's number. */
    static final int WELL_DIGIT_OFF = 0x494336;
    /** The START figure, from the panel's top. */
    static final int START_DY = 27;
    /** The START figure, in from the panel's right edge. */
    static final int START_INSET = 24;
    /** The START figure's colour. */
    static final int START_COLOUR = 0x74838f;
    /** The description, from the panel's left. */
    static final int DESC_DX = 20;
    /** The description, from the panel's top. */
    static final int DESC_DY = 58;

    // --- the ledger --------------------------------------------------------

    /** The table: a header row on the frame's own colour, then ten striped rows. */
    static final int TABLE_X = 41;
    /** The table's top edge. */
    static final int TABLE_Y = 111;
    /** The table's width. */
    static final int TABLE_W = 868;
    /** The heading row's height. */
    static final int TABLE_HEAD_H = 29;
    /** How many runs the table holds. */
    static final int LEDGER_ROWS = 10;
    /** A run row's height. */
    static final int ROW_H = 36;

    /**
     * Striping is by <b>flat colour, never alpha</b>. A
     * translucent stripe over the torchlit backdrop would shift down the table
     * as the gradient does, so the rows would not read as one surface.
     */
    static final int ROW_ODD = 0x191513;
    /** The stripe for the second, fourth, ... row. */
    static final int ROW_EVEN = 0x141110;

    /** Column edges. Two of the seven are right-aligned. */
    static final int COL_RUN = 57;
    /** The score column's right edge. */
    static final int COL_SCORE_RIGHT = 166;
    /** The outcome column's left edge. */
    static final int COL_OUTCOME = 189;
    /** The mode column's left edge. */
    static final int COL_MODE = 285;
    /** The date column's left edge. */
    static final int COL_DATE = 389;
    /** The time column's left edge. */
    static final int COL_TIME = 463;
    /** The slain column's right edge. */
    static final int COL_SLAIN_RIGHT = 892;

    /** A score of zero or more: bone. */
    static final int SCORE_POSITIVE = 0xe8ddc7;
    /** A score below zero: dried blood. */
    static final int SCORE_NEGATIVE = 0x8c2f22;
    /** CLEARED, and a win's verdict on the run-end panel. */
    static final int OUTCOME_WON = 0x71b45c;
    /** DEFEATED, YOU DIED, and the dialogs' headings. */
    static final int OUTCOME_LOST = 0x8c2f22;
    /** The dim columns either side of the score: mode, date, time, slain. */
    static final int CELL_QUIET = 0x746d63;

    /** The totals panel beside it: a gold heading, then eight rows split by rules. */
    static final int TOTALS_X = 943;
    /** The totals panel's width. */
    static final int TOTALS_W = 296;
    /** The totals panel's height. */
    static final int TOTALS_H = 310;
    /** The totals heading's top. */
    static final int TOTALS_HEADING_TOP = 130;
    /** The first totals row's top. */
    static final int TOTALS_ROW_Y = 152;
    /** A totals row's height. */
    static final int TOTALS_ROW_H = 32;
    /** How many figures the totals panel holds. */
    static final int TOTALS_ROWS = 8;
    /** The totals labels' left edge. */
    static final int TOTALS_LABEL_X = 959;
    /** The totals values' right edge. */
    static final int TOTALS_VALUE_RIGHT = 1222;

    /** The line where a ledger with nothing in it says so. */
    static final int EMPTY_TOP = 300;

    /**
     * The quiet erase control, under the totals panel and sharing its right
     * edge, in the empty half of the screen where nothing else goes.
     */
    static final int ERASE_W = 232;
    /** The erase plate's height. */
    static final int ERASE_H = 36;
    /** The erase plate's top. */
    static final int ERASE_Y = 648;

    // --- trophies ----------------------------------------------------------

    /**
     * Ten entries, five to a column, filled down then across.
     *
     * <p>Rows are 68 tall on an 82 pitch because the longest description in the
     * catalog runs to 85 characters, so at a size that survives a ×1.5 viewport
     * the descriptions need two lines, and the row has to have somewhere to put
     * the second. There is empty screen below either way.
     */
    static final int TROPHY_X = 37;
    /** The first trophy row's top. */
    static final int TROPHY_Y = 113;
    /** A trophy row's width. */
    static final int TROPHY_W = 582;
    /** A trophy row's height. */
    static final int TROPHY_H = 68;
    /** From one trophy row's top to the next. */
    static final int TROPHY_PITCH = 82;
    /** From the first column's left edge to the second's. */
    static final int TROPHY_COLUMN_PITCH = 614;
    /** How many trophies a column holds. */
    static final int TROPHY_PER_COLUMN = 5;
    /** Two lines of description, and what one line of it may be. */
    static final int TROPHY_DESC_LINES = 2;
    /** From one description line to the next. */
    static final int TROPHY_LINE_H = 16;

    /** The seal, from the row's left. */
    static final int SEAL_DX = 13;
    /** The seal, from the row's top. */
    static final int SEAL_DY = 21;
    /** The seal's size, square. */
    static final int SEAL_SIZE = 26;
    /** The title and description, from the row's left. */
    static final int TROPHY_TEXT_DX = 52;
    /** The title, from the row's top. */
    static final int TROPHY_TITLE_DY = 12;
    /** The description's first line, from the row's top. */
    static final int TROPHY_DESC_DY = 32;
    /** The status, in from the row's right edge. */
    static final int TROPHY_STATUS_INSET = 16;

    /** An earned trophy's row. */
    static final int ROW_EARNED = 0x191513;
    /** A locked trophy's row. */
    static final int ROW_LOCKED = 0x131110;
    /** An earned trophy's seal, filled gold. The empty well <em>is</em> the locked state; there is no padlock glyph. */
    static final int SEAL_EARNED = 0xd9a441;
    /** A locked trophy's seal: an empty well. */
    static final int SEAL_LOCKED = 0x1e1a17;
    /** A locked trophy's text, held back but readable. */
    static final int TROPHY_LOCKED_TEXT = 0x4a3524;

    /** The header's progress bar, built like the board's health bar. */
    static final int PROGRESS_X = 203;
    /** The progress bar's top edge. */
    static final int PROGRESS_Y = 35;
    /** The progress bar's width, frame included. */
    static final int PROGRESS_W = 160;
    /** The progress bar's height, frame included. */
    static final int PROGRESS_H = 20;
    /** From one separator to the next. */
    static final int PROGRESS_SEGMENT = 16;
    /** A separator's width. */
    static final int PROGRESS_GAP = 2;
    /**
     * The empty track is the health bar's own {@link HudArt#BAR_EMPTY}, a dark
     * green under a gold fill — the progress bar is drawn exactly like the HP
     * bar. It looks like an oversight and is not. The separators are the frame
     * colour laid over the track at {@link #PROGRESS_SEGMENT_ALPHA}.
     */
    static final int PROGRESS_EMPTY = HudArt.BAR_EMPTY;
    /** The separators' alpha. */
    static final float PROGRESS_SEGMENT_ALPHA = 0.8f;
    /** Three bands over a 16px interior, lightest at the top, as the bar is drawn. */
    static final int PROGRESS_BAND_TOP = 5;
    /** The middle band's height; the lowest band takes the rest. */
    static final int PROGRESS_BAND_MID = 6;

    // --- the first-run prompt ----------------------------------------------

    /**
     * The one-time welcome, over the title. Its own geometry rather than the
     * menu column's: {@link #buttonY} would put the first plate at 326, where
     * the prompt's second line of copy sits.
     */
    static final int PROMPT_W = 600;
    /** The prompt's height. */
    static final int PROMPT_H = 268;
    /** The prompt's top edge. */
    static final int PROMPT_Y = 226;
    /** The prompt's heading, from its top. */
    static final int PROMPT_HEADING_DY = 30;
    /** The prompt's first line, from its top. */
    static final int PROMPT_LINE_DY = 72;
    /** From the prompt's first line to its second. */
    static final int PROMPT_LINE_GAP = 24;
    /** The prompt's first button, from its top. */
    static final int PROMPT_BUTTON_DY = 132;

    // --- the confirmation dialog -------------------------------------------

    /**
     * A question that must be answered before anything behind it: the ledger's
     * erase and the board's abandon-run. Two lines of copy over two plates side
     * by side, the safe one first, built from the five parts at the ledger's
     * measurements.
     */
    static final int DIALOG_W = 640;
    /** The dialog's height. */
    static final int DIALOG_H = 244;
    /** The dialog's top edge. */
    static final int DIALOG_Y = 238;
    /** The heading, from the dialog's top. */
    static final int DIALOG_HEADING_DY = 28;
    /** The first line, from the dialog's top. */
    static final int DIALOG_LINE_DY = 70;
    /** From the first line to the second. */
    static final int DIALOG_LINE_GAP = 30;
    /** A dialog button's width. */
    static final int DIALOG_BUTTON_W = 244;
    /** The dialog buttons' top edge, on the stage. */
    static final int DIALOG_BUTTON_Y = 396;
    /** Between the two dialog buttons. */
    static final int DIALOG_BUTTON_GAP = 24;

    // --- run end -----------------------------------------------------------

    /**
     * One panel over the dither, covering both outcomes. Held as offsets from
     * the panel's own top, because the panel is not always the same height: a
     * run that unlocked nothing has no rule and no trophy band, and the panel
     * shrinks by {@link #END_TROPHY_BAND} rather than leaving a hole where they
     * would be.
     */
    static final int END_X = 338;
    /** The run-end panel's width. */
    static final int END_W = 600;
    /** The panel's height with the trophy band. */
    static final int END_H = 444;
    /**
     * The rule, the heading and two trophy rows — dropped when nothing unlocked.
     * Even, so the shorter panel is even too and still centres on a whole pixel;
     * an odd height lands it half a pixel off and the frame stops being crisp.
     */
    static final int END_TROPHY_BAND = 114;

    /** The eyebrow, from the panel's top. */
    static final int END_EYEBROW_DY = 34;
    /** The verdict, from the panel's top. */
    static final int END_HEADLINE_DY = 67;
    /** The same hard offset the wordmark uses — an offset, not a blur. */
    static final int END_HEADLINE_SHADOW_DY = 4;

    /** Three figures in one shared frame, split by 2px dividers. */
    static final int END_STATS_X = 376;
    /** The figures' frame, from the panel's top. */
    static final int END_STATS_DY = 118;
    /** The figures' frame's width. */
    static final int END_STATS_W = 524;
    /** The figures' frame's height. */
    static final int END_STATS_H = 71;
    /** A figure's label, from the frame's top. */
    static final int END_STAT_LABEL_DY = 13;
    /** A figure's value, from the frame's top. */
    static final int END_STAT_VALUE_DY = 33;

    /** The new-best badge, from the panel's top. */
    static final int END_BADGE_DY = 207;
    /** The new-best badge's height. */
    static final int END_BADGE_H = 26;
    /** Padding either side of the badge's label. */
    static final int END_BADGE_PAD_X = 18;

    /** The rule over the trophy band: its left end. */
    static final int END_RULE_X = 372;
    /** The rule, from the panel's top. */
    static final int END_RULE_DY = 255;
    /** The rule's length. */
    static final int END_RULE_W = 532;

    /** The trophy band's heading, from the panel's top. */
    static final int END_UNLOCKED_DY = 276;
    /** The trophy band's left edge: the heading and the seals. */
    static final int END_UNLOCKED_X = 372;
    /** The first unlocked trophy's row, from the panel's top. */
    static final int END_TROPHY_DY = 298;
    /** From one unlocked trophy's row to the next. */
    static final int END_TROPHY_PITCH = 30;
    /** An unlocked trophy's seal, square. */
    static final int END_TROPHY_SEAL = 22;
    /** The trophy's name, from the seal's left. */
    static final int END_TROPHY_NAME_DX = 34;
    /** Between the trophy's name and its description. */
    static final int END_TROPHY_DESC_GAP = 14;
    /** Two fit above the buttons; a run cannot realistically unlock more at once. */
    static final int END_TROPHIES_SHOWN = 2;
    /**
     * Where an unlocked trophy's description must stop: the rule's right end, the
     * panel's own margin. A description wraps within it rather than running off
     * the panel.
     */
    static final int END_TEXT_RIGHT = END_RULE_X + END_RULE_W;
    /** A long description takes a second line beside the name, sharing the seal's height. */
    static final int END_TROPHY_DESC_LINES = 2;

    /** The button row, from the panel's top (with the trophy band). */
    static final int END_BUTTONS_DY = 376;
    /** A run-end button's height. */
    static final int END_BUTTON_H = 38;
    /** Between run-end buttons. */
    static final int END_BUTTON_GAP = 10;
    /** Padding either side of a run-end button's label; the tutorial's NEXT uses it too. */
    static final int END_BUTTON_PAD_X = 22;

    // --- the tutorial overlay ----------------------------------------------

    /**
     * The callout's width. The narration is set at 14 and its longest beat runs
     * to 296 characters, so the panel is made wide rather than the words small.
     */
    static final int CALLOUT_W = 600;
    /** Padding either side of the callout's text. */
    static final int CALLOUT_PAD_X = 18;
    /** The STEP line, from the callout's top. */
    static final int CALLOUT_STEP_TOP = 16;
    /** The narration's first line, from the callout's top. */
    static final int CALLOUT_TEXT_TOP = 44;
    /** From one narration line to the next. */
    static final int CALLOUT_LINE_H = 24;
    /**
     * The most lines a callout holds; anything past the last line joins it
     * rather than being cut (see {@link TextWrap}). The panel grows to fit — the
     * tutorial's whole job is saying things, and its longest beat runs to 296
     * characters.
     */
    static final int CALLOUT_MAX_LINES = 6;
    /** Between the callout and the card it points at. */
    static final int CALLOUT_GAP = 13;
    /** Padding under the callout's last line. */
    static final int CALLOUT_BOTTOM_PAD = 12;

    /** One dot per beat, the current one gold. */
    static final int DOT_SIZE = 6;
    /** From one dot to the next. */
    static final int DOT_PITCH = 8;
    /** A beat reached. */
    static final int DOT_ON = 0xd9a441;
    /** A beat still to come. */
    static final int DOT_OFF = 0x3a2e26;

    /** The viewfinder ticks around the card being taught, and the Skip plate. */
    static final int TICK_COLOUR = 0xf7f0dc;
    /** The Skip plate's width. */
    static final int SKIP_W = 166;
    /** The Skip plate's height; the callout's NEXT plate shares it. */
    static final int SKIP_H = 36;
    /**
     * Bottom right, but lifted clear of the potion marker, which occupies the
     * bottom strip from {@link BoardArt#MARKER_Y}.
     */
    static final int SKIP_Y = BoardArt.MARKER_Y - SKIP_H - 20;
    /** The Skip plate, in from the stage's right edge. */
    static final int SKIP_INSET = 45;

    private ScreenArt() {
    }

    /**
     * The callout is as tall as its heading, its own lines and its padding make
     * it, plus a Next plate on an explanation beat. A fixed height either
     * truncated the long steps or left the short ones half empty.
     *
     * @param lines   how many lines the narration wrapped to
     * @param hasNext whether the beat is an explanation, with a NEXT plate
     * @return the callout's height
     */
    static int calloutH(int lines, boolean hasNext) {
        int h = CALLOUT_TEXT_TOP + lines * CALLOUT_LINE_H + CALLOUT_BOTTOM_PAD;
        return hasNext ? h + SKIP_H + CALLOUT_BOTTOM_PAD / 2 : h;
    }

    /**
     * How wide a line of narration may be.
     *
     * @return the callout's width less its padding
     */
    static int calloutTextWidth() {
        return CALLOUT_W - 2 * CALLOUT_PAD_X;
    }

    /**
     * The Skip plate's left edge.
     *
     * @return {@link #SKIP_INSET} in from the stage's right edge
     */
    static int skipX() {
        return (int) Theme.WORLD_WIDTH - SKIP_W - SKIP_INSET;
    }

    /**
     * Which of the three stat cells a column index covers, inside the shared frame.
     *
     * @param index the cell, 0 to 2
     * @return the cell's left edge
     */
    static int endCellX(int index) {
        return END_STATS_X + index * (END_STATS_W + THICK) / 3;
    }

    /**
     * A stat cell's width, the dividers taken out.
     *
     * @return the width of each of the three cells
     */
    static int endCellW() {
        return (END_STATS_W - 2 * THICK) / 3;
    }

    /**
     * Shorter by the trophy band when the run unlocked nothing.
     *
     * @param withTrophies whether the run unlocked anything
     * @return the panel's height
     */
    static int endH(boolean withTrophies) {
        return withTrophies ? END_H : END_H - END_TROPHY_BAND;
    }

    /**
     * The panel stays centred whichever height it is.
     *
     * @param withTrophies whether the run unlocked anything
     * @return the panel's top edge
     */
    static int endY(boolean withTrophies) {
        return ((int) Theme.WORLD_HEIGHT - endH(withTrophies)) / 2;
    }

    /**
     * The button row's top, below the trophy band or where it would have been.
     *
     * @param withTrophies whether the run unlocked anything
     * @return the buttons' top edge
     */
    static int endButtonsY(boolean withTrophies) {
        return endY(withTrophies) + (withTrophies ? END_BUTTONS_DY
                : END_BUTTONS_DY - END_TROPHY_BAND);
    }

    /**
     * An unlocked trophy's row on the run-end panel.
     *
     * @param index the trophy, from 0
     * @return the row's top edge
     */
    static int endTrophyY(int index) {
        return endY(true) + END_TROPHY_DY + index * END_TROPHY_PITCH;
    }

    /**
     * How wide a description beginning at {@code descX} may run before the margin.
     *
     * @param descX where the description starts
     * @return the room it has, up to {@link #END_TEXT_RIGHT}
     */
    static int endTrophyDescWidth(int descX) {
        return END_TEXT_RIGHT - descX;
    }

    /**
     * Each line's share of the seal's height: all of it for one, half each for two.
     *
     * @param lines how many lines the description wrapped to, 1 or more
     * @return one line's height
     */
    static int endTrophyLineH(int lines) {
        return END_TROPHY_SEAL / lines;
    }

    /**
     * The top of a description line's share, the lines stacked down the seal.
     *
     * @param rowY  the trophy row's top edge
     * @param line  which line, from 0
     * @param lines how many lines there are
     * @return that line's share's top edge
     */
    static int endTrophyLineY(int rowY, int line, int lines) {
        return rowY + line * endTrophyLineH(lines);
    }

    /**
     * The table's height follows from the rows it actually holds, so the frame
     * and the striping cannot disagree — a fixed height with four runs in it
     * would leave the bottom of the table hanging empty.
     *
     * @param rows how many runs the table holds, 0 to {@link #LEDGER_ROWS}
     * @return the table's height, frame included
     */
    static int tableH(int rows) {
        return TABLE_HEAD_H + rows * ROW_H + THICK;
    }

    /**
     * A run row's top, under the heading row.
     *
     * @param index the row, from 0 (the best run)
     * @return its top edge
     */
    static int ledgerRowY(int index) {
        return TABLE_Y + TABLE_HEAD_H + index * ROW_H;
    }

    /**
     * Each totals row carries a 2px rule at its foot, except the last.
     *
     * @param index the row, from 0
     * @return its top edge
     */
    static int totalsRowY(int index) {
        return TOTALS_ROW_Y + index * TOTALS_ROW_H;
    }

    /**
     * The totals panel's right edge, which the erase plate shares.
     *
     * @return the right edge
     */
    static int totalsRight() {
        return TOTALS_X + TOTALS_W;
    }

    /**
     * The erase plate's left edge, right-aligned under the totals panel.
     *
     * @return the left edge
     */
    static int eraseX() {
        return totalsRight() - ERASE_W;
    }

    /**
     * Down the first column, then down the second — the order the catalog is in.
     *
     * @param index the trophy's place in the catalog, from 0
     * @return its row's left edge
     */
    static int trophyX(int index) {
        return TROPHY_X + (index / TROPHY_PER_COLUMN) * TROPHY_COLUMN_PITCH;
    }

    /**
     * A trophy row's top, down its column.
     *
     * @param index the trophy's place in the catalog, from 0
     * @return its row's top edge
     */
    static int trophyY(int index) {
        return TROPHY_Y + (index % TROPHY_PER_COLUMN) * TROPHY_PITCH;
    }

    /**
     * How wide a description line may be before the row's right inset.
     *
     * @return the width
     */
    static int trophyTextWidth() {
        return TROPHY_W - TROPHY_TEXT_DX - TROPHY_STATUS_INSET;
    }

    /**
     * How much of the progress bar is filled, in whole pixels of its interior.
     *
     * @param earned trophies earned, 0 or more
     * @param total  trophies in the catalog
     * @return the filled width, 0 up to the interior's width
     */
    static int progressFillWidth(int earned, int total) {
        if (total <= 0 || earned <= 0) {
            return 0;
        }
        int interior = PROGRESS_W - 2 * THICK;
        return Math.round(interior * Math.min(earned, total) / (float) total);
    }

    /**
     * A mode panel's top.
     *
     * @param index the mode, in menu order, from 0
     * @return the panel's top edge
     */
    static int panelY(int index) {
        return PANEL_Y + index * PANEL_PITCH;
    }

    /**
     * The right edge everything in a panel is right-aligned against.
     *
     * @return the panels' right edge
     */
    static int panelRight() {
        return PANEL_X + PANEL_W;
    }

    /**
     * Which mode panel a point in <b>world</b> coordinates is on, or -1. Same
     * flip as everywhere else: the pointer arrives y-up, the panels are
     * specified y-down.
     *
     * @param count  how many panels there are
     * @param worldX the point's x, in world space
     * @param worldY the point's y, in world space (y up)
     * @return the panel's index, or -1
     */
    static int panelAt(int count, float worldX, float worldY) {
        if (worldX < PANEL_X || worldX >= PANEL_X + PANEL_W) {
            return -1;
        }
        for (int i = 0; i < count; i++) {
            float bottom = CardArt.toWorldY(panelY(i), PANEL_H);
            if (worldY >= bottom && worldY < bottom + PANEL_H) {
                return i;
            }
        }
        return -1;
    }

    /**
     * And whether a point is on the header's back button.
     *
     * @param worldX the point's x, in world space
     * @param worldY the point's y, in world space (y up)
     * @return true if the point is on the back plate
     */
    static boolean backContains(float worldX, float worldY) {
        float bottom = CardArt.toWorldY(BACK_Y, BACK_H);
        return worldX >= BACK_X && worldX < BACK_X + BACK_W
                && worldY >= bottom && worldY < bottom + BACK_H;
    }

    /**
     * The portrait field's left edge, inside the well's frame.
     *
     * @return the left edge
     */
    static int fieldX() {
        return WELL_X + THICK;
    }

    /**
     * The portrait field's top edge, inside the well's frame.
     *
     * @return the top edge
     */
    static int fieldY() {
        return WELL_Y + THICK;
    }

    /**
     * The portrait well's width, frame included.
     *
     * @return the width
     */
    static int wellW() {
        return FIELD + 2 * THICK;
    }

    /**
     * The portrait well's height: the field and the caption band, frame included.
     *
     * @return the height
     */
    static int wellH() {
        return FIELD + CAPTION_H + 2 * THICK;
    }

    /**
     * The portrait is centred in the field; 216 − 192 leaves 12 a side.
     *
     * @return the portrait's left edge
     */
    static int portraitX() {
        return fieldX() + (FIELD - PORTRAIT) / 2;
    }

    /**
     * The portrait's top, centred in the field.
     *
     * @return the portrait's top edge
     */
    static int portraitY() {
        return fieldY() + (FIELD - PORTRAIT) / 2;
    }

    /**
     * The caption band's top, under the field.
     *
     * @return the band's top edge
     */
    static int captionY() {
        return fieldY() + FIELD;
    }

    /**
     * A menu button's top.
     *
     * @param index the button, from 0 at the top
     * @return its top edge
     */
    static int buttonY(int index) {
        return BUTTONS_Y + index * BUTTON_PITCH;
    }

    /**
     * 0 is MUSIC, 1 is SOUND.
     *
     * @param index the plate, 0 or 1
     * @return its left edge
     */
    static int audioPlateX(int index) {
        return COLUMN_X + index * (AUDIO_W + AUDIO_GAP);
    }

    /**
     * Which audio plate a world point is on — 0 MUSIC, 1 SOUND — or -1, the gap between included.
     *
     * @param worldX the point's x, in world space
     * @param worldY the point's y, in world space (y up)
     * @return 0, 1 or -1
     */
    static int audioPlateAt(float worldX, float worldY) {
        float bottom = CardArt.toWorldY(AUDIO_Y, AUDIO_H);
        if (worldY < bottom || worldY >= bottom + AUDIO_H) {
            return -1;
        }
        for (int i = 0; i < 2; i++) {
            int x = audioPlateX(i);
            if (worldX >= x && worldX < x + AUDIO_W) {
                return i;
            }
        }
        return -1;
    }

    /**
     * The left edge of a pip, the three right-aligned against the plate's padding.
     *
     * @param plateX the plate's left edge
     * @param pip    the pip, from 0 on the left to {@code PIPS - 1}
     * @return the pip's left edge
     */
    static int pipX(int plateX, int pip) {
        int right = plateX + AUDIO_W - 2 * THICK - AUDIO_PAD;
        return right - (PIPS - pip) * PIP_W - (PIPS - 1 - pip) * PIP_GAP;
    }

    /**
     * The pips' top, centred down the plate.
     *
     * @return the pips' top edge
     */
    static int pipY() {
        return AUDIO_Y + (AUDIO_H - PIP_H) / 2;
    }

    /**
     * A pip's colour: lit up to the level, dimmed while muted, a sunk slot past it.
     *
     * @param pip   the pip, from 0
     * @param level the plate's level, 0 to {@link #PIPS}
     * @param muted whether everything is muted
     * @return {@link #PIP_ON}, {@link #PIP_MUTED} or {@link #PIP_OFF}
     */
    static int pipColour(int pip, int level, boolean muted) {
        if (pip >= level) {
            return PIP_OFF;
        }
        return muted ? PIP_MUTED : PIP_ON;
    }

    /**
     * The first-run prompt's left edge, centred on the stage.
     *
     * @return the left edge
     */
    static int promptX() {
        return (int) (Theme.WORLD_WIDTH - PROMPT_W) / 2;
    }

    /**
     * The prompt's plates are centred on the stage, not on the menu column.
     *
     * @return the plates' left edge
     */
    static int promptButtonX() {
        return (int) (Theme.WORLD_WIDTH - BUTTON_W) / 2;
    }

    /**
     * A prompt button's top.
     *
     * @param index the button, 0 or 1
     * @return its top edge
     */
    static int promptButtonY(int index) {
        return PROMPT_Y + PROMPT_BUTTON_DY + index * BUTTON_PITCH;
    }

    /**
     * Which of the prompt's two buttons a world point is on, or -1.
     *
     * @param worldX the point's x, in world space
     * @param worldY the point's y, in world space (y up)
     * @return 0, 1 or -1
     */
    static int promptButtonAt(float worldX, float worldY) {
        int x = promptButtonX();
        if (worldX < x || worldX >= x + BUTTON_W) {
            return -1;
        }
        for (int i = 0; i < 2; i++) {
            float bottom = CardArt.toWorldY(promptButtonY(i), BUTTON_H);
            if (worldY >= bottom && worldY < bottom + BUTTON_H) {
                return i;
            }
        }
        return -1;
    }

    /**
     * The dialog's left edge, centred on the stage.
     *
     * @return the left edge
     */
    static int dialogX() {
        return (int) (Theme.WORLD_WIDTH - DIALOG_W) / 2;
    }

    /**
     * A dialog button's left edge; the pair is centred on the stage.
     *
     * @param index the button, 0 (the safe one) or 1
     * @return its left edge
     */
    static int dialogButtonX(int index) {
        int span = 2 * DIALOG_BUTTON_W + DIALOG_BUTTON_GAP;
        int left = (int) (Theme.WORLD_WIDTH - span) / 2;
        return left + index * (DIALOG_BUTTON_W + DIALOG_BUTTON_GAP);
    }

    /**
     * Which of the dialog's two buttons a world point is on, or -1.
     *
     * @param worldX the point's x, in world space
     * @param worldY the point's y, in world space (y up)
     * @return 0, 1 or -1
     */
    static int dialogButtonAt(float worldX, float worldY) {
        float bottom = CardArt.toWorldY(DIALOG_BUTTON_Y, BUTTON_H);
        if (worldY < bottom || worldY >= bottom + BUTTON_H) {
            return -1;
        }
        for (int i = 0; i < 2; i++) {
            int x = dialogButtonX(i);
            if (worldX >= x && worldX < x + DIALOG_BUTTON_W) {
                return i;
            }
        }
        return -1;
    }

    /**
     * Which button of a column a point in <b>world</b> coordinates is on, or -1
     * — including the gaps between them, which must not activate anything. The
     * pointer arrives with y upward and the buttons are specified with y
     * downward, so the flip happens here rather than at every call.
     *
     * @param x      the column's left edge
     * @param count  how many buttons the column has
     * @param worldX the point's x, in world space
     * @param worldY the point's y, in world space (y up)
     * @return the button's index from 0 at the top, or -1
     */
    static int buttonAt(int x, int count, float worldX, float worldY) {
        if (worldX < x || worldX >= x + BUTTON_W) {
            return -1;
        }
        for (int i = 0; i < count; i++) {
            float bottom = CardArt.toWorldY(buttonY(i), BUTTON_H);
            if (worldY >= bottom && worldY < bottom + BUTTON_H) {
                return i;
            }
        }
        return -1;
    }
}
