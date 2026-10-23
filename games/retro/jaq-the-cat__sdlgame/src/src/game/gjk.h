#pragma once

#include <stdlib.h>

typedef struct _vec2 {
    float x, y;
} vec2;

int gjk (const vec2 * vertices1, size_t count1, const vec2 * vertices2, size_t count2);
