package com.stickman.tower.companion

import com.badlogic.gdx.graphics.Color

/**
 * Tipe Roh Pendamping Tinta (Ink Familiar Companion Type).
 * Entitas roh penolong berwujud siluet magis melayang di samping bahu karakter.
 */
enum class FamiliarType(
    val id: String,
    val displayName: String,
    val subtitle: String,
    val lore: String,
    val unlockFloor: Int,
    val primaryColor: Color,
    val secondaryColor: Color
) {
    NONE(
        id = "NONE",
        displayName = "Tanpa Pendamping",
        subtitle = "Melangkah Sendiri",
        lore = "Mengembara di Menara Aethelgard hanya bermodalkan bilah pedang di genggaman tangan.",
        unlockFloor = 1,
        primaryColor = Color.GRAY,
        secondaryColor = Color.DARK_GRAY
    ),

    ARIA_WISP(
        id = "ARIA_WISP",
        displayName = "Gema Lentera Aria",
        subtitle = "Lentera Penuntun Jiwa",
        lore = "Percikan cahaya lentera jiwa dari Aria sang Gema Warna Terakhir. Menuntun langkah sang ksatria dan secara magnetis menarik pecahan emas Aethel dari jarak jauh.",
        unlockFloor = 1,
        primaryColor = Color(0.35f, 0.95f, 0.85f, 1f), // Cyan bercahaya
        secondaryColor = Color(1.0f, 0.85f, 0.30f, 1f)  // Emas murni
    ),

    VULCAN_SPARK(
        id = "VULCAN_SPARK",
        displayName = "Bara Suci Vulcanus",
        subtitle = "Nyala Api Paron Meteorit",
        lore = "Percikan bara api hidup yang dipukul dari paron meteorit Vulcanus di Lantai 6. Menyelimuti bilah pedang dengan panas pembakar yang sanggup menyulut tinta hitam musuh.",
        unlockFloor = 6,
        primaryColor = Color(1.0f, 0.38f, 0.12f, 1f), // Jingga api
        secondaryColor = Color(1.0f, 0.88f, 0.25f, 1f)  // Kuning bara
    ),

    PHANTOM_SHADOW(
        id = "PHANTOM_SHADOW",
        displayName = "Bayangan Hantu Astral",
        subtitle = "Cermin Jiwa Penakluk",
        lore = "Esensi bayangan batin yang dijinakkan setelah menundukkan Doppelgänger di Balairung Cermin Lantai 8. Menghunjamkan tebasan bayangan ekstra saat pertahanan musuh runtuh.",
        unlockFloor = 8,
        primaryColor = Color(0.68f, 0.22f, 0.95f, 1f), // Ungu astral
        secondaryColor = Color(0.95f, 0.18f, 0.28f, 1f)  // Merah delima
    );

    companion object {
        fun fromString(name: String?): FamiliarType {
            if (name.isNullOrBlank()) return ARIA_WISP
            return try {
                valueOf(name.trim().uppercase())
            } catch (_: Exception) {
                ARIA_WISP
            }
        }
    }
}
