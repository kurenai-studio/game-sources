//
//  ball.c
//  raylib-test
//
//  Created by Gabriele Pappalardo on 04/04/2020.
//  Copyright © 2020 Gabriele Pappalardo. All rights reserved.
//

#include <stdlib.h>
#include <stdio.h>

#include "ball.h"
#include "game.h"

extern unsigned int playerOneScore_g;
extern unsigned int playerTwoScore_g;

void MoveBall(ball* b, Rectangle p1, Rectangle p2, GameState* state) {
    
    b->rect.x = b->rect.x + b->velocity.x;
    b->rect.y = b->rect.y + b->velocity.y;
    
    bool collisionP1 = CheckCollisionRecs(b->rect, p1), collisionP2 = CheckCollisionRecs(b->rect, p2);
    
    if (collisionP1 || collisionP2) {
        
        b->velocity.x = -b->velocity.x;
        b->velocity.y = ((arc4random() % 10) + 1);
        
        if (collisionP1) b->rect.x = p1.x + b->rect.width;
        if (collisionP2) b->rect.x = p2.x - b->rect.width;

    }
    
    if (b->rect.y >= SCREEN_HEIGHT) {
        b->rect.y = SCREEN_HEIGHT - b->rect.height / 2;
        b->velocity.y = -b->velocity.y;
    }
    
    if (b->rect.y <= b->rect.height / 2) {
        b->rect.y = b->rect.height / 2;
        b->velocity.y = -b->velocity.y;
    }
    
    if (b->rect.x >= SCREEN_WIDTH) {
        playerOneScore_g++;
        b->rect.x = p2.x - p2.width - 8;
        b->velocity.x = 0;
        *state = PLAYER_TWO_SERVE;
    }
    if (b->rect.x <= 0) {
        playerTwoScore_g++;
        b->rect.x = p1.x + p1.width + 8;
        b->velocity.x = 0;
        *state = PLAYER_ONE_SERVE;
    }

}
