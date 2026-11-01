#pragma once

#include <string>

#include "raylib.h"

namespace GWSandbox
{
    // Enumeration to specify text justification options
    enum class Justify
    {
        // No alignment, use x and y as is
        NONE,
        // Center the text horizontally on the screen
        CENTER_X,
        // Center the text vertically on the screen
        CENTER_Y,
        // Center the text both horizontally and vertically
        CENTER_BOTH
    };

    struct BasicText
    {
        std::string text;
        int fontSize;
        int x, y;
        int screenWidth, screenHeight;
        Color color;
        Justify justify;

        BasicText(std::string text, int fontSize, int x, int y, Color color, Justify justify = Justify::NONE, int screenWidth = 0, int screenHeight = 0)
            : text(text), fontSize(fontSize), x(x), y(y), color(color), justify(justify), screenWidth(screenWidth), screenHeight(screenHeight) {}

        void Draw() const
        {
            int textX = x;
            int textY = y;

            // Only calculate text size if we need to justify it
            if (justify != Justify::NONE)
            {
                Vector2 textSize = MeasureTextEx(GetFontDefault(), text.c_str(), fontSize, 1);

                if (justify == Justify::CENTER_X || justify == Justify::CENTER_BOTH)
                {
                    textX = screenWidth / 2 - (textSize.x / 2);
                }

                if (justify == Justify::CENTER_Y || justify == Justify::CENTER_BOTH)
                {
                    textY = screenHeight / 2 - (textSize.y / 2);
                }
            }

            DrawText(text.c_str(), textX, textY, fontSize, color);
        }

        void SetText(std::string text)
        {
            this->text = text;
        }

        void SetScreenSize(int width, int height)
        {
            screenWidth = width;
            screenHeight = height;
        }

        void SetJustification(Justify newJustify)
        {
            justify = newJustify;
        }
    };
}