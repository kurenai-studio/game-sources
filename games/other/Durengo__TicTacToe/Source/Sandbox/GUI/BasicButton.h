#pragma once

#include <functional>
#include <string>

#include "raylib.h"

namespace GWSandbox
{
    struct Button
    {
        // Position and dimensions of the button
        Rectangle bounds;
        // Color of the button when not interacted with
        Color normalColor;
        // Color of the button on mouse hover
        Color hoverColor;
        // Color of the button when pressed
        Color pressedColor;
        // Delegate function for button click event
        std::function<void()> onClick;
        // Text to be displayed on the button
        std::string text;
        // Flag to enable or disable the button's click functionality
        bool isEnabled;

        // Modify constructor to initialize isEnabled
        Button(Rectangle bounds, Color normal, Color hover, Color pressed, std::function<void()> clickCallback, std::string text = "Button", bool isEnabled = true)
            : bounds(bounds), normalColor(normal), hoverColor(hover), pressedColor(pressed), onClick(clickCallback), text(text), isEnabled(isEnabled) {}

        // Check if the button is hovered or clicked
        void Update()
        {
            if (isEnabled)
            {
                Vector2 mousePoint = GetMousePosition();
                if (CheckCollisionPointRec(mousePoint, bounds))
                {
                    if (IsMouseButtonReleased(MOUSE_LEFT_BUTTON))
                    {
                        // Call the delegate function if the button is enabled
                        onClick();
                    }
                }
            }
        }

        void Draw() const
        {
            Color currentColor = isEnabled ? normalColor : GRAY;

            if (CheckCollisionPointRec(GetMousePosition(), bounds))
            {
                currentColor = IsMouseButtonDown(MOUSE_LEFT_BUTTON) ? pressedColor : hoverColor;
            }
            DrawRectangleRec(bounds, currentColor);

            // Measure the text width and height
            int fontSize = 20;
            Vector2 textSize = MeasureTextEx(GetFontDefault(), text.c_str(), fontSize, 1);

            // Calculate text position to center it on the button
            float textX = bounds.x + (bounds.width - textSize.x) / 2;
            float textY = bounds.y + (bounds.height - textSize.y) / 2 - 10;

            // Adjust Y position to align text vertically in the middle
            textY += (textSize.y / 2);

            // Draw the text centered
            DrawText(text.c_str(), static_cast<int>(textX), static_cast<int>(textY), fontSize, WHITE);
        }

        void SetEnabled(bool enabled)
        {
            isEnabled = enabled;
        }
    };
}