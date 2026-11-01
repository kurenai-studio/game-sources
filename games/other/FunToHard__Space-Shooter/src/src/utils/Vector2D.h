#pragma once
#include <cmath>
#include <raylib.h>

namespace SpaceShooter {

struct Vec2
{
    float x, y;

    Vec2()
        : x(0)
        , y(0)
    {
    }
    Vec2(float x, float y)
        : x(x)
        , y(y)
    {
    }

    // Vector operations
    Vec2 operator+(const Vec2& other) const
    {
        return Vec2(x + other.x, y + other.y);
    }

    Vec2 operator-(const Vec2& other) const
    {
        return Vec2(x - other.x, y - other.y);
    }

    Vec2 operator*(float scalar) const
    {
        return Vec2(x * scalar, y * scalar);
    }

    Vec2& operator+=(const Vec2& other)
    {
        x += other.x;
        y += other.y;
        return *this;
    }

    // Magnitude/Length
    float Length() const
    {
        return sqrt(x * x + y * y);
    }

    // Normalize vector
    Vec2 Normalize() const
    {
        float len = Length();
        if(len > 0) {
            return Vec2(x / len, y / len);
        }
        return Vec2(0, 0);
    }

    // Distance between two points
    static float Distance(const Vec2& a, const Vec2& b)
    {
        return (a - b).Length();
    }

    // Convert to Raylib Vector2
    Vector2 ToVector2() const
    {
        return {x, y};
    }

    // Create from Raylib Vector2
    static Vec2 FromVector2(const Vector2& v)
    {
        return Vec2(v.x, v.y);
    }
};

// Utility functions
inline float Lerp(float a, float b, float t)
{
    return a + t * (b - a);
}

inline float Clamp(float value, float min, float max)
{
    if(value < min)
        return min;
    if(value > max)
        return max;
    return value;
}

// Rectangle collision detection
inline bool CheckCollisionRectangles(const Rectangle& rec1, const Rectangle& rec2)
{
    return ::CheckCollisionRecs(rec1, rec2);
}

// Point in rectangle
inline bool CheckCollisionPointRec(const Vec2& point, const Rectangle& rec)
{
    return ::CheckCollisionPointRec(point.ToVector2(), rec);
}
} // namespace SpaceShooter
