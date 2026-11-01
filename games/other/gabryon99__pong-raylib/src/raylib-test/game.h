//
//  game.h
//  raylib-test
//
//  Created by Gabriele Pappalardo on 04/04/2020.
//  Copyright © 2020 Gabriele Pappalardo. All rights reserved.
//

#ifndef game_h
#define game_h

#define SCREEN_WIDTH 800
#define SCREEN_HEIGHT 600
#define FPS 60

enum GameState {
    IDLE,
    PLAYING,
    PLAYER_ONE_SERVE,
    PLAYER_TWO_SERVE
};

typedef enum GameState GameState;

#endif /* game_h */
