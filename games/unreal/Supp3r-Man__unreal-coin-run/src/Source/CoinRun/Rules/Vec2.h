// Engine-free on purpose: nothing under Source/CoinRun/Rules includes an Unreal header, so the
// game rules compile and run in plain C++17 (see Tests/rules). Keep it that way.
// No exceptions and no RTTI either, to match how Unreal compiles modules.
#pragma once

#include <cmath>

namespace coinrun {

// A point or direction on the arena floor. Units are Unreal centimetres; x and y are world X and Y.
struct Vec2 {
    float x = 0.0f;
    float y = 0.0f;

    Vec2() = default;
    Vec2(float x_in, float y_in) : x(x_in), y(y_in) {}

    float SqrLength() const { return x * x + y * y; }
    float Length() const { return std::sqrt(SqrLength()); }

    // Unit vector, or (0, 0) for a vector too short to have a direction.
    Vec2 Normalized() const {
        const float len = Length();
        if (len < 1e-6f) return Vec2(0.0f, 0.0f);
        return Vec2(x / len, y / len);
    }
};

inline Vec2 operator+(Vec2 a, Vec2 b) { return Vec2(a.x + b.x, a.y + b.y); }
inline Vec2 operator-(Vec2 a, Vec2 b) { return Vec2(a.x - b.x, a.y - b.y); }
inline Vec2 operator*(Vec2 a, float s) { return Vec2(a.x * s, a.y * s); }

inline float Dot(Vec2 a, Vec2 b) { return a.x * b.x + a.y * b.y; }
inline float Distance(Vec2 a, Vec2 b) { return (a - b).Length(); }

}  // namespace coinrun
