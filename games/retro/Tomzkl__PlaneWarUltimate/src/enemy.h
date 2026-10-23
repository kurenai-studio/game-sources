#pragma once
#include "raylib.h"
#include "constants.h"
#include "pool.h"
#include "types.h"
#ifdef _MSC_VER
#pragma warning(disable: 4244)  // int to float conversion in drawing
#endif

namespace pwu {

struct Enemy
{
    float x;
    float y;
    int hp;
    EnemyKind kind;
    bool active;

    void Init(EnemyKind k, float startX, float startY);
    void Update(int enemySpeed);
    void Draw(const Texture2D& tex) const;
    Rectangle GetBounds() const;
    int GetScore() const;
    int GetSize() const;
};

Enemy* SpawnEnemy(Pool<Enemy, MAX_ENEMIES>& pool, int difficulty);

} // namespace pwu
