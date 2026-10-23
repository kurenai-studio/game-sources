#include "../game.h"

#include <SDL2/SDL_image.h>

#include "gjk.h"
#include "entities.h"

#define MOVESPEED 10

extern SDL_Renderer *rend;

typedef struct {
    bool w, a, s, d, space;
} keys;

keys kb = {};
entity *player;

void start(entities *es) {
    player = makeentity((entity) {
        .type = PLAYER,
        .origin = {0.f, 0.f},
        .velocity = {0.f, .0f},
        .size = {64.f, 64.f},
        .gravity = 1.f,
        .texture = IMG_LoadTexture(rend, "sprites/player.png"),
    }); // player
    eadd(player);

    for (int i=0; i<20; i++) {
        eadd(makeentity((entity) {
            .type = OBJECT,
            .origin = {i*64, 64*2},
            .velocity = {0, 0},
            .size = {64, 64},
            .gravity = 0,
            .texture = IMG_LoadTexture(rend, "sprites/ground.png"),
        })); // player
    }

    for (int i=0; i<20; i++) {
        eadd(makeentity((entity) {
            .type = OBJECT,
            .origin = {i*64, 64*6},
            .velocity = {0, 0},
            .size = {64, 64},
            .gravity = 0,
            .texture = IMG_LoadTexture(rend, "sprites/ground.png"),
        })); // player
    }
}

bool kbhandle(SDL_Scancode scancode, bool down) {
    switch (scancode) {
    case SDL_SCANCODE_A:
    case SDL_SCANCODE_LEFT:
        kb.a = down;
        break;
    case SDL_SCANCODE_D:
    case SDL_SCANCODE_RIGHT:
        kb.d = down;
        break;
    case SDL_SCANCODE_W:
    case SDL_SCANCODE_UP:
        kb.w = down;
        break;
    case SDL_SCANCODE_S:
    case SDL_SCANCODE_DOWN:
        kb.s = down;
        break;
    case SDL_SCANCODE_ESCAPE:
        return true;
    default:
        break;
    }
    return false;
}

// global update
bool gupdate(entities *es, SDL_Event *event) {
    bool kbr = kbhandle(event->key.keysym.scancode, event->type == SDL_KEYDOWN);

    player->velocity.x = -MOVESPEED * kb.a;
    player->velocity.x += MOVESPEED * kb.d;
    player->origin.x += player->velocity.x;

    player->velocity.y = -MOVESPEED * kb.w;
    player->velocity.y += MOVESPEED * kb.s;
    player->origin.y += player->velocity.y;

    return kbr;
}

// entity update
void update(void *e) {
    entity *en = (entity*) e;
}

void render(void *e) {
    entity *en = (entity*) e;
    SDL_Rect dst = {
        en->origin.x,
        en->origin.y,
        en->size.x,
        en->size.y,
    };
    SDL_RenderCopy(rend, en->texture, NULL, &dst);
}

void destroy(void *e) {
    SDL_DestroyTexture(((entity*) e)->texture);
    free((entity*) e);
}

void end() {
}

int main() {
    return run();
}
