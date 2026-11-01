#ifndef CANVAS_HPP
#define CANVAS_HPP

#include "raylib.h"

struct Canvas {
    Rectangle area         = { 0, 0, 200, 200 };
    Color     color        = WHITE;
    float     border_thick = 0;
    Color     border_color = BLACK;

    Rectangle OuterArea() const {
        return { area.x - border_thick, area.y - border_thick,
                 area.width + 2 * border_thick, area.height + 2 * border_thick };
    }
};

void DrawCanvas(const Canvas& c);

void BeginCanvasMode(const Canvas& c);
void EndCanvasMode();

#endif // CANVAS_HPP
