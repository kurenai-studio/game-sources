//
//  paddle.c
//  raylib-test
//
//  Created by Gabriele Pappalardo on 04/04/2020.
//  Copyright © 2020 Gabriele Pappalardo. All rights reserved.
//

#include "game.h"
#include "paddle.h"
#include "ball.h"
#include <raymath.h>
#include <stdlib.h>

static float paddleAITime = 0.0f;

void MovePaddle(paddle* p) {
    if (IsKeyDown(p->input.upKey)) p->rect.y -= p->velocity.y;
    if (IsKeyDown(p->input.downKey)) p->rect.y += p->velocity.y;
    // Clamp player position
    if (p->rect.y <= OFFSET_Y) p->rect.y = OFFSET_Y;
    if (p->rect.y >= SCREEN_HEIGHT - p->rect.height - OFFSET_Y) p->rect.y = SCREEN_HEIGHT - p->rect.height - OFFSET_Y;
}

void PaddleAI(paddle* p, ball b) {
    
    paddleAITime += GetFrameTime() / ((arc4random() % 2) + 1);
    float pos = Lerp(p->rect.y, b.rect.y, paddleAITime);
    p->rect.y = pos;
    
    if (paddleAITime >= 1) paddleAITime = 0;
    
    // Clamp player position
    if (p->rect.y <= OFFSET_Y) p->rect.y = OFFSET_Y;
    if (p->rect.y >= SCREEN_HEIGHT - p->rect.height - OFFSET_Y) p->rect.y = SCREEN_HEIGHT - p->rect.height - OFFSET_Y;
    
    return;
}
