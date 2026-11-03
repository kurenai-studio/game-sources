package com.stickman.tower.world

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import kotlin.math.sin

/**
 * Tipe objek penceritaan visual lingkungan (Environmental Storytelling Prop).
 * Memuat reruntuhan arsitektur, artefak bersejarah, dan anomali dunia Aethelgard per babak.
 */
enum class PropType(val displayName: String, val actBelonging: Int) {
    // Act I: Lower Bastion (Benteng Bawah & Jurang Duri)
    BROKEN_CHAIN("Rantai Besi Raksasa Terputus", 1),
    BEHEADED_STATUE("Patung Ksatria Terpenggal", 1),
    INK_SPLATTER_MURAL("Mural Noda Tinta Purba", 1),

    // Act II: Sunken Archives & Iron Foundry (Kawah Alkimia & Suaka Penempa)
    SHATTERED_BOOKSHELF("Rak Buku Arsip Tenggelam", 2),
    LEAKING_ALCHEMY_VAT("Tabung Alkimia Miasma Bocor", 2),
    TITAN_ANVIL("Paron Meteorit Vulcanus", 2),

    // Act III: The Astral Climb (Tebing Angkasa & Cermin Jiwa)
    VOID_WALL_CRACK("Retakan Dinding Jurang Kosmis", 3),
    BLOOD_ECLIPSE_ALTAR("Altar Gerhana Darah Valtheor", 3),

    // Act IV: The Primordial Canvas (Singgasana Kanvas Puncak)
    PURE_CANVAS_PILLAR("Pilar Marmer Kanvas Murni", 4),
    FROZEN_GOLDEN_BRUSH("Kuas Emas Primordial Mengambang", 4)
}

/**
 * Objek visual lingkungan yang dirender secara prosedural menggunakan ShapeRenderer.
 * Menghidupkan atmosfer penceritaan visual tanpa membebani memori dengan tekstur bitmap besar.
 */
class EnvironmentalProp(
    val x: Float,
    val y: Float,
    val width: Float,
    val height: Float,
    val type: PropType,
    val isForeground: Boolean = false
) {
    var animTime: Float = (0..100).random() * 0.1f

    fun update(delta: Float) {
        animTime += delta
    }

    fun render(shapeRenderer: ShapeRenderer) {
        when (type) {
            PropType.BROKEN_CHAIN -> renderBrokenChain(shapeRenderer)
            PropType.BEHEADED_STATUE -> renderBeheadedStatue(shapeRenderer)
            PropType.INK_SPLATTER_MURAL -> renderInkMural(shapeRenderer)
            PropType.SHATTERED_BOOKSHELF -> renderBookshelf(shapeRenderer)
            PropType.LEAKING_ALCHEMY_VAT -> renderAlchemyVat(shapeRenderer)
            PropType.TITAN_ANVIL -> renderTitanAnvil(shapeRenderer)
            PropType.VOID_WALL_CRACK -> renderVoidCrack(shapeRenderer)
            PropType.BLOOD_ECLIPSE_ALTAR -> renderBloodAltar(shapeRenderer)
            PropType.PURE_CANVAS_PILLAR -> renderCanvasPillar(shapeRenderer)
            PropType.FROZEN_GOLDEN_BRUSH -> renderGoldenBrush(shapeRenderer)
        }
    }

    private fun renderBrokenChain(shapeRenderer: ShapeRenderer) {
        val swing = sin(animTime * 1.5f) * 0.08f
        shapeRenderer.setColor(0.18f, 0.20f, 0.26f, 0.90f)

        // Rantai menggantung dari langit-langit (y + height) ke bawah (y)
        var currX = x + width / 2f
        var currY = y + height
        val links = 5
        val segH = height / links

        for (i in 0 until links) {
            val offsetX = swing * (i + 1)
            shapeRenderer.rectLine(currX, currY, currX + offsetX, currY - segH, 0.06f)
            shapeRenderer.circle(currX + offsetX, currY - segH, 0.08f, 6)
            currX += offsetX
            currY -= segH
        }

        // Ujung rantai terputus bergerigi
        shapeRenderer.setColor(0.35f, 0.38f, 0.48f, 0.95f)
        shapeRenderer.circle(currX, currY, 0.12f, 6)
    }

    private fun renderBeheadedStatue(shapeRenderer: ShapeRenderer) {
        val centerX = x + width / 2f

        // 1. Alas Patung Batu Obsidian
        shapeRenderer.setColor(0.12f, 0.14f, 0.18f, 0.95f)
        shapeRenderer.rect(x, y, width, height * 0.35f)

        // 2. Batang Tubuh Zirah Terpenggal
        shapeRenderer.setColor(0.20f, 0.24f, 0.32f, 0.95f)
        shapeRenderer.triangle(
            centerX - width * 0.40f, y + height * 0.35f,
            centerX + width * 0.40f, y + height * 0.35f,
            centerX, y + height * 0.90f
        )

        // 3. Bahu & Leher Terpotong dengan noda tinta
        shapeRenderer.setColor(0.15f, 0.18f, 0.24f, 0.95f)
        shapeRenderer.rect(centerX - width * 0.25f, y + height * 0.75f, width * 0.50f, height * 0.15f)

        // Noda Tinta Menetes dari Leher
        shapeRenderer.setColor(0.04f, 0.04f, 0.06f, 0.95f)
        shapeRenderer.circle(centerX, y + height * 0.90f, width * 0.15f, 8)
        shapeRenderer.rectLine(centerX - 0.08f, y + height * 0.85f, centerX - 0.08f, y + height * 0.50f, 0.04f)
        shapeRenderer.rectLine(centerX + 0.06f, y + height * 0.85f, centerX + 0.06f, y + height * 0.60f, 0.04f)
    }

    private fun renderInkMural(shapeRenderer: ShapeRenderer) {
        val centerX = x + width / 2f
        val centerY = y + height / 2f

        shapeRenderer.setColor(0.06f, 0.07f, 0.10f, 0.70f)
        shapeRenderer.circle(centerX, centerY, width * 0.45f, 10)
        shapeRenderer.circle(centerX + width * 0.2f, centerY + height * 0.15f, width * 0.25f, 8)
        shapeRenderer.circle(centerX - width * 0.25f, centerY - height * 0.1f, width * 0.20f, 8)

        // Coretan Tinta Dinamis
        shapeRenderer.rectLine(centerX - width * 0.4f, centerY - height * 0.2f, centerX + width * 0.45f, centerY + height * 0.25f, 0.08f)
    }

    private fun renderBookshelf(shapeRenderer: ShapeRenderer) {
        // Kerangka Rak Buku
        shapeRenderer.setColor(0.14f, 0.16f, 0.22f, 0.90f)
        shapeRenderer.rect(x, y, width, height)

        // Sekat Rak
        shapeRenderer.setColor(0.22f, 0.26f, 0.36f, 0.95f)
        val shelfH = height / 3f
        shapeRenderer.rectLine(x, y + shelfH, x + width, y + shelfH, 0.05f)
        shapeRenderer.rectLine(x, y + shelfH * 2f, x + width, y + shelfH * 2f, 0.05f)

        // Buku & Gulungan Kuno (Biru & Emas Pudar)
        shapeRenderer.setColor(0.30f, 0.45f, 0.65f, 0.85f)
        shapeRenderer.rect(x + 0.1f, y + 0.05f, 0.15f, shelfH - 0.1f)
        shapeRenderer.rect(x + 0.3f, y + 0.05f, 0.18f, shelfH - 0.12f)
        shapeRenderer.setColor(0.75f, 0.65f, 0.35f, 0.85f)
        shapeRenderer.rect(x + 0.12f, y + shelfH + 0.05f, 0.20f, shelfH - 0.08f)
        shapeRenderer.rect(x + 0.4f, y + shelfH + 0.05f, 0.14f, shelfH - 0.14f)

        // Retakan Kaca
        shapeRenderer.setColor(0.6f, 0.8f, 1.0f, 0.6f)
        shapeRenderer.rectLine(x + 0.1f, y + height - 0.1f, x + width * 0.7f, y + shelfH * 1.5f, 0.03f)
    }

    private fun renderAlchemyVat(shapeRenderer: ShapeRenderer) {
        val centerX = x + width / 2f
        val pulse = (sin(animTime * 3.5f) + 1f) * 0.5f

        // Kaca Silinder Tabung
        shapeRenderer.setColor(0.12f, 0.15f, 0.22f, 0.70f)
        shapeRenderer.rect(x, y + 0.1f, width, height - 0.2f)

        // Bingkai Logam Atas dan Bawah
        shapeRenderer.setColor(0.35f, 0.38f, 0.45f, 0.95f)
        shapeRenderer.rect(x - 0.05f, y, width + 0.10f, 0.12f)
        shapeRenderer.rect(x - 0.05f, y + height - 0.12f, width + 0.10f, 0.12f)

        // Cairan Miasma Ungu Berdenyut
        shapeRenderer.setColor(0.65f + 0.2f * pulse, 0.20f, 0.85f + 0.15f * pulse, 0.85f)
        shapeRenderer.rect(x + 0.05f, y + 0.12f, width - 0.10f, (height - 0.24f) * 0.65f)

        // Gelembung Cairan
        shapeRenderer.setColor(0.85f, 0.55f, 1.0f, 0.90f)
        val bubbleY = y + 0.2f + (sin(animTime * 4.0f) + 1f) * 0.2f
        shapeRenderer.circle(centerX - 0.1f, bubbleY, 0.05f, 6)
        shapeRenderer.circle(centerX + 0.12f, bubbleY + 0.15f, 0.04f, 6)

        // Kebocoran Cairan ke Lantai
        shapeRenderer.rectLine(centerX + width * 0.3f, y + 0.15f, centerX + width * 0.35f, y, 0.04f)
        shapeRenderer.circle(centerX + width * 0.35f, y, 0.08f, 6)
    }

    private fun renderTitanAnvil(shapeRenderer: ShapeRenderer) {
        val centerX = x + width / 2f
        val emberPulse = (sin(animTime * 5.0f) + 1f) * 0.5f

        // 1. Alas Paron Besi Meteorit
        shapeRenderer.setColor(0.18f, 0.20f, 0.28f, 0.95f)
        shapeRenderer.rect(x + 0.15f, y, width - 0.30f, height * 0.35f)

        // 2. Leher Paron
        shapeRenderer.rect(x + 0.30f, y + height * 0.35f, width - 0.60f, height * 0.25f)

        // 3. Kepala Tanduk Paron (Horisontal)
        shapeRenderer.rect(x, y + height * 0.60f, width, height * 0.40f)

        // 4. Nyala Bara Emas di Permukaan Atas Paron
        shapeRenderer.setColor(1.0f, 0.55f + 0.3f * emberPulse, 0.15f, 0.95f)
        shapeRenderer.rectLine(x + 0.05f, y + height - 0.03f, x + width - 0.05f, y + height - 0.03f, 0.08f)

        // Percikan Bara Api
        shapeRenderer.setColor(1.0f, 0.85f, 0.3f, 0.9f)
        val sparkY = y + height + 0.08f + emberPulse * 0.12f
        shapeRenderer.circle(centerX - 0.15f, sparkY, 0.04f, 6)
        shapeRenderer.circle(centerX + 0.20f, sparkY + 0.05f, 0.03f, 6)
    }

    private fun renderVoidCrack(shapeRenderer: ShapeRenderer) {
        val centerX = x + width / 2f
        val cosmicPulse = (sin(animTime * 2.5f) + 1f) * 0.5f

        // Retakan Dinding Hitam Luar
        shapeRenderer.setColor(0.03f, 0.03f, 0.06f, 0.95f)
        shapeRenderer.rect(x, y, width, height)

        // Cahaya Astral Ungu / Cyan dari Jurang Kosmis
        shapeRenderer.setColor(0.25f + 0.25f * cosmicPulse, 0.15f, 0.65f + 0.25f * cosmicPulse, 0.85f)
        shapeRenderer.triangle(
            centerX - width * 0.35f, y + height * 0.1f,
            centerX + width * 0.35f, y + height * 0.5f,
            centerX, y + height * 0.9f
        )

        // Bintang Kosmis Berkedip
        shapeRenderer.setColor(Color.WHITE)
        shapeRenderer.circle(centerX - 0.08f, y + height * 0.45f, 0.04f, 6)
        shapeRenderer.circle(centerX + 0.12f, y + height * 0.70f, 0.03f, 6)
        shapeRenderer.circle(centerX + 0.02f, y + height * 0.25f, 0.03f, 6)
    }

    private fun renderBloodAltar(shapeRenderer: ShapeRenderer) {
        val centerX = x + width / 2f

        // Meja Altar Obsidian Bertingkat
        shapeRenderer.setColor(0.10f, 0.12f, 0.16f, 0.95f)
        shapeRenderer.rect(x, y, width, height * 0.25f)
        shapeRenderer.rect(x + 0.15f, y + height * 0.25f, width - 0.30f, height * 0.45f)

        // Piringan Lilin Gerhana
        shapeRenderer.setColor(0.75f, 0.15f, 0.25f, 0.90f)
        shapeRenderer.rectLine(x + 0.1f, y + height * 0.70f, x + width - 0.1f, y + height * 0.70f, 0.06f)

        // Simbol Bulan Ungu di Tengah Altar
        shapeRenderer.setColor(0.85f, 0.35f, 0.95f, 0.95f)
        shapeRenderer.circle(centerX, y + height * 0.45f, width * 0.18f, 10)
        shapeRenderer.setColor(0.10f, 0.12f, 0.16f, 1.0f)
        shapeRenderer.circle(centerX + 0.06f, y + height * 0.48f, width * 0.14f, 10)
    }

    private fun renderCanvasPillar(shapeRenderer: ShapeRenderer) {
        // Pilar Marmer Kanvas Putih Bersih
        shapeRenderer.setColor(0.92f, 0.94f, 0.98f, 0.95f)
        shapeRenderer.rect(x + 0.1f, y, width - 0.2f, height)

        // Kapital & Basis Pilar Emas
        shapeRenderer.setColor(0.95f, 0.82f, 0.35f, 0.95f)
        shapeRenderer.rect(x, y, width, 0.12f)
        shapeRenderer.rect(x, y + height - 0.12f, width, 0.12f)

        // Garis Relief Emas Tipis
        shapeRenderer.rectLine(x + width * 0.35f, y + 0.15f, x + width * 0.35f, y + height - 0.15f, 0.03f)
        shapeRenderer.rectLine(x + width * 0.65f, y + 0.15f, x + width * 0.65f, y + height - 0.15f, 0.03f)
    }

    private fun renderGoldenBrush(shapeRenderer: ShapeRenderer) {
        val centerX = x + width / 2f
        val floatOffset = sin(animTime * 2.0f) * 0.12f
        val currY = y + floatOffset

        // Gagang Kuas Emas Mengambang
        shapeRenderer.setColor(0.95f, 0.82f, 0.30f, 0.95f)
        shapeRenderer.rectLine(centerX, currY + height * 0.35f, centerX, currY + height, 0.08f)

        // Gelang Penjepit Bulu Kuas
        shapeRenderer.setColor(0.75f, 0.60f, 0.20f, 0.95f)
        shapeRenderer.rect(centerX - 0.12f, currY + height * 0.30f, 0.24f, 0.10f)

        // Bulu Kuas Hitam Primordial dengan Tetesan Tinta
        shapeRenderer.setColor(0.05f, 0.05f, 0.08f, 0.95f)
        shapeRenderer.triangle(
            centerX - 0.15f, currY + height * 0.30f,
            centerX + 0.15f, currY + height * 0.30f,
            centerX, currY
        )

        // Tetesan Tinta Menggantung
        shapeRenderer.circle(centerX, currY - 0.05f, 0.05f, 6)
    }
}
