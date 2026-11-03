package com.stickman.tower.input

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class VirtualControllerViewportTest {

    @Test
    fun testVirtualControllerButtonPlacement() {
        val controller = VirtualController()
        controller.resize(1280, 720)

        // Verifikasi D-Pad (Lingkaran)
        assertEquals(85f, controller.btnLeft.x)
        assertEquals(95f, controller.btnLeft.y)
        assertEquals(45f, controller.btnLeft.radius)

        assertEquals(200f, controller.btnRight.x)
        assertEquals(95f, controller.btnRight.y)
        assertEquals(45f, controller.btnRight.radius)

        // Verifikasi Tombol Aksi Kanan Layar (Ergonomic Concentric Arc Layout)
        val atkX = 1280f - 120f
        val atkY = 110f
        assertEquals(atkX, controller.btnAttack.x)
        assertEquals(atkY, controller.btnAttack.y)
        assertEquals(54f, controller.btnAttack.radius)

        // JUMP (Bawah Kiri Attack)
        assertEquals(atkX - 110f, controller.btnJump.x)
        assertEquals(atkY - 22f, controller.btnJump.y)
        assertEquals(38f, controller.btnJump.radius)

        // DASH (Kiri Attack, di atas Jump)
        assertEquals(atkX - 128f, controller.btnDodge.x)
        assertEquals(atkY + 65f, controller.btnDodge.y)
        assertEquals(38f, controller.btnDodge.radius)

        // Multi-Skill Arc: SK1, SK2, SK3
        assertEquals(atkX + 16f, controller.btnSkill1.x)
        assertEquals(atkY + 128f, controller.btnSkill1.y)
        assertEquals(36f, controller.btnSkill1.radius)
        assertEquals(controller.btnSkill1.x, controller.btnSkill.x) // backward-compatibility alias

        assertEquals(atkX - 68f, controller.btnSkill2.x)
        assertEquals(atkY + 162f, controller.btnSkill2.y)
        assertEquals(36f, controller.btnSkill2.radius)

        assertEquals(atkX - 156f, controller.btnSkill3.x)
        assertEquals(atkY + 150f, controller.btnSkill3.y)
        assertEquals(36f, controller.btnSkill3.radius)

        // ULT (Puncak Mahkota / Apex Crown di atas SK2 & SK3)
        assertEquals(atkX - 106f, controller.btnUltimate.x)
        assertEquals(atkY + 246f, controller.btnUltimate.y)
        assertEquals(42f, controller.btnUltimate.radius)
    }

    @Test
    fun testNoButtonOverlap() {
        val controller = VirtualController()
        controller.resize(1280, 720)

        val actionButtons = listOf(
            "ATK" to controller.btnAttack,
            "JUMP" to controller.btnJump,
            "DASH" to controller.btnDodge,
            "SK1" to controller.btnSkill1,
            "SK2" to controller.btnSkill2,
            "SK3" to controller.btnSkill3,
            "ULT" to controller.btnUltimate
        )

        // Verifikasi bahwa SETIAP pasangan tombol memiliki jarak >= radius1 + radius2 + minGap (minimal 10px visual clearance)
        for (i in actionButtons.indices) {
            for (j in (i + 1) until actionButtons.size) {
                val (name1, b1) = actionButtons[i]
                val (name2, b2) = actionButtons[j]
                val dx = b1.x - b2.x
                val dy = b1.y - b2.y
                val dist = kotlin.math.sqrt(dx * dx + dy * dy)
                val requiredMinDist = b1.radius + b2.radius + 10f
                assertTrue(
                    dist >= requiredMinDist,
                    "Overlap detected between $name1 and $name2! dist=$dist, required=$requiredMinDist"
                )
            }
        }
    }

    @Test
    fun testButtonHitTesting() {
        val controller = VirtualController()
        controller.resize(1280, 720)

        // Point tepat di tengah tombol Attack
        assertTrue(controller.btnAttack.contains(1280f - 120f, 110f))
        // Point di luar radius
        assertFalse(controller.btnAttack.contains(0f, 0f))
        assertFalse(controller.btnAttack.contains(1280f - 120f + 60f, 110f))

        // D-Pad hit-testing
        assertTrue(controller.btnLeft.contains(85f, 95f))
        assertTrue(controller.btnRight.contains(200f, 95f))
    }
}
