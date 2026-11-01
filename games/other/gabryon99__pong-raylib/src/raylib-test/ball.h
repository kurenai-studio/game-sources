//
//  ball.h
//  raylib-test
//
//  Created by Gabriele Pappalardo on 04/04/2020.
//  Copyright © 2020 Gabriele Pappalardo. All rights reserved.
//

#include <raylib.h>
#include "game.h"

#ifndef ball_h
#define ball_h

struct ball {
    Rectangle rect;
    Vector2 velocity;
};

typedef struct ball ball;

void MoveBall(ball*, Rectangle, Rectangle, GameState* state);

#endif /* ball_h */
