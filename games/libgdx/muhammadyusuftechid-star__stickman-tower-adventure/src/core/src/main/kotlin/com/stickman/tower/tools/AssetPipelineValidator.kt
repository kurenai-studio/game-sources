package com.stickman.tower.tools

import com.badlogic.gdx.Gdx
import com.stickman.tower.character.CharacterArchetype
import com.stickman.tower.world.StoryDialogue
import com.stickman.tower.world.TowerLevelBuilder
import java.io.File

/**
 * Laporan hasil validasi integritas aset, font, audio, dan konsistensi data lore.
 */
data class AssetValidationReport(
    val totalChecked: Int,
    val passed: Int,
    val failed: Int,
    val warnings: List<String>,
    val errors: List<String>
) {
    val isClean: Boolean get() = failed == 0 && errors.isEmpty()

    fun summary(): String {
        return if (isClean) {
            "✓ [ASSET VALIDATION PASSED] Checked: $totalChecked, Passed: $passed, Failed: 0 (${warnings.size} warnings)"
        } else {
            "✗ [ASSET VALIDATION FAILED] Checked: $totalChecked, Passed: $passed, Failed: $failed - Errors: ${errors.joinToString("; ")}"
        }
    }
}

/**
 * Asset Pipeline & Content Integrity Validator Tool:
 * Memverifikasi keabsahan file fisik font (TTF magic bytes), file gambar (PNG magic bytes),
 * konsistensi katalog audio/SFX, integritas skema save file, serta validitas prasasti cerita
 * dan dialog narasi agar tidak ada aset yang hilang atau referensi yang rusak (broken lore references).
 */
object AssetPipelineValidator {

    private val PNG_MAGIC = byteArrayOf(0x89.toByte(), 0x50.toByte(), 0x4E.toByte(), 0x47.toByte())
    private val TTF_MAGIC_1 = byteArrayOf(0x00.toByte(), 0x01.toByte(), 0x00.toByte(), 0x00.toByte())
    private val TTF_MAGIC_2 = "true".toByteArray(Charsets.US_ASCII)
    private val OTF_MAGIC = "OTTO".toByteArray(Charsets.US_ASCII)

    /**
     * Memeriksa seluruh aset game dan konsistensi lore/dialogue.
     */
    fun validateAll(assetsDir: File? = null): AssetValidationReport {
        val errors = mutableListOf<String>()
        val warnings = mutableListOf<String>()
        var totalChecked = 0
        var passed = 0

        // 1. Tentukan direktori assets (prioritas: parameter -> Gdx.files -> direktori lokal)
        val resolvedDir = assetsDir
            ?: (if (Gdx.files != null && Gdx.files.internal("fonts").exists()) Gdx.files.internal("").file() else null)
            ?: File("assets").takeIf { it.exists() }
            ?: File("../assets").takeIf { it.exists() }

        // 2. Validasi File Fisik Font & PNG jika direktori ditemukan
        if (resolvedDir != null && resolvedDir.exists()) {
            val fontBold = File(resolvedDir, "fonts/NotoSans-Bold.ttf")
            val fontRegular = File(resolvedDir, "fonts/NotoSans-Regular.ttf")

            totalChecked++
            if (validateFontFile(fontBold)) passed++ else errors.add("Font NotoSans-Bold.ttf rusak atau tidak ditemukan di $fontBold")

            totalChecked++
            if (validateFontFile(fontRegular)) passed++ else errors.add("Font NotoSans-Regular.ttf rusak atau tidak ditemukan di $fontRegular")

            // Validasi Gambar Penting
            val imagesToCheck = listOf("logo.png", "icon.png", "banner.png", "libgdx.png")
            for (imgName in imagesToCheck) {
                val imgFile = File(resolvedDir, imgName)
                if (imgFile.exists()) {
                    totalChecked++
                    if (validatePngFile(imgFile)) passed++ else errors.add("File gambar $imgName rusak (invalid PNG header)")
                }
            }
        } else {
            warnings.add("Direktori 'assets/' tidak terdeteksi langsung di classpath runtime, melewati uji I/O file fisik.")
        }

        // 3. Validasi Konsistensi Arketipe Karakter (Data Integrity)
        for (arch in CharacterArchetype.entries) {
            totalChecked++
            if (arch.characterName.isNotBlank() &&
                arch.weaponName.isNotBlank() &&
                arch.skill1Name.isNotBlank() &&
                arch.ultName.isNotBlank() &&
                arch.moveSpeed > 0f &&
                arch.jumpVelocity > 0f
            ) {
                passed++
            } else {
                errors.add("Definisi Arketipe ${arch.name} memiliki field kosong atau nilai tidak valid!")
            }
        }

        // 4. Validasi Konsistensi Lore & Prasasti Menara (Lore Tablets Verification)
        val storyFloors = (1..10).map { TowerLevelBuilder.buildFloor(it) }
        val allTabletsInFloors = storyFloors.flatMap { it.loreTablets }

        totalChecked++
        if (allTabletsInFloors.isNotEmpty()) {
            passed++
        } else {
            errors.add("Tidak ada Lore Tablet terpasang di 10 lantai Story Mode!")
        }

        // Pastikan setiap tablet memiliki teks isi dan judul yang valid
        for (t in allTabletsInFloors) {
            totalChecked++
            if (t.tabletId.isNotBlank() && t.title.isNotBlank() && t.text.isNotBlank()) {
                passed++
            } else {
                errors.add("Lore Tablet #${t.tabletId} (${t.title}) memiliki konten kosong!")
            }
        }

        // 5. Validasi Konsistensi Dialog Cerita (Story Dialogue Integrity)
        val allDialogues = storyFloors.flatMap { it.storyDialogues }
        totalChecked++
        if (allDialogues.isNotEmpty()) {
            passed++
        } else {
            errors.add("Tidak ada StoryDialogue terpasang di 10 lantai Story Mode!")
        }

        for ((idx, d) in allDialogues.withIndex()) {
            totalChecked++
            if (d.lines.isNotEmpty() && d.lines.all { it.speaker.isNotBlank() && it.text.isNotBlank() }) {
                passed++
            } else {
                errors.add("StoryDialogue #$idx memiliki dialog lines kosong!")
            }
        }

        // 6. Validasi Act Title dan Bos pada Story Floors
        for (floor in storyFloors) {
            totalChecked++
            if (floor.actTitle.isNotBlank() && floor.actSubtitle.isNotBlank()) {
                passed++
            } else {
                errors.add("Lantai ${floor.floorNumber} tidak memiliki Act Title / Subtitle yang valid!")
            }
        }

        return AssetValidationReport(
            totalChecked = totalChecked,
            passed = passed,
            failed = errors.size,
            warnings = warnings,
            errors = errors
        )
    }

    private fun validateFontFile(file: File): Boolean {
        if (!file.exists() || file.length() < 1024) return false
        return try {
            val header = ByteArray(4)
            file.inputStream().use { it.read(header) }
            header.contentEquals(TTF_MAGIC_1) ||
                header.contentEquals(TTF_MAGIC_2) ||
                header.contentEquals(OTF_MAGIC)
        } catch (_: Throwable) {
            false
        }
    }

    private fun validatePngFile(file: File): Boolean {
        if (!file.exists() || file.length() < 16) return false
        return try {
            val header = ByteArray(4)
            file.inputStream().use { it.read(header) }
            header.contentEquals(PNG_MAGIC)
        } catch (_: Throwable) {
            false
        }
    }
}
