#pragma once
#include <SDL2/SDL_image.h>
#include "gjk.h"

typedef enum etype {
    PLAYER,
    DMG,
    OBJECT,
} etype;

typedef struct entity {
    etype type;
    vec2 origin;
    vec2 velocity;
    vec2 size;
    float gravity;
    SDL_Texture *texture;
} entity;

void* makeentity(entity temp);
