#include <SDL2/SDL_render.h>
#include <stdlib.h>
#include "entity.h"

extern SDL_Renderer *rend;
extern entities es;

enode* makenode(void *e, enode *next) {
    enode *node = malloc(sizeof(enode));
    node->previous = NULL;
    node->e = e;
    node->next = next;
    return node;
}

void eadd(void *e) {
    // special case: first entity
    if (es.length == 0) {
        es.head = makenode(e, NULL);
        es.length++;
        return;
    }

    // create new node
    es.head->previous = makenode(e, es.head);
    es.head = es.head->previous;
    es.length++;
}

void eremove(void *e) {
    enode *node = es.head;
    // special case: first item
    if (&node->e == e) {
        es.head = node->next;
        free(node);
        es.length--;
        return;
    }
    // scroll through until node is e
    for (; node != NULL && node->e != e; node = node->next);
    node->previous->next = node->next;
    free(node);
    es.length--;
}

void efree(void (*destroy)(void*)) {
    enode *tofree = es.head;
    enode *node;
    while (tofree != NULL) {
        node = tofree->next;
        destroy(tofree->e);
        free(tofree);
        tofree = node;
    }
    es.length = 0;
}

void erender(void (*render)(void*)) {
    for (enode *node = es.head; node != NULL; node = node->next)
        render(node->e);
}

void eupdate(void (*update)(void*)) {
    for (enode *node = es.head; node != NULL; node = node->next)
        update(node->e);
}
