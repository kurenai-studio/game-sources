#include <stdio.h>
#include <string>
#include <random>

#include <SDL2/SDL.h>

const unsigned int SCREEN_WIDTH = 740;
const unsigned int SCREEN_HEIGHT = 320;
const unsigned int MIDLINE_WIDTH = 2;
const unsigned int MIDLINE_HEIGHT = 10;
const unsigned int PLAYER_HEIGHT = 40;
const unsigned int PLAYER_WIDTH = 10;
const unsigned int PLAYER_VELOCITY = 5;
const unsigned int BALL_RADIUS = 10;

bool gameOver = false;
unsigned int winner = 0;
float ballXVel = 0.095f;
float ballYVel = 0.07f;

typedef struct {
    float x; // position is relative to center
    float y;
} Ball;

SDL_Window* window = NULL;
SDL_Renderer* renderer = NULL;
SDL_Rect player1;
SDL_Rect player2;

bool init();
void close();
void movePlayer(SDL_Rect& player, int key);
void drawBall(Ball ball);
void moveBall(Ball& ball);
void showVictory();
int getRandomNumber(int lower, int upper);
void rndBallVelocity();

int main(int argc, char* args[]) {

    if (!init()) {
        printf("Could not initialize window! Error: %s\n", SDL_GetError());
    }
    else {
        SDL_Event e;
        bool quit = false;

        player1 = { 0, SCREEN_HEIGHT / 2, PLAYER_WIDTH, PLAYER_HEIGHT };
        player2 = { SCREEN_WIDTH - PLAYER_WIDTH, SCREEN_HEIGHT / 2, PLAYER_HEIGHT, PLAYER_HEIGHT };
        Ball ball = { SCREEN_WIDTH / 2, (float)getRandomNumber(BALL_RADIUS + 10, SCREEN_HEIGHT - BALL_RADIUS - 10) };
        rndBallVelocity();

        while (!quit) {
            while (SDL_PollEvent(&e)) {
                if (e.type == SDL_QUIT) {
                    quit = true;
                }

                else if (e.type == SDL_KEYDOWN && !gameOver) {
                    int key = e.key.keysym.sym;

                    // player 1 controls
                    if (key == SDLK_w || key == SDLK_s) {
                        movePlayer(player1, key);
                    }
                    // player 2 controls
                    else if (key == SDLK_UP || key == SDLK_DOWN) {
                        movePlayer(player2, key);
                    }
                }
            }

            if (!gameOver) {
                SDL_SetRenderDrawColor(renderer, 31, 31, 31, 255); // background -> dark
                SDL_RenderClear(renderer);

                SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255); // ball -> green
                drawBall(ball);

                SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
                unsigned int y_coord = 0;
                for (unsigned int i = 0; i < 100; i++) {
                    SDL_Rect rect = { SCREEN_WIDTH / 2, (int)y_coord, MIDLINE_WIDTH, MIDLINE_HEIGHT };
                    SDL_RenderFillRect(renderer, &rect);

                    y_coord += MIDLINE_HEIGHT + 10;
                }

                SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255); // player 1 -> red
                SDL_RenderFillRect(renderer, &player1);

                SDL_SetRenderDrawColor(renderer, 0, 0, 255, 255); // player 2 -> blue
                SDL_RenderFillRect(renderer, &player2);

                moveBall(ball);

                SDL_RenderPresent(renderer);
            }
            else {
                ballXVel = 0;
                ballYVel = 0;
                showVictory();
            }
        }
    }
    close();
    return 0;
}

void rndBallVelocity() {
    int rnd1 = getRandomNumber(1, 100);
    int rnd2 = getRandomNumber(1, 100);

    ballXVel = (rnd1 % 2 == 0) ? ballXVel : -ballXVel;
    ballYVel = (rnd2 % 2 == 0) ? ballYVel : -ballYVel;
}

void showVictory() {
    std::string path = "assets/trophy.bmp";
    SDL_Surface* surface = SDL_LoadBMP(path.c_str()); // Path to your image
    if (!surface) {
        printf("Failed to load trophy image: %s\n", SDL_GetError());
        return;
    }

    SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
    SDL_FreeSurface(surface);

    unsigned int xPos;
    unsigned int yPos = SCREEN_HEIGHT * (1.0f / 5.0f);  // Ensure floating point division
    unsigned int height = 100;
    unsigned int width = 100;

    if (winner == 2) {
        xPos = (SCREEN_WIDTH / 4.0f) - (width / 2.0f);
    }
    else {
        xPos = (SCREEN_WIDTH * (3.0f / 4.0f)) - (width / 2.0f);
    }

    SDL_Rect rect = { (int)xPos, (int)yPos, (int)width, (int)height };
    SDL_RenderCopy(renderer, texture, NULL, &rect);
    SDL_RenderPresent(renderer);
    SDL_DestroyTexture(texture);
}

void moveBall(Ball& ball) {
    ball.x += ballXVel;
    ball.y += ballYVel;

    // collision detection
    if (ball.y - BALL_RADIUS <= 0 || ball.y + BALL_RADIUS >= SCREEN_HEIGHT) {
        ballYVel = -ballYVel;
    }

    if (ball.x - BALL_RADIUS <= player1.x + player1.w && ball.x + BALL_RADIUS >= player1.x) {
        if (ball.y >= player1.y && ball.y <= player1.y + player1.h) {
            ballXVel = -ballXVel; // Reverse the ball's direction
            ball.x = player1.x + player1.w + BALL_RADIUS; // Prevent ball from getting stuck
        }
    }

    // Check for collision with player 2
    if (ball.x + BALL_RADIUS >= player2.x && ball.x - BALL_RADIUS <= player2.x + player2.w) {
        if (ball.y >= player2.y && ball.y <= player2.y + player2.h) {
            ballXVel = -ballXVel; // Reverse the ball's direction
            ball.x = player2.x - BALL_RADIUS; // Prevent ball from getting stuck
        }
    }

    if (ball.x - BALL_RADIUS <= 0 || ball.x + BALL_RADIUS >= SCREEN_WIDTH) { // ball collides with left or right wall
        gameOver = true;

        // check who is the winner
        if (ball.x > SCREEN_WIDTH / 2) {
            winner = 2;
        }
        else {
            winner = 1;
        }
    }
}

void movePlayer(SDL_Rect& player, int key) {

    // move up
    if (key == SDLK_w || key == SDLK_UP) {
        // move player if they are not at the edge
        if (player.y > 0) {
            player.y -= PLAYER_VELOCITY;
        }
    }

    // move down
    else if (key == SDLK_s || key == SDLK_DOWN) {
        // move player if they are not at the edge
        if (player.y + player.h < SCREEN_HEIGHT) {
            player.y += PLAYER_VELOCITY;
        }
    }
}

void drawBall(Ball ball) {
    int radius = BALL_RADIUS / 2;
    int centerX = ball.x;
    int centerY = ball.y;

    int x = radius;
    int y = 0;
    int decisionOver2 = 1 - x;

    // Loop through the circle and fill in the pixels
    while (y <= x) {
        // Draw horizontal lines for each y position (fill the region)
        SDL_RenderDrawLine(renderer, centerX - x, centerY + y, centerX + x, centerY + y); // Top side
        SDL_RenderDrawLine(renderer, centerX - x, centerY - y, centerX + x, centerY - y); // Bottom side
        SDL_RenderDrawLine(renderer, centerX - y, centerY + x, centerX + y, centerY + x); // Left side
        SDL_RenderDrawLine(renderer, centerX - y, centerY - x, centerX + y, centerY - x); // Right side

        // Move to the next point
        y++;
        if (decisionOver2 <= 0) {
            decisionOver2 += 2 * y + 1;  // Change in decision parameter
        }
        else {
            x--;
            decisionOver2 += 2 * (y - x) + 1;  // Change in decision parameter
        }
    }
}

bool init() {
    bool success = true;

    window = SDL_CreateWindow("Pong!", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);

    if (window == NULL) {
        printf("Window could not be created! Error: %s\n", SDL_GetError());
        success = false;
    }

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (renderer == NULL) {
        printf("Renderer could not be created! Error: %s\n", SDL_GetError());
        success = false;
    }
    return success;
}

int getRandomNumber(int lower, int upper) {
    // R -> [lower, upper]

    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dist(lower, upper);

    int random_number = dist(gen);
    return random_number;
}

void close() {
    SDL_DestroyRenderer(renderer);
    renderer = NULL;

    SDL_DestroyWindow(window);
    window = NULL;

    SDL_Quit();
}