#include <raylib.h>

#include <stdbool.h>

#include <stddef.h>

#include <stdio.h>

#include <stdlib.h>



int main() {

  // Window Initialization

  const int WINDOW_WIDTH = 680, WINDOW_HEIGHT = 480;

  InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "My Window");



  

  SetTargetFPS(60);



  // Player variables

  Vector2 playerpos;

  playerpos.x = 50;

  playerpos.y = 300;



  bool keyheld = false;

  bool isDead = false;

  // Ball variables

  Vector2 ballpos;

  ballpos.x = 400;

  ballpos.y = 300;

  enum _directionx { left, right };

  enum _directiony { up, down };

  enum _directionx balldirx = left;

  enum _directiony balldiry = down;

  float ballspeed[2] = {250.0f, 20.0f};

  float oldBallSpeed[2] = {ballspeed[0],ballspeed[1]};

  enum _directiony playerdiry;



  // Drawing net in the middle of the screen



  int netUnit = 20;

  for (int i = 0; i < (WINDOW_HEIGHT); i++) {

    if (i % netUnit) {

      DrawRectangle(WINDOW_WIDTH / 2, i, netUnit, netUnit, RED);

    }

  }



  int playerScore = 0;

  // Happens every frame

  while (!WindowShouldClose()) {

    

    if (IsKeyDown(KEY_Z)){

      isDead = false;

      ballspeed[0] = oldBallSpeed[0];

      ballspeed[1] = oldBallSpeed[1];

    }

    if (isDead) {

      goto game;

    }



    

    // Ball Movement

    if (balldirx == left)

      ballpos.x -= ballspeed[0]*GetFrameTime();

    else

      ballpos.x += ballspeed[0]*GetFrameTime();

    if (balldiry == up) {

      ballpos.y -= ballspeed[1]*GetFrameTime();

      if (ballpos.y < 10) {

        balldiry = down;

        ballpos.y += ballspeed[1]*GetFrameTime();

      }

    } else {

      ballpos.y += ballspeed[1]*GetFrameTime();

      if (ballpos.y > WINDOW_HEIGHT - 10) {

        balldiry = up;

        ballpos.y -= ballspeed[1]*GetFrameTime();

      }

    }

    if (CheckCollisionCircleRec(

            ballpos, 10,

            (Rectangle){playerpos.x, playerpos.y, 10,

                        70})) { // Left side Player Collision with ball

      playerScore++;

      // if (balldirx == left) {

      //   ballpos.x += ballspeed[0];

      balldirx = right;

      //} else {

      //  ballpos.x -= ballspeed[0];

      //  balldirx = left;

      //}

      ballspeed[0]+=10;

      ballspeed[1]+=7.5;

      if (IsKeyPressed(KEY_UP)||IsKeyPressed(KEY_DOWN)) {

        ballspeed[0]+=10;

      }

    }

    if (CheckCollisionCircleRec(

            ballpos, 10,

            (Rectangle){WINDOW_WIDTH - 100, WINDOW_HEIGHT - playerpos.y - 70,

                        10, 70})) { // Right side Player collision with ball

      playerScore++;

      // if (balldirx == left) {

      //   ballpos.x += ballspeed[0];

      //   balldirx = right;

      // } else {

      //   ballpos.x -= ballspeed[0];

      balldirx = left;

      //}

      ballspeed[0]+=10;

      ballspeed[1]+=7.5;

      if (IsKeyPressed(KEY_UP)||IsKeyPressed(KEY_DOWN)) {

        ballspeed[0]+=10;

      }

    }

    if (ballpos.x <= 0) { // Player LOSE

      playerScore=0;

      ballspeed[0] = 5.0f, ballspeed[1] = 1.0f;



      ballpos.x = 400;

      ballpos.y = 300;

      BeginDrawing();

      DrawText("Lose!, Try again.", WINDOW_WIDTH/3,WINDOW_HEIGHT/2,20,RED);

      WaitTime(0.4);

      isDead = true;

      EndDrawing();

      while (!GetKeyPressed()) {

        goto game;

      }



    } else if (ballpos.x >= WINDOW_WIDTH) { // Player LOSE

      playerScore=0;

      ballspeed[0] = 5.0f, ballspeed[1] = 1.0f;



      ballpos.x = 400;

      ballpos.y = 300;

      BeginDrawing();

      DrawText("Lose!, Try again.",WINDOW_WIDTH/3,WINDOW_HEIGHT/2,20,RED);

      WaitTime(.4);

      isDead = true;

      EndDrawing();

      while (!GetKeyPressed()) {

        goto game;

      }

      

    }



    // Player Input  // Keyboard Handling

    if (IsKeyDown(KEY_W) || IsKeyDown(KEY_UP)) {

      playerpos.y -= (10 * (playerpos.y >= 1));



      playerdiry = up;

    }

    if (IsKeyDown(KEY_S) || IsKeyDown(KEY_DOWN)) {

      playerdiry = down;

      playerpos.y += (10 * (playerpos.y <= WINDOW_HEIGHT - 70));

    }

    if (IsKeyDown(KEY_W) && IsKeyDown(KEY_UP) && IsKeyDown(KEY_S) &&

        IsKeyDown(KEY_DOWN)) {

      keyheld = true;

    } else {

      keyheld = false;

    }

    game:

    BeginDrawing();

    // Clears screen so it won't render everything on top of each other while

    // changing bg color

    ClearBackground(DARKBLUE);

    // 2d rendering and hitbox checking



    static const int netUnit = 9;

    for (int i = 0; i < (WINDOW_HEIGHT); i++) {

      if (i % netUnit == 0) {

        DrawRectangle(WINDOW_WIDTH / 2, i, 3, 1, BLUE);

      }

    }



    DrawCircle(ballpos.x, ballpos.y, 10, RAYWHITE);            // Ball

    DrawRectangle(playerpos.x, playerpos.y, 20, 70, BLUE); // Player

    DrawRectangle(WINDOW_WIDTH - 100, WINDOW_HEIGHT - playerpos.y - 70, 20, 70,

                  BLUE); // Opposite Paddle

    if (!isDead)

    goto afterDeadScreen;

    else {

      DrawText("Press \'Z\' to restart.",WINDOW_WIDTH/3,WINDOW_HEIGHT/2,30,RED);





    }

    afterDeadScreen:

    // UI, overlays



    DrawText("Pong:  ", 10, 10, 20, WHITE);

    DrawFPS(10, 30);

    DrawText("Player Score: ", WINDOW_WIDTH / 2 - 75, 25, 25, WHITE);

    char *stringPlayerScore = malloc(50);

    snprintf(stringPlayerScore, 50, "%d", playerScore);

    free(stringPlayerScore);

    DrawText(stringPlayerScore, WINDOW_WIDTH / 2 - 50, 45, 50, WHITE);

    EndDrawing();

  }



  return 0;

}
