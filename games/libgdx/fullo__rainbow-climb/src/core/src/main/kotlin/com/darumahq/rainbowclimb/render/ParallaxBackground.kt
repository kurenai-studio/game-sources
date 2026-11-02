package com.darumahq.rainbowclimb.render

import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.g2d.SpriteBatch
import com.badlogic.gdx.graphics.g2d.TextureRegion
import com.darumahq.rainbowclimb.util.Constants
import com.darumahq.rainbowclimb.world.Biome
import com.darumahq.rainbowclimb.world.BiomeType

class ParallaxBackground(private val sprites: SpriteManager) {

    private val scrollSpeeds = floatArrayOf(0.03f, 0.12f, 0.25f)

    // Cache TextureRegions per biome to avoid per-frame allocation
    private val regionCache = mutableMapOf<BiomeType, List<TextureRegion>>()

    private fun getRegions(biome: Biome): List<TextureRegion> {
        return regionCache.getOrPut(biome.type) {
            sprites.getBackgroundLayers(biome.type).map { TextureRegion(it) }
        }
    }

    fun render(batch: SpriteBatch, cameraY: Float, biome: Biome) {
        val regions = getRegions(biome)
        batch.setColor(Color.WHITE)

        for (i in regions.indices) {
            val region = regions[i]
            val speed = if (i < scrollSpeeds.size) scrollSpeeds[i] else 0.3f
            val offset = (cameraY * speed) % Constants.VIRTUAL_HEIGHT

            batch.draw(region, 0f, -offset, Constants.VIRTUAL_WIDTH, Constants.VIRTUAL_HEIGHT)
            batch.draw(region, 0f, Constants.VIRTUAL_HEIGHT - offset, Constants.VIRTUAL_WIDTH, Constants.VIRTUAL_HEIGHT)
        }
    }
}
