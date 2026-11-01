#pragma once

class Ball{
    public:
        int width;
        int height;
        int x;
        int y;

        int ballSpeedX;
        int ballSpeedY;
        int speed;

        int screenWidth;
        int screenHeight;

        bool playerPoint;
        bool aiPoint;

        Ball(int screenWidth, int screenHeight, int width = 10, int height = 10, int x = 0, int y = 0);
        
        void reset();
        int random(int a, int b);
        void draw();
        void update(float dt);   
};