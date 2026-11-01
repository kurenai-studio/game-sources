#include "paddle.h"
#include "ball.h"

#include "raylib/src/raylib.h"

Paddle::Paddle(int width, int height, int x, int y) {
    this->width = width;
    this->height = height;
    this->x = x;
    this->y = y;
}

void Paddle::draw() {
    DrawRectangle(this->x, this->y, this->width, this->height, WHITE);
}

void Paddle::update(float dt) {
    if(IsKeyDown(KEY_W))
        this->y -= 200 * dt;
    if(IsKeyDown(KEY_S))
        this->y += 200 * dt;

    if(this->y >= this->screenHeight - 30)
        this->y = this->screenHeight - 30;
    if(this->y <= -60)
        this->y = -60;
}

bool Paddle::collide(Ball ball) {
    float leftA = this->x;
    float rightA = this->x + this->width;
    float topA = this->y;
    float bottomA = this->y + this->height;

    float leftB = ball.x;
    float rightB = ball.x + ball.width;
    float topB = ball.y;
    float bottomB = ball.y + ball.height;

    if(bottomA <= topB)
        return false;
    
    if(topA >= bottomB)
        return false;
    
    if(rightA <= leftB)
        return false;
    
    if(leftA >= rightB)
        return false;
    
    return true;
}