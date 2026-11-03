package com.stickman.tower.ui

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.Texture
import com.badlogic.gdx.graphics.g2d.BitmapFont
import com.badlogic.gdx.graphics.g2d.freetype.FreeTypeFontGenerator
import com.badlogic.gdx.graphics.g2d.freetype.FreeTypeFontGenerator.FreeTypeFontParameter

/**
 * Manajer Tipografi Terpusat untuk Stickman Tower Adventure.
 * Menghasilkan font beresolusi tinggi, anti-aliased dengan linear filtering menggunakan FreeType,
 * serta memuat karakter set lengkap (termasuk bullet, simbol RPG, rune, dan panah) untuk mencegah
 * rendering simbol kotak kosong (□).
 *
 * Menerapkan jaminan Zero-Allocation Fallback: Jika FreeType gagal atau dalam lingkungan headless,
 * font akan dialihkan secara transparan ke instance static cached fallback tanpa mengalokasikan
 * objek baru di setiap frame render loop.
 *
 * ══════════════════════════════════════════════════════════════════════════════
 * STANDAR TOKEN TIPOGRAFI INDUSTRI (Game UI Typography Design System - Major Third 1.25x Scale):
 * 1. TOKEN_DISPLAY    (titleFont: 32pt Bold)    -> H1 Judul Layar, Big Banners (2.0x).
 * 2. TOKEN_HEADING    (headerFont: 22pt Bold)   -> H2 Judul Seksi/Panel, Nama Bos, Tombol CTA Utama (1.38x).
 * 3. TOKEN_SUBHEADING (subheadFont: 18pt Bold)  -> H3 Judul Kartu, Header Dialog, Bookmark Badge (1.13x).
 * 4. TOKEN_BODY       (regularFont: 16pt Reg)   -> Konten Cerita/Lore, Deskripsi Skill, Tombol Standar (1.0x).
 * 5. TOKEN_CAPTION    (smallFont: 13pt Reg)     -> Thematic Ink Pills, Badge Status, Cooldown, Footer (0.81x).
 * ══════════════════════════════════════════════════════════════════════════════
 */
object FontManager {
    var isInitialized = false
        private set

    private var _titleFont: BitmapFont? = null
    private var _headerFont: BitmapFont? = null
    private var _subheadFont: BitmapFont? = null
    private var _regularFont: BitmapFont? = null
    private var _smallFont: BitmapFont? = null

    // Single static cached fallback instance to guarantee zero heap allocations in render loops
    private var _cachedFallbackFont: BitmapFont? = null

    private fun getSafeFallback(): BitmapFont {
        if (_cachedFallbackFont == null) {
            try {
                _cachedFallbackFont = BitmapFont()
            } catch (_: Throwable) {
                // Dalam headless testing tanpa OpenGL context
            }
        }
        return _cachedFallbackFont ?: try { BitmapFont() } catch (_: Throwable) { BitmapFont() }
    }

    val titleFont: BitmapFont
        get() = _titleFont ?: getSafeFallback()

    val headerFont: BitmapFont
        get() = _headerFont ?: getSafeFallback()

    val subheadFont: BitmapFont
        get() = _subheadFont ?: getSafeFallback()

    val regularFont: BitmapFont
        get() = _regularFont ?: getSafeFallback()

    val smallFont: BitmapFont
        get() = _smallFont ?: getSafeFallback()

    const val EXTRA_CHARS = "•★⚔◀▶~✓✕☼☽⚡☯◇◈◆▲▼—'\"✦"

    fun init() {
        if (isInitialized) return

        try {
            val boldFile = Gdx.files?.internal("fonts/NotoSans-Bold.ttf")
            val regularFile = Gdx.files?.internal("fonts/NotoSans-Regular.ttf")

            if (boldFile != null && boldFile.exists() && regularFile != null && regularFile.exists()) {
                val boldGen = FreeTypeFontGenerator(boldFile)
                val regularGen = FreeTypeFontGenerator(regularFile)

                val paramTitle = FreeTypeFontParameter().apply {
                    size = 32
                    color = Color.WHITE
                    minFilter = Texture.TextureFilter.Linear
                    magFilter = Texture.TextureFilter.Linear
                    characters = FreeTypeFontGenerator.DEFAULT_CHARS + EXTRA_CHARS
                }
                _titleFont = boldGen.generateFont(paramTitle)

                val paramHeader = FreeTypeFontParameter().apply {
                    size = 22
                    color = Color.WHITE
                    minFilter = Texture.TextureFilter.Linear
                    magFilter = Texture.TextureFilter.Linear
                    characters = FreeTypeFontGenerator.DEFAULT_CHARS + EXTRA_CHARS
                }
                _headerFont = boldGen.generateFont(paramHeader)

                val paramSubhead = FreeTypeFontParameter().apply {
                    size = 18
                    color = Color.WHITE
                    minFilter = Texture.TextureFilter.Linear
                    magFilter = Texture.TextureFilter.Linear
                    characters = FreeTypeFontGenerator.DEFAULT_CHARS + EXTRA_CHARS
                }
                _subheadFont = boldGen.generateFont(paramSubhead)

                val paramRegular = FreeTypeFontParameter().apply {
                    size = 16
                    color = Color.WHITE
                    minFilter = Texture.TextureFilter.Linear
                    magFilter = Texture.TextureFilter.Linear
                    characters = FreeTypeFontGenerator.DEFAULT_CHARS + EXTRA_CHARS
                }
                _regularFont = regularGen.generateFont(paramRegular)

                val paramSmall = FreeTypeFontParameter().apply {
                    size = 13
                    color = Color.WHITE
                    minFilter = Texture.TextureFilter.Linear
                    magFilter = Texture.TextureFilter.Linear
                    characters = FreeTypeFontGenerator.DEFAULT_CHARS + EXTRA_CHARS
                }
                _smallFont = regularGen.generateFont(paramSmall)

                boldGen.dispose()
                regularGen.dispose()
                isInitialized = true
                Gdx.app?.log("FontManager", "FreeType fonts successfully generated and cached.")
                return
            }
        } catch (e: Throwable) {
            Gdx.app?.error("FontManager", "Failed to load FreeType font, falling back to default BitmapFont", e)
        }

        // Fallback jika file tidak ditemukan atau di lingkungan test tanpa backend GL
        createFallbackFonts()
    }

    private fun createFallbackFonts() {
        try {
            val fallback = BitmapFont()
            _cachedFallbackFont = fallback
            _titleFont = BitmapFont().apply { data.setScale(2.2f) }
            _headerFont = BitmapFont().apply { data.setScale(1.6f) }
            _subheadFont = BitmapFont().apply { data.setScale(1.35f) }
            _regularFont = BitmapFont().apply { data.setScale(1.1f) }
            _smallFont = BitmapFont().apply { data.setScale(0.85f) }
        } catch (_: Throwable) {
            // Dalam headless test tanpa Gdx.graphics/gl
        }
        isInitialized = true
    }

    fun dispose() {
        if (!isInitialized) return
        try {
            _titleFont?.dispose()
            _headerFont?.dispose()
            _subheadFont?.dispose()
            _regularFont?.dispose()
            _smallFont?.dispose()
            _cachedFallbackFont?.dispose()
        } catch (_: Throwable) {}
        _titleFont = null
        _headerFont = null
        _subheadFont = null
        _regularFont = null
        _smallFont = null
        _cachedFallbackFont = null
        isInitialized = false
    }
}

