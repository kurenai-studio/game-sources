package com.stickman.tower.screen

/**
 * Status kondisi permainan pada game loop stage MVP.
 */
enum class GameStatus {
    PLAYING,     // Pemain sedang aktif bermain dan menjelajah
    GAME_OVER,   // HP pemain habis (kalah), dapat respawn di Checkpoint
    STAGE_CLEAR  // Pemain mengalahkan musuh & mencapai portal (menang MVP)
}
