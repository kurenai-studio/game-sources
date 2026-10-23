#include <iostream>
#include <SDL2/SDL.h>
#include <glm/glm.hpp>

constexpr uint32_t SCREEN_WIDTH = 800;
constexpr uint32_t SCREEN_HEIGHT = 600;

constexpr uint32_t PADDLE_WIDTH = 40;
constexpr uint32_t PADDLE_HEIGHT = 120;
constexpr glm::vec2 PADDLE_SPEED = glm::vec2(0.0f, 5.0f);
constexpr uint32_t BALL_SIZE = 25;

// Game Structs
struct Entity {
    SDL_Rect rect = {};
    glm::vec2 velocity = {};
};

struct Game {
    Entity paddles[2] = {};
    Entity ball = {};
    uint32_t scores[2] = {};
};

// Engine Structs
struct Input {
    bool keyState[SDL_NUM_SCANCODES];
};

struct Engine {
    SDL_Window *window = nullptr;
    SDL_Renderer *renderer = nullptr;
    Input input = {};
    bool windowShouldClose = false;
};

// Game Functions
//////////////////
void initGame(Game &game);
void updateGame(Game &game, const Engine &engine);
void renderGame(const Game &game, const Engine &engine);
//////////////////

// Engine Functions
//////////////////
// Init
bool initEngine(Engine &engine);
// I/O Related
void handleEvents(Engine &engine);
void updateKeyState(Input &input, const SDL_Event &event);
bool isKeyPressed(const Engine &engine, SDL_Scancode key);
// Rendering
void render(const Engine &engine);
void renderEntity(const Engine &engine, const Entity& entity);
void presentRender(const Engine &engine);
// Quit
void quitEngine(Engine &engine);
////////////////

int main(int argc, char* args[])
{
    Engine engine;
    if (!initEngine(engine)) {
        return -1;
    };

    Game game;
    initGame(game);

    while (!engine.windowShouldClose) {
        // get input
        handleEvents(engine);

        // update game
        updateGame(game, engine);

        // start render
        render(engine);

        // render game
        renderGame(game, engine);

        // present render
        presentRender(engine);
    }

    quitEngine(engine);
    return 0;
}

void initGame(Game &game) {
    constexpr int centerOfPaddle = SCREEN_HEIGHT / 2 - PADDLE_HEIGHT / 2;
    game.paddles[0].rect = SDL_Rect{ PADDLE_WIDTH, centerOfPaddle, PADDLE_WIDTH, PADDLE_HEIGHT };
    game.paddles[1].rect = SDL_Rect{ SCREEN_WIDTH - PADDLE_WIDTH * 2, centerOfPaddle, PADDLE_WIDTH, PADDLE_HEIGHT };
    game.ball.rect = SDL_Rect{ SCREEN_WIDTH / 2 - BALL_SIZE / 2, SCREEN_HEIGHT / 2 - BALL_SIZE / 2, BALL_SIZE, BALL_SIZE };
    game.ball.velocity = glm::vec2{ 1.0f, -1.0f };
}

void updateGame(Game &game, const Engine &engine) {
    // Left Paddle
    if (isKeyPressed(engine, SDL_SCANCODE_W) &&
            0 < game.paddles[0].rect.y) {
        game.paddles[0].rect.y -= PADDLE_SPEED.y;
        } else if (isKeyPressed(engine, SDL_SCANCODE_S) &&
            SCREEN_HEIGHT - PADDLE_HEIGHT> game.paddles[0].rect.y) {
        game.paddles[0].rect.y += PADDLE_SPEED.y;
    }
    // Right Paddle
    if (isKeyPressed(engine, SDL_SCANCODE_UP) &&
            0 < game.paddles[1].rect.y) {
        game.paddles[1].rect.y -= PADDLE_SPEED.y;
    } else if (isKeyPressed(engine, SDL_SCANCODE_DOWN) &&
            SCREEN_HEIGHT - PADDLE_HEIGHT> game.paddles[1].rect.y) {
        game.paddles[1].rect.y += PADDLE_SPEED.y;
    }

    // Ball
    game.ball.rect.x += static_cast<int>(game.ball.velocity.x);
    game.ball.rect.y += static_cast<int>(game.ball.velocity.y);
    if (0 > game.ball.rect.y || SCREEN_HEIGHT - BALL_SIZE < game.ball.rect.y) // Top & Bottom Wall Collision
        game.ball.velocity.y = -game.ball.velocity.y;
    if (SDL_HasIntersection(&game.paddles[0].rect, &game.ball.rect) || SDL_HasIntersection(&game.paddles[1].rect, &game.ball.rect))
        game.ball.velocity.x = -game.ball.velocity.x;
    if (0 > game.ball.rect.x) {
        // Rest Ball Position
        game.ball.rect = SDL_Rect{ SCREEN_WIDTH / 2 - BALL_SIZE / 2, SCREEN_HEIGHT / 2 - BALL_SIZE / 2, BALL_SIZE, BALL_SIZE };

        // Update scores
        game.scores[0] += 1;
    } else if (SCREEN_WIDTH - BALL_SIZE < game.ball.rect.x) {
        // Rest Ball Position
        game.ball.rect = SDL_Rect{ SCREEN_WIDTH / 2 - BALL_SIZE / 2, SCREEN_HEIGHT / 2 - BALL_SIZE / 2, BALL_SIZE, BALL_SIZE };

        // Update scores
        game.scores[1] += 1;
    }
}

void renderGame(const Game &game, const Engine &engine) {
    renderEntity(engine, game.paddles[0]);
    renderEntity(engine, game.paddles[1]);
    renderEntity(engine, game.ball);
}

bool initEngine(Engine &engine) {
    if (SDL_Init(SDL_INIT_VIDEO)) {
        SDL_Log("SDL_Init failed: %s", SDL_GetError());
        return false;
    }

    engine.window = SDL_CreateWindow("Pong Powered By SDL2", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        800, 600, SDL_WINDOW_SHOWN);
    if (!engine.window) {
        SDL_Log("SDL_CreateWindow failed: %s", SDL_GetError());
        return false;
    }

    engine.renderer = SDL_CreateRenderer(engine.window, -1, SDL_RENDERER_ACCELERATED);
    if (!engine.renderer) {
        SDL_Log("SDL_CreateRenderer failed: %s", SDL_GetError());
        return false;
    }

    return true;
}

void handleEvents(Engine &engine) {
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_QUIT) {
            engine.windowShouldClose = true;
        }
        updateKeyState(engine.input, event);
    }
    if (isKeyPressed(engine, SDL_SCANCODE_ESCAPE)) {
        engine.windowShouldClose = true;
    }
}

void updateKeyState(Input &input, const SDL_Event &event) {
    if (event.type == SDL_KEYDOWN) {
        input.keyState[event.key.keysym.scancode] = true;
    } else if (event.type == SDL_KEYUP) {
        input.keyState[event.key.keysym.scancode] = false;
    }
}

bool isKeyPressed(const Engine &engine, const SDL_Scancode key) {
    return engine.input.keyState[key];
}

void render(const Engine &engine) {
    SDL_SetRenderDrawColor(engine.renderer, 0, 0, 0, 255); // Black background
    SDL_RenderClear(engine.renderer);
}

void renderEntity(const Engine &engine, const Entity& entity) {
    SDL_SetRenderDrawColor(engine.renderer, 255, 255, 255, 255); // White for entity
    SDL_RenderDrawRect(engine.renderer, &entity.rect);
}

void presentRender(const Engine &engine) {
    SDL_RenderPresent(engine.renderer);
}

void quitEngine(Engine &engine) {
    SDL_DestroyRenderer(engine.renderer);
    engine.renderer = nullptr;
    SDL_DestroyWindow(engine.window);
    engine.window = nullptr;
    SDL_Quit();
}
