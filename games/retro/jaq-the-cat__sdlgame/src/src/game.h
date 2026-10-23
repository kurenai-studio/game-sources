#pragma once
#include "entity.h"
#include <SDL2/SDL_events.h>
#include <stdbool.h>

int run();

void start(entities *es);
bool gupdate(entities *es, SDL_Event *event);
void update(void* e);
void render(void *e);
void destroy(void *e);
void end();
