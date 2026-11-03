package com.stickman.tower.combat

/**
 * Fase waktu dalam satu siklus serangan (Attack Lifecycle).
 */
enum class AttackPhase {
    INACTIVE, // Tidak sedang menyerang
    STARTUP,  // Ancang-ancang sebelum serangan aktif
    ACTIVE,   // Hitbox serangan aktif dan dapat melukai musuh
    RECOVERY  // Jeda setelah serangan sebelum bisa bergerak normal
}
