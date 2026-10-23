/*
 * snake-gui: A graphical snake game in C using raylib
 *
 * Author:  sejjy <sejjymvm@gmail.com>
 * Date:    October 16, 2026
 * License: MIT
 */

#include "raylib.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define TIMEOUT       0.15f
#define GRID_WIDTH    20
#define GRID_HEIGHT   20
#define GRID_SIZE     (GRID_WIDTH * GRID_HEIGHT)
#define RECT_SIZE     32
#define FONT_SIZE     24
#define WINDOW_WIDTH  ((GRID_WIDTH  + 2) * RECT_SIZE)
#define WINDOW_HEIGHT ((GRID_HEIGHT + 2) * RECT_SIZE)
#define COLOR_BG      BLACK
#define COLOR_TEXT    WHITE
#define COLOR_EMPTY   DARKGRAY
#define COLOR_HEAD    GREEN
#define COLOR_BODY    DARKGREEN
#define COLOR_APPLE   RED

typedef struct {
	int x;
	int y;
} vec2;

RenderTexture2D window;
Font font;
float timeout;
int score;
int hiscore;
int snake_size;
int tail_idx;
int head_idx;
vec2 prev_tail_pos;
vec2 prev_head_pos;
vec2 snake[GRID_SIZE];
vec2 dir;
vec2 next_head_pos;
vec2 apple;
bool snake_collided;
bool apple_consumed;
bool occupied[GRID_HEIGHT][GRID_WIDTH];
bool finished;

void init_window(void);
void init_state(void);
void update_apple_pos(void);
void init_drawing(void);
void print_scores(void);
void draw_walls(void);
void draw_char(int y, int x, Color color);
void print_controls(void);
bool read_input(void);
void update_state(void);
void update_drawing(void);

int main(void)
{
	hiscore = 0;
	timeout = TIMEOUT;

	srand((unsigned)time(NULL));

	init_window();
	init_state();
	init_drawing();

	for (;;) {
		if (!read_input())
			break;

		update_state();
		update_drawing();

		if (snake_collided || finished) {
			hiscore = score > hiscore ? score : hiscore;
			timeout = -1.0f;

			if (!read_input())
				break;

			timeout = TIMEOUT;
			init_state();
			init_drawing();
		}
	}

	UnloadRenderTexture(window);
	UnloadFont(font);
	CloseWindow();

	printf("score: %3d   hiscore: %3d\n", score, hiscore);

	return 0;
}

void init_window(void)
{
	InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Snake");
	SetTargetFPS(60);
	window = LoadRenderTexture(WINDOW_WIDTH, WINDOW_HEIGHT);
	font = LoadFontEx("PixelCode.ttf", FONT_SIZE, NULL, 0);
}

void init_state(void)
{
	int x, y;

	score = 0;
	snake_size = 2;
	tail_idx = 0;
	head_idx = 1;
	snake[tail_idx].x = GRID_WIDTH / 4;
	snake[tail_idx].y = GRID_HEIGHT / 2;
	snake[head_idx].x = snake[tail_idx].x + 1;
	snake[head_idx].y = snake[tail_idx].y;
	dir.x = 1;
	dir.y = 0;

	for (y = 0; y < GRID_HEIGHT; y++)
		for (x = 0; x < GRID_WIDTH; x++)
			occupied[y][x] = false;

	occupied[snake[tail_idx].y][snake[tail_idx].x] = true;
	occupied[snake[head_idx].y][snake[head_idx].x] = true;

	update_apple_pos();
}

void update_apple_pos(void)
{
	do {
		apple.x = rand() % GRID_WIDTH;
		apple.y = rand() % GRID_HEIGHT;
	} while (occupied[apple.y][apple.x]);
}

void init_drawing(void)
{
	int x, y;

	BeginTextureMode(window);

	ClearBackground(COLOR_BG);
	print_scores();
	draw_walls();

	for (y = 0; y < GRID_HEIGHT; y++)
		for (x = 0; x < GRID_WIDTH; x++)
			draw_char(y, x, COLOR_EMPTY);

	draw_char(snake[tail_idx].y, snake[tail_idx].x, COLOR_BODY);
	draw_char(snake[head_idx].y, snake[head_idx].x, COLOR_HEAD);
	draw_char(apple.y, apple.x, COLOR_APPLE);

	print_controls();

	EndTextureMode();
}

void print_scores(void)
{
	DrawRectangle(0, 0, WINDOW_WIDTH, RECT_SIZE - 2, COLOR_BG);
	DrawTextEx(font,
	           TextFormat("score: %3d   hiscore: %3d", score, hiscore),
	           (Vector2){ RECT_SIZE + RECT_SIZE / 3.0f, 5 },
	           FONT_SIZE, 0, COLOR_TEXT);
}

void draw_walls(void)
{
	DrawRectangleLinesEx((Rectangle){ RECT_SIZE - 2,
	                                  RECT_SIZE - 2,
	                                  GRID_WIDTH  * RECT_SIZE + 4,
	                                  GRID_HEIGHT * RECT_SIZE + 4 },
	                     2, COLOR_EMPTY);
}

void draw_char(int y, int x, Color color)
{
	x = (1 + x) * RECT_SIZE;
	y = (1 + y) * RECT_SIZE;

	DrawRectangle(x, y, RECT_SIZE, RECT_SIZE, COLOR_BG);
	if (!ColorIsEqual(color, COLOR_EMPTY)) {
		DrawRectangle(x + 2,
		              y + 2,
		              RECT_SIZE - 2 * 2,
		              RECT_SIZE - 2 * 2,
		              color);
		return;
	}

	DrawRectangle(x + RECT_SIZE / 2 - 1,
	              y + RECT_SIZE / 2 - 1,
	              2,
	              2,
	              COLOR_EMPTY);
}

void print_controls(void)
{
	DrawTextEx(font,
	           "move: w a s d   exit: esc",
	           (Vector2){ RECT_SIZE + RECT_SIZE / 3.0f,
	                      WINDOW_HEIGHT - RECT_SIZE + 2 },
	           FONT_SIZE, 0, COLOR_TEXT);
}

bool read_input(void)
{
	int pressed = 0;
	double start = GetTime();

	do {
		if (WindowShouldClose())
			return false;

		if (timeout >= 0 && GetTime() - start >= timeout)
			break;

		BeginDrawing();
		DrawTextureRec(window.texture,
		               (Rectangle){ 0, 0, WINDOW_WIDTH, -WINDOW_HEIGHT },
		               (Vector2){ 0, 0 }, WHITE);
		EndDrawing();
	} while ((pressed = GetKeyPressed()) == 0);

	switch (pressed) {
		case KEY_W:
			if (dir.y != 1) {
				dir.x = 0;
				dir.y = -1;
			}
			break;
		case KEY_A:
			if (dir.x != 1) {
				dir.x = -1;
				dir.y = 0;
			}
			break;
		case KEY_S:
			if (dir.y != -1) {
				dir.x = 0;
				dir.y = 1;
			}
			break;
		case KEY_D:
			if (dir.x != -1) {
				dir.x = 1;
				dir.y = 0;
			}
			break;
		case KEY_ESCAPE:
			return false;
			break;
	}

	return true;
}

void update_state(void)
{
	next_head_pos.x = snake[head_idx].x + dir.x;
	next_head_pos.y = snake[head_idx].y + dir.y;

	snake_collided = false;
	if (next_head_pos.x < 0 || next_head_pos.x >= GRID_WIDTH ||
	    next_head_pos.y < 0 || next_head_pos.y >= GRID_HEIGHT)
		snake_collided = true;
	else if (occupied[next_head_pos.y][next_head_pos.x] &&
	        (next_head_pos.x != snake[tail_idx].x ||
	         next_head_pos.y != snake[tail_idx].y))
		snake_collided = true;

	apple_consumed = next_head_pos.x == apple.x &&
	                 next_head_pos.y == apple.y;

	prev_tail_pos = snake[tail_idx];
	prev_head_pos = snake[head_idx];

	if (snake_collided)
		return;

	if (!apple_consumed) {
		occupied[prev_tail_pos.y][prev_tail_pos.x] = false;
		tail_idx = (tail_idx + 1) % GRID_SIZE;
	}

	occupied[next_head_pos.y][next_head_pos.x] = true;
	head_idx = (head_idx + 1) % GRID_SIZE;

	if (apple_consumed) {
		score += 1;
		snake_size += 1;
		finished = snake_size == GRID_SIZE;

		if (!finished)
			update_apple_pos();
	}

	snake[head_idx] = next_head_pos;
}

void update_drawing(void)
{
	BeginTextureMode(window);

	if (!apple_consumed)
		draw_char(prev_tail_pos.y, prev_tail_pos.x, COLOR_EMPTY);

	draw_char(prev_head_pos.y, prev_head_pos.x, COLOR_BODY);
	draw_char(next_head_pos.y, next_head_pos.x, COLOR_HEAD);

	if (apple_consumed) {
		if (!finished)
			draw_char(apple.y, apple.x, COLOR_APPLE);
		print_scores();
	}

	EndTextureMode();
}
