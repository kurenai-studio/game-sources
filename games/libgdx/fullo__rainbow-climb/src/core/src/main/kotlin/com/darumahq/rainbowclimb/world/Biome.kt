package com.darumahq.rainbowclimb.world

import com.badlogic.gdx.graphics.Color

enum class BiomeType {
    SKY_GARDEN,
    CLOUD_KINGDOM,
    NEON_CITY,
    CRYSTAL_CAVE,
    FIRE_RUINS,
    CANDY_LAND,
    SPACE_STATION,
    HAUNTED_FOREST
}

data class Biome(
    val type: BiomeType,
    val name: String,
    val bgColor: Color,
    val platformColor: Color,
    val accentColor: Color,
    val tempo: Int,       // BPM for music engine
    val musicMood: Float  // 0.0 = calm, 1.0 = intense
) {
    companion object {
        val ALL = listOf(
            Biome(BiomeType.SKY_GARDEN, "Sky Garden",
                Color(0.53f, 0.81f, 0.92f, 1f),
                Color(0.36f, 0.68f, 0.25f, 1f),
                Color(1f, 1f, 1f, 1f),
                tempo = 115, musicMood = 0.2f),

            Biome(BiomeType.CLOUD_KINGDOM, "Cloud Kingdom",
                Color(0.85f, 0.91f, 1f, 1f),
                Color(1f, 1f, 1f, 1f),
                Color(1f, 0.84f, 0f, 1f),
                tempo = 110, musicMood = 0.1f),

            Biome(BiomeType.NEON_CITY, "Neon City",
                Color(0.1f, 0.05f, 0.2f, 1f),
                Color(0.7f, 0.1f, 0.9f, 1f),
                Color(0f, 1f, 0.9f, 1f),
                tempo = 135, musicMood = 0.7f),

            Biome(BiomeType.CRYSTAL_CAVE, "Crystal Cave",
                Color(0.05f, 0.1f, 0.25f, 1f),
                Color(0.2f, 0.5f, 0.6f, 1f),
                Color(0.7f, 0.85f, 0.9f, 1f),
                tempo = 120, musicMood = 0.4f),

            Biome(BiomeType.FIRE_RUINS, "Fire Ruins",
                Color(0.15f, 0.05f, 0.02f, 1f),
                Color(0.5f, 0.2f, 0.1f, 1f),
                Color(1f, 0.5f, 0f, 1f),
                tempo = 140, musicMood = 0.9f),

            Biome(BiomeType.CANDY_LAND, "Candy Land",
                Color(1f, 0.9f, 0.95f, 1f),
                Color(1f, 0.6f, 0.8f, 1f),
                Color(0.6f, 1f, 0.8f, 1f),
                tempo = 125, musicMood = 0.3f),

            Biome(BiomeType.SPACE_STATION, "Space Station",
                Color(0.02f, 0.02f, 0.08f, 1f),
                Color(0.3f, 0.3f, 0.4f, 1f),
                Color(0.2f, 0.5f, 1f, 1f),
                tempo = 130, musicMood = 0.6f),

            Biome(BiomeType.HAUNTED_FOREST, "Haunted Forest",
                Color(0.05f, 0.1f, 0.05f, 1f),
                Color(0.2f, 0.35f, 0.15f, 1f),
                Color(0.5f, 0.3f, 0.6f, 1f),
                tempo = 118, musicMood = 0.5f)
        )
    }
}
