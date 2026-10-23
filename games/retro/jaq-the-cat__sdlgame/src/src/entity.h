#pragma once

#include <SDL2/SDL_render.h>
#include <stdio.h>

typedef struct enode {
    struct enode *previous;
    void *e;
    struct enode *next;
} enode;

typedef struct entities {
    enode *head;
    int length;
} entities;

void eadd(void *e);
void eremove(void *e);

// Takes in a function to destroy any elements inside the entity
// that need to be destroyed
void efree(void (*destroy)(void*));

// takes in function to render entities
void erender(void (*render)(void*));
void eupdate(void (*update)(void*));
