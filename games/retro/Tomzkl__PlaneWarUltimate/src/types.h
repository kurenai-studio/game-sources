#pragma once

namespace pwu {

enum class Difficulty
{
    EASY,
    NORMAL,
    HARD,
    LUNATIC
};

enum class GameState
{
    MENU,
    SETTINGS,
    LEADERBOARD,
    PLAYING,
    PAUSED,
    GAMEOVER
};

enum class EnemyKind
{
    SMALL,
    MEDIUM,
    LARGE
};

enum class PowerUpKind
{
    HEAL,
    TRIPLE,
    BOMB
};

struct Bullet
{
    float x;
    float y;
    float speedX;
    float speedY;
    bool active;
    int trailTimer;   // for glow pulse
};

struct StarData
{
    float x;
    float y;
    float speed;
    float alpha;
    float size;
};

struct StarItem
{
    float x, y;
    float life;
    bool active;
};

} // namespace pwu
