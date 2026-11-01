//
//  paddle.h
//  raylib-test
//
//  Created by Gabriele Pappalardo on 04/04/2020.
//  Copyright © 2020 Gabriele Pappalardo. All rights reserved.
//

#include <raylib.h>

#include "game.h"
#include "ball.h"

#ifndef paddle_h
#define paddle_h

#define OFFSET_Y 10

#define SET_PADDLE_POSITION(p, x0, y0) \
    p.rect.x = x0; p.rect.y = y0;

#define SET_PADDLE_SIZE(p, w, h) \
    p.rect.width = w; p.rect.height = h;

#define SET_PADDLE_INPUT(p, up, down) \
    p.input.upKey = up; p.input.downKey = down;

#define DRAW_PADDLE(p) \
    DrawRectangle(p.rect.x, p.rect.y, p.rect.width, p.rect.height, WHITE);


struct paddle {
    Rectangle rect;
    Vector2 velocity;
    struct InputKey {
        KeyboardKey upKey;
        KeyboardKey downKey;
    } input;
};

typedef struct paddle paddle;

void MovePaddle(paddle* p);
void PaddleAI(paddle* p, ball b);

#endif /* paddle_h */
