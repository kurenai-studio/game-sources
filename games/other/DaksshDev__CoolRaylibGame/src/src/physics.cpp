#include "physics.h"
#include <cmath>

// Very small "physics engine" for the cube:
// - applies gravity
// - applies damping
// - bounces off the window edges
// - reacts to how fast you move the OS window ("shake" controls)
void UpdatePhysics(GameState* state, float dt, int screenWidth, int screenHeight)
{
    // Calculate window velocity and acceleration (for shake detection)
    Vector2 currentWindowPos = GetWindowPosition();
    state->windowPhysics.windowVelocity = Vector2Scale(
        Vector2Subtract(currentWindowPos, state->windowPhysics.lastWindowPos), 
        1.0f / dt
    );
    
    // Window acceleration = change in velocity (this captures the "shake")
    Vector2 windowAcceleration = Vector2Scale(
        Vector2Subtract(state->windowPhysics.windowVelocity, state->windowPhysics.lastWindowVelocity), 
        1.0f / dt
    );
    
    // Apply shake force to cube (inverse of window acceleration, scaled for effect)
    float shakeMagnitude = Vector2Length(windowAcceleration);
    if (shakeMagnitude > 100.0f)
    {
        Vector2 shakeForce = Vector2Scale(windowAcceleration, -0.5f);
        state->cube.acceleration = Vector2Add(
            state->cube.acceleration, 
            Vector2Scale(shakeForce, 1.0f / state->cube.mass)
        );
    }
    
    state->windowPhysics.lastWindowPos = currentWindowPos;
    state->windowPhysics.lastWindowVelocity = state->windowPhysics.windowVelocity;
    
    // Apply gravity
    state->cube.acceleration.y += state->gravity;
    
    // Update velocity from acceleration
    state->cube.velocity = Vector2Add(
        state->cube.velocity, 
        Vector2Scale(state->cube.acceleration, dt)
    );
    
    // Apply damping
    state->cube.velocity = Vector2Scale(state->cube.velocity, state->cube.damping);
    
    // Update position
    state->cube.position = Vector2Add(
        state->cube.position, 
        Vector2Scale(state->cube.velocity, dt)
    );
    
    // Reset acceleration for next frame
    state->cube.acceleration = {0, 0};
    
    // Clamp position to stay within bounds (account for titlebar)
    if (state->cube.position.x < 0) state->cube.position.x = 0;
    if (state->cube.position.x > screenWidth - state->cube.size) 
        state->cube.position.x = screenWidth - state->cube.size;
    if (state->cube.position.y < state->titleBarHeight) 
        state->cube.position.y = state->titleBarHeight;
    if (state->cube.position.y > screenHeight - state->cube.size) 
        state->cube.position.y = screenHeight - state->cube.size;
    
    // Check collisions with walls - LEFT/RIGHT
    if (state->cube.position.x <= 0 || 
        state->cube.position.x >= screenWidth - state->cube.size)
    {
        state->cube.velocity.x = -state->cube.velocity.x * 0.6f;
    }
    
    // Check collisions with titlebar ceiling
    if (state->cube.position.y <= state->titleBarHeight)
    {
        state->cube.velocity.y = -state->cube.velocity.y * 0.6f;
    }
    
    // Floor collision with bounce
    if (state->cube.position.y >= screenHeight - state->cube.size)
    {
        state->cube.velocity.y = -state->cube.velocity.y * 0.5f;
        
        // Stop small bounces
        if (std::fabs(state->cube.velocity.y) < 50)
        {
            state->cube.velocity.y = 0;
        }
    }
}