#include "canvas.hpp"

void DrawCanvas(const Canvas& c) {
    DrawRectangleRec(c.area, c.color);
    if (c.border_thick > 0) {
        DrawRectangleLinesEx(c.OuterArea(), c.border_thick, c.border_color);
    }
}

void BeginCanvasMode(const Canvas& c){
        BeginScissorMode((int)c.area.x, (int)c.area.y,
                         (int)c.area.width, (int)c.area.height);
        BeginMode2D(Camera2D{ {c.area.x, c.area.y}, {0, 0}, 0.0f, 1.0f });
}

void EndCanvasMode(){ EndMode2D(); EndScissorMode(); }

