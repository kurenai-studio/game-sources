#include "ui.h"

// Handle interactive resizing using custom hit‑areas on the right,
// bottom and bottom‑right corner of the window.
void HandleResize(GameState* state, int screenWidth, int screenHeight)
{
    Vector2 mousePos = GetMousePosition();
    int handleSize = state->resizeHandleSize;
    
    // Safety net: like dragging, if the window loses focus while resizing,
    // we may miss the release event. If the mouse button is no longer
    // down, cancel any in‑progress resize so the game never "sticks".
    if (!IsMouseButtonDown(MOUSE_LEFT_BUTTON) && state->resizeState.isResizing)
    {
        state->resizeState.isResizing = false;
        state->resizeState.mode = RESIZE_NONE;
    }
    
    // Define resize areas
    Rectangle rightHandle = {(float)screenWidth - handleSize, (float)state->titleBarHeight, 
                             (float)handleSize, (float)screenHeight - state->titleBarHeight};
    Rectangle bottomHandle = {0, (float)screenHeight - handleSize, 
                              (float)screenWidth, (float)handleSize};
    Rectangle cornerHandle = {(float)screenWidth - handleSize, (float)screenHeight - handleSize, 
                              (float)handleSize, (float)handleSize};
    
    // Start resizing
    if (IsMouseButtonPressed(MOUSE_LEFT_BUTTON) && !state->dragState.isDragging)
    {
        if (CheckCollisionPointRec(mousePos, cornerHandle))
        {
            state->resizeState.isResizing = true;
            state->resizeState.mode = RESIZE_CORNER;
            state->resizeState.resizeStartMousePos = mousePos;
            state->resizeState.resizeStartSize = {(float)screenWidth, (float)screenHeight};
        }
        else if (CheckCollisionPointRec(mousePos, rightHandle))
        {
            state->resizeState.isResizing = true;
            state->resizeState.mode = RESIZE_RIGHT;
            state->resizeState.resizeStartMousePos = mousePos;
            state->resizeState.resizeStartSize = {(float)screenWidth, (float)screenHeight};
        }
        else if (CheckCollisionPointRec(mousePos, bottomHandle))
        {
            state->resizeState.isResizing = true;
            state->resizeState.mode = RESIZE_BOTTOM;
            state->resizeState.resizeStartMousePos = mousePos;
            state->resizeState.resizeStartSize = {(float)screenWidth, (float)screenHeight};
        }
    }
    
    // Stop resizing
    if (IsMouseButtonReleased(MOUSE_LEFT_BUTTON))
    {
        state->resizeState.isResizing = false;
        state->resizeState.mode = RESIZE_NONE;
    }
    
    // Update window size while resizing
    if (state->resizeState.isResizing)
    {
        Vector2 currentMousePos = GetMousePosition();
        Vector2 mouseDelta = {
            currentMousePos.x - state->resizeState.resizeStartMousePos.x,
            currentMousePos.y - state->resizeState.resizeStartMousePos.y
        };
        
        int newWidth = screenWidth;
        int newHeight = screenHeight;
        
        if (state->resizeState.mode == RESIZE_RIGHT || state->resizeState.mode == RESIZE_CORNER)
        {
            newWidth = (int)(state->resizeState.resizeStartSize.x + mouseDelta.x);
            if (newWidth < 120) newWidth = 120; // Min width (title bar + resize handle)
        }
        
        if (state->resizeState.mode == RESIZE_BOTTOM || state->resizeState.mode == RESIZE_CORNER)
        {
            newHeight = (int)(state->resizeState.resizeStartSize.y + mouseDelta.y);
            if (newHeight < 80) newHeight = 80; // Min height (title bar + resize handle)
        }
        
        SetWindowSize(newWidth, newHeight);
    }
    
    // Change cursor based on hover
    if (!state->resizeState.isResizing)
    {
        if (CheckCollisionPointRec(mousePos, cornerHandle))
        {
            SetMouseCursor(MOUSE_CURSOR_RESIZE_NWSE);
        }
        else if (CheckCollisionPointRec(mousePos, rightHandle))
        {
            SetMouseCursor(MOUSE_CURSOR_RESIZE_EW);
        }
        else if (CheckCollisionPointRec(mousePos, bottomHandle))
        {
            SetMouseCursor(MOUSE_CURSOR_RESIZE_NS);
        }
        else
        {
            SetMouseCursor(MOUSE_CURSOR_DEFAULT);
        }
    }
}

// Visual hint rectangles so the player can see where to drag
// to resize the window.
void DrawResizeHandles(GameState* state, int screenWidth, int screenHeight)
{
    int handleSize = state->resizeHandleSize;
    
    // Right handle
    DrawRectangle(screenWidth - handleSize, state->titleBarHeight, 
                  handleSize, screenHeight - state->titleBarHeight, 
                  ColorAlpha(BLUE, 0.3f));
    
    // Bottom handle
    DrawRectangle(0, screenHeight - handleSize, 
                  screenWidth, handleSize, 
                  ColorAlpha(BLUE, 0.3f));
    
    // Corner handle (brighter)
    DrawRectangle(screenWidth - handleSize, screenHeight - handleSize, 
                  handleSize, handleSize, 
                  ColorAlpha(BLUE, 0.5f));
}

// Custom title bar that replaces the OS window frame.
// It supports drag‑moving the window and a manual close button.
void HandleTitleBar(GameState* state, int screenWidth)
{
    Vector2 mousePos = GetMousePosition();
    Rectangle titleBar = {0, 0, (float)screenWidth, (float)state->titleBarHeight};
    Rectangle closeButton = {(float)screenWidth - 45, 0, 45, (float)state->titleBarHeight};
    
    // Safety net: if the window lost focus while the mouse was down,
    // we might never see the release event. In that case, force‑reset
    // the drag state once the button is no longer held.
    if (!IsMouseButtonDown(MOUSE_LEFT_BUTTON) && state->dragState.isDragging)
    {
        state->dragState.isDragging = false;
    }
    
    // Close button
    if (CheckCollisionPointRec(mousePos, closeButton) && IsMouseButtonPressed(MOUSE_LEFT_BUTTON))
    {
        state->shouldClose = true;
        return;
    }
    
    // Start dragging
    if (CheckCollisionPointRec(mousePos, titleBar) && 
        !CheckCollisionPointRec(mousePos, closeButton) && 
        IsMouseButtonPressed(MOUSE_LEFT_BUTTON) &&
        !state->resizeState.isResizing)
    {
        state->dragState.isDragging = true;
        Vector2 windowPos = GetWindowPosition();
        state->dragState.dragStartMouseScreen.x = windowPos.x + mousePos.x;
        state->dragState.dragStartMouseScreen.y = windowPos.y + mousePos.y;
        state->dragState.dragStartWindowPos = windowPos;
    }
    
    // Stop dragging
    if (IsMouseButtonReleased(MOUSE_LEFT_BUTTON))
    {
        state->dragState.isDragging = false;
    }
    
    // Update window position while dragging
    if (state->dragState.isDragging)
    {
        Vector2 currentMousePos = GetMousePosition();
        Vector2 windowPos = GetWindowPosition();
        
        Vector2 currentMouseScreen;
        currentMouseScreen.x = windowPos.x + currentMousePos.x;
        currentMouseScreen.y = windowPos.y + currentMousePos.y;
        
        Vector2 offset;
        offset.x = currentMouseScreen.x - state->dragState.dragStartMouseScreen.x;
        offset.y = currentMouseScreen.y - state->dragState.dragStartMouseScreen.y;
        
        SetWindowPosition((int)(state->dragState.dragStartWindowPos.x + offset.x), 
                        (int)(state->dragState.dragStartWindowPos.y + offset.y));
    }
}

// Draw the custom title bar and close button.
void DrawTitleBar(GameState* state, int screenWidth)
{
    Vector2 mousePos = GetMousePosition();
    Rectangle closeButton = {(float)screenWidth - 45, 0, 45, (float)state->titleBarHeight};
    
    // Draw custom titlebar
    DrawRectangle(0, 0, screenWidth, state->titleBarHeight, DARKGRAY);
    DrawText("IndexOutOfBoundsException()", 10, 10, 20, RAYWHITE);
    
    // Draw close button
    Color closeColor = CheckCollisionPointRec(mousePos, closeButton) ? RED : MAROON;
    DrawRectangle(screenWidth - 45, 0, 45, state->titleBarHeight, closeColor);
    DrawText("X", screenWidth - 28, 8, 20, RAYWHITE);
    
    // Draw separator line
    DrawLine(0, state->titleBarHeight, screenWidth, state->titleBarHeight, GRAY);
}

// Simple rectangular button with hover highlight and centered text.
void DrawButton(Button* button, Vector2 mousePos)
{
    Color buttonColor = button->isHovered ? DARKGRAY : GRAY;
    Color textColor = button->isHovered ? WHITE : LIGHTGRAY;
    
    DrawRectangleRec(button->bounds, buttonColor);
    DrawRectangleLinesEx(button->bounds, 2, WHITE);
    
    int textWidth = MeasureText(button->text, 20);
    DrawText(button->text, 
             button->bounds.x + (button->bounds.width - textWidth) / 2,
             button->bounds.y + (button->bounds.height - 20) / 2,
             20, textColor);
}

// Main menu with title, buttons and tiny credits at the bottom.
void DrawMainMenu(GameState* state, int screenWidth, int screenHeight)
{
    Vector2 mousePos = GetMousePosition();
    
    const char* title = "IndexOutOfBoundsException()";
    int titleFontSize = 30;
    int titleWidth = MeasureText(title, titleFontSize);
    DrawText(title, screenWidth / 2 - titleWidth / 2, screenHeight / 2 - 120, titleFontSize, WHITE);

    // Small subtitle under the main title
    const char* subtitle = "simple C++ game (only 3 levels!)";
    int subtitleFontSize = 18;
    int subtitleWidth = MeasureText(subtitle, subtitleFontSize);
    DrawText(subtitle,
             screenWidth / 2 - subtitleWidth / 2,
             screenHeight / 2 - 90,
             subtitleFontSize,
             LIGHTGRAY);
    
    DrawButton(&state->newGameButton, mousePos);
    DrawButton(&state->loadGameButton, mousePos);

    const char* credit1 = "Made by @DaksshDeva";
    const char* credit2 = "IndexOutOfBoundsException() is Open Source!";
    const char* credit3 = "GitHub: https://github.com/DaksshDev/CoolRaylibGame.git";
    int creditFontSize = 16;
    int y3 = screenHeight - 24;
    int y2 = y3 - 20;
    int y1 = y2 - 20;

    DrawText(credit1, screenWidth / 2 - MeasureText(credit1, creditFontSize) / 2, y1, creditFontSize, GRAY);
    DrawText(credit2, screenWidth / 2 - MeasureText(credit2, creditFontSize) / 2, y2, creditFontSize, GRAY);
    DrawText(credit3, screenWidth / 2 - MeasureText(credit3, creditFontSize) / 2, y3, creditFontSize, LIGHTGRAY);
}