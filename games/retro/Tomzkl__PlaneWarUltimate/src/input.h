#pragma once
#include "raylib.h"

namespace pwu {

// ==================================================================
//  Input - single point of control for all key bindings.
//  To remap: change the KeyboardKey values below.
//  To add gamepad: check IsGamepadButton* in parallel with IsKey*.
// ==================================================================

namespace Input {

// -- Movement --------------------------------------------------
inline bool MoveUp()    { return IsKeyDown(KEY_W)    || IsKeyDown(KEY_UP);    }
inline bool MoveDown()  { return IsKeyDown(KEY_S)    || IsKeyDown(KEY_DOWN);  }
inline bool MoveLeft()  { return IsKeyDown(KEY_A)    || IsKeyDown(KEY_LEFT);  }
inline bool MoveRight() { return IsKeyDown(KEY_D)    || IsKeyDown(KEY_RIGHT); }

inline float AxisX()
{
    float v = 0;
    if (MoveLeft())  v -= 1.0f;
    if (MoveRight()) v += 1.0f;
    return v;
}

inline float AxisY()
{
    float v = 0;
    if (MoveUp())   v -= 1.0f;
    if (MoveDown()) v += 1.0f;
    return v;
}

// -- Actions ----------------------------------------------------
inline bool Shoot()         { return IsKeyDown(KEY_SPACE); }
inline bool ShootPressed()  { return IsKeyPressed(KEY_SPACE); }
inline bool Bomb()          { return IsKeyPressed(KEY_B); }
inline bool Pause()         { return IsKeyPressed(KEY_P) || IsKeyPressed(KEY_ESCAPE); }
inline bool Confirm()       { return IsKeyPressed(KEY_ENTER) || IsKeyPressed(KEY_SPACE); }
inline bool Back()          { return IsKeyPressed(KEY_ESCAPE); }
inline bool MenuUp()        { return IsKeyPressed(KEY_W)    || IsKeyPressed(KEY_UP);    }
inline bool MenuDown()      { return IsKeyPressed(KEY_S)    || IsKeyPressed(KEY_DOWN);  }
inline bool MenuLeft()      { return IsKeyPressed(KEY_LEFT); }
inline bool MenuRight()     { return IsKeyPressed(KEY_RIGHT); }
inline bool FullscreenToggle() { return IsKeyPressed(KEY_F11); }
inline bool MuteToggle()    { return IsKeyPressed(KEY_M); }
inline bool Restart()       { return IsKeyPressed(KEY_R); }

// -- Menu slider (held for repeat) ------------------------------
inline bool SliderLeft()    { return IsKeyDown(KEY_LEFT); }
inline bool SliderRight()   { return IsKeyDown(KEY_RIGHT); }
inline bool SliderLeftPressed()  { return IsKeyPressed(KEY_LEFT); }
inline bool SliderRightPressed() { return IsKeyPressed(KEY_RIGHT); }

} // namespace Input
} // namespace pwu
