package com.stickman.tower.enemy

/**
 * Tipe Varian Musuh di Menara:
 * - MELEE: Petarung jarak dekat berbelati crimson (agresif mengejar dan menebas).
 * - RANGED: Pemanah/Penyihir jarak jauh amethyst (kiting/menjaga jarak dan menembakkan proyektil berkecepatan tinggi).
 * - FLYING: Siluet gargoyle/kelelawar udara (hover sinewave di atas pemain, swoop divebomb menukik tajam).
 * - SHIELDED: Ksatria perisai obsidian (kebal serangan depan normal, memerlukan backstab/cross-up atau Guard Break).
 */
enum class EnemyType {
    MELEE,
    RANGED,
    FLYING,
    SHIELDED
}

