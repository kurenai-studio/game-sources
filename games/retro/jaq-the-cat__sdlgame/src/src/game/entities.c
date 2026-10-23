#include "entities.h"

void* makeentity(entity temp) {
    entity *e = (entity*) malloc(sizeof(temp));
    e->type = temp.type;
    e->origin = temp.origin;
    e->velocity = temp.velocity;
    e->size = temp.size;
    e->gravity = temp.gravity;
    e->texture = temp.texture;
    return e;
}
