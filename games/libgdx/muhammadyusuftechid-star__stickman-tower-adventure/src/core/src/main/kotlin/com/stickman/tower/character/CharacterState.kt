package com.stickman.tower.character

/**
 * State machine untuk gerakan dan aksi karakter.
 */
enum class CharacterState {
    IDLE,
    RUN,
    JUMP,
    FALL,
    ATTACK,
    HURT
}
