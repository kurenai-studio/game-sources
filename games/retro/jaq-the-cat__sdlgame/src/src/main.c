#include <SDL2/SDL.h>
#include <SDL2/SDL_rect.h>
#include <SDL2/SDL_image.h>
#include <SDL2/SDL_render.h>
#include <SDL2/SDL_timer.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include "conf.h"
#include "entity.h"

#include "game.h"

// globals
extern bool close;
extern entities es;

SDL_Window *win;
SDL_Renderer *rend;

void init() {
    if (SDL_Init(SDL_INIT_EVERYTHING) != 0)
        printf("Error initializing SDL: %s\n", SDL_GetError());
    win = SDL_CreateWindow(
        "SDL Game",
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        WIDTH, HEIGHT,
        0);
    rend = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    IMG_Init(IMG_INIT_PNG);
}

int run() {
    init();

    // game start
    start(&es);

    SDL_Event event;
    while (!close) {
        SDL_Event event;

        // Events mangement
        SDL_PollEvent(&event);
        switch (event.type) {
        case SDL_QUIT:
            close = true;
            break;
        case SDL_KEYDOWN:
            if (event.key.keysym.scancode == SDL_SCANCODE_ESCAPE) {
                close = true;
                break;
            }
        }

        // update stuff
        close = gupdate(&es, &event);
        eupdate(update);

        // Clear screen
        SDL_SetRenderDrawColor(rend, BACKGROUND, 255);
        SDL_RenderClear(rend);

        // Render stuff
        erender(render);

        // Draw to screen
        SDL_RenderPresent(rend);
    }

    // game end
    end();
    efree(destroy);

    IMG_Quit();
    SDL_DestroyRenderer(rend);
    SDL_DestroyWindow(win);
    SDL_Quit();

    return EXIT_SUCCESS;
}
