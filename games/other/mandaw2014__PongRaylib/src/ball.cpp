#include "ball.h"

#include "raylib/src/raylib.h"

#include <iostream>

Ball::Ball(int screenWidth, int screenHeight, int width, int height, int x, int y) {
    this->screenWidth = screenWidth;
    this->screenHeight = screenHeight;
    
    this->width = width;
    this->height = height;
    this->x = x;
    this->y = y;

    this->speed = 250;
    
    this->ballSpeedX = this->random(-1, 1);
    this->ballSpeedY = this->random(-1, 1);
    
    this->playerPoint = false;
    this->aiPoint = false;
}

void Ball::reset() {
    this->x = this->screenWidth / 2 - this->width / 2;
    this->y = this->screenHeight / 2 - this->height / 2;
    this->ballSpeedX = this->random(-1, 1);
    this->ballSpeedY = this->random(-1, 1);
}

int Ball::random(int a, int b) {
    srand(time(NULL));

    int r = rand() % 2;

    if(r == 0)
        return a;
    else
        return b;
}

void Ball::draw() {
    DrawRectangle(this->x, this->y, this->width, this->height, WHITE);
}

void Ball::update(float dt) {
    this->x += this->speed * ballSpeedX * dt;
    this->y += this->speed * ballSpeedY * dt;

    if(this->y <= 2 || this->y >= this->screenHeight - 20) 
        this->ballSpeedY *= -1;

    if(this->x <= -10) {
        this->reset();
        this->aiPoint = true;
    }
    else if(this->x >= this->screenWidth + 10) {
        this->reset();
        this->playerPoint = true;
    }
    else {
        this->playerPoint = false;
        this->aiPoint = false;
    }
}