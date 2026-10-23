#include "../include/NativeRoguelikeCore.h"
#include <cmath>
#include <algorithm>

NATIVE_API void Native_Steering_ComputeSwarm(
    const float* inPositionsX,
    const float* inPositionsY,
    const float* inVelocitiesX,
    const float* inVelocitiesY,
    int count,
    float targetX,
    float targetY,
    float targetSpeed,
    float separationRadius,
    float separationWeight,
    float* outVelocitiesX,
    float* outVelocitiesY
) {
    if (count <= 0 || !inPositionsX || !inPositionsY || !outVelocitiesX || !outVelocitiesY) {
        return;
    }

    const float sepRadSq = separationRadius * separationRadius;
    const float invSepRad = (separationRadius > 0.001f) ? (1.0f / separationRadius) : 1.0f;

    for (int i = 0; i < count; ++i) {
        float px = inPositionsX[i];
        float py = inPositionsY[i];

        // 1. Vector to player / target
        float toTargetX = targetX - px;
        float toTargetY = targetY - py;
        float distToTarget = std::sqrt(toTargetX * toTargetX + toTargetY * toTargetY);

        float desiredVx = 0.0f;
        float desiredVy = 0.0f;

        if (distToTarget > 0.001f) {
            desiredVx = (toTargetX / distToTarget) * targetSpeed;
            desiredVy = (toTargetY / distToTarget) * targetSpeed;
        }

        // 2. Separation force against other flock members
        float sepForceX = 0.0f;
        float sepForceY = 0.0f;
        int neighborCount = 0;

        for (int j = 0; j < count; ++j) {
            if (i == j) continue;

            float dx = px - inPositionsX[j];
            float dy = py - inPositionsY[j];
            float dSq = dx * dx + dy * dy;

            if (dSq > 0.0001f && dSq < sepRadSq) {
                float dist = std::sqrt(dSq);
                float strength = (1.0f - dist * invSepRad);
                sepForceX += (dx / dist) * strength;
                sepForceY += (dy / dist) * strength;
                neighborCount++;
            }
        }

        if (neighborCount > 0) {
            sepForceX *= separationWeight;
            sepForceY *= separationWeight;
        }

        // Combined velocity
        float finalVx = desiredVx + sepForceX;
        float finalVy = desiredVy + sepForceY;

        // Cap speed
        float finalSpeedSq = finalVx * finalVx + finalVy * finalVy;
        float maxSpeed = targetSpeed * 1.35f;
        if (finalSpeedSq > maxSpeed * maxSpeed) {
            float finalSpeed = std::sqrt(finalSpeedSq);
            finalVx = (finalVx / finalSpeed) * maxSpeed;
            finalVy = (finalVy / finalSpeed) * maxSpeed;
        }

        outVelocitiesX[i] = finalVx;
        outVelocitiesY[i] = finalVy;
    }
}
