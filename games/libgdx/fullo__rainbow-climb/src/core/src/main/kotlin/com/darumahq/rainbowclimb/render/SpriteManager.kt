package com.darumahq.rainbowclimb.render

import com.badlogic.gdx.Gdx
import com.badlogic.gdx.graphics.Texture
import com.badlogic.gdx.graphics.g2d.Animation
import com.badlogic.gdx.graphics.g2d.BitmapFont
import com.badlogic.gdx.graphics.g2d.TextureAtlas
import com.badlogic.gdx.graphics.g2d.TextureRegion
import com.badlogic.gdx.graphics.g2d.freetype.FreeTypeFontGenerator
import com.badlogic.gdx.utils.Array as GdxArray
import com.badlogic.gdx.utils.Disposable
import com.darumahq.rainbowclimb.entity.EnemyType
import com.darumahq.rainbowclimb.entity.PlayerCharacter
import com.darumahq.rainbowclimb.world.BiomeType

class SpriteManager : Disposable {

    private val textures = mutableListOf<Texture>()
    private lateinit var atlas: TextureAtlas

    // Player animations per character
    lateinit var allPlayerAnims: Map<PlayerCharacter, Map<String, Animation<TextureRegion>>>
        private set

    // Enemy animations: EnemyType -> (animName -> Animation)
    lateinit var enemyAnims: Map<EnemyType, Map<String, Animation<TextureRegion>>>
        private set

    // Boss animations
    lateinit var bossAnims: Map<String, Animation<TextureRegion>>
        private set

    // Collectible fruit animations (list, pick randomly)
    lateinit var fruitAnims: List<Animation<TextureRegion>>
        private set
    lateinit var collectEffect: Animation<TextureRegion>
        private set

    // Gem animations by color name
    lateinit var gemAnims: Map<String, Animation<TextureRegion>>
        private set

    // Backgrounds per biome (3 parallax layers each)
    lateinit var bgLayers: Map<BiomeType, List<Texture>>
        private set

    // Platform textures
    lateinit var platformBrown: TextureRegion
        private set
    lateinit var platformGrey: TextureRegion
        private set
    lateinit var platformCrumble: TextureRegion
        private set
    lateinit var rainbowBridge: Animation<TextureRegion>
        private set

    // Font
    lateinit var pixelFont: BitmapFont
        private set

    fun load() {
        atlas = TextureAtlas(Gdx.files.internal("game.atlas"))
        loadPlayerAnims()
        loadEnemyAnims()
        loadBossAnims()
        loadCollectibleAnims()
        loadGemAnims()
        loadBackgrounds()
        loadPlatforms()
        loadFont()
    }

    // ── Loading helpers ──────────────────────────────────────────

    private fun loadStrip(path: String, frameW: Int, frameH: Int,
                          frameDuration: Float = 0.05f,
                          playMode: Animation.PlayMode = Animation.PlayMode.LOOP
    ): Animation<TextureRegion> {
        // Try atlas first, fall back to individual texture
        val atlasName = path.replace("/", "_").replace(".png", "")
        val region = atlas.findRegion(atlasName)

        if (region != null) {
            val numFrames = region.regionWidth / frameW
            val frames = GdxArray<TextureRegion>(numFrames)
            for (i in 0 until numFrames) {
                frames.add(TextureRegion(region.texture,
                    region.regionX + i * frameW, region.regionY, frameW, frameH))
            }
            return Animation(frameDuration, frames, playMode)
        }

        // Fallback: load individual file
        val tex = Texture(Gdx.files.internal(path))
        tex.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest)
        textures.add(tex)
        val numFrames = tex.width / frameW
        val frames = GdxArray<TextureRegion>(numFrames)
        for (i in 0 until numFrames) {
            frames.add(TextureRegion(tex, i * frameW, 0, frameW, frameH))
        }
        return Animation(frameDuration, frames, playMode)
    }

    // ── Player ───────────────────────────────────────────────────

    private fun loadPlayerAnims() {
        val allAnims = mutableMapOf<PlayerCharacter, Map<String, Animation<TextureRegion>>>()
        for (character in PlayerCharacter.entries) {
            val map = mutableMapOf<String, Animation<TextureRegion>>()
            val base = character.spritePath
            map["idle"] = loadStrip("$base/idle.png", 32, 32)
            map["run"] = loadStrip("$base/run.png", 32, 32)
            map["jump"] = loadStrip("$base/jump.png", 32, 32, playMode = Animation.PlayMode.NORMAL)
            map["fall"] = loadStrip("$base/fall.png", 32, 32, playMode = Animation.PlayMode.NORMAL)
            map["hit"] = loadStrip("$base/hit.png", 32, 32, playMode = Animation.PlayMode.NORMAL)
            map["double_jump"] = loadStrip("$base/double_jump.png", 32, 32, playMode = Animation.PlayMode.NORMAL)
            allAnims[character] = map
        }
        allPlayerAnims = allAnims
    }

    // ── Enemies ──────────────────────────────────────────────────

    private fun loadEnemyAnims() {
        val map = mutableMapOf<EnemyType, Map<String, Animation<TextureRegion>>>()

        // Walker (17x14 frames)
        map[EnemyType.WALKER] = loadEnemySet("sprites/enemies/walker", 32, 32,
            listOf("idle", "run", "dead", "hit", "attack"))

        // Flyer (15x15 frames)
        map[EnemyType.FLYER] = mapOf(
            "spin" to loadStrip("sprites/enemies/flyer/spin.png", 32, 32)
        )

        // Hopper (16x16)
        map[EnemyType.HOPPER] = loadEnemySet("sprites/enemies/hopper", 32, 32,
            listOf("idle", "jump", "fall", "dead"))

        // Shooter (16x16)
        map[EnemyType.SHOOTER] = loadEnemySet("sprites/enemies/shooter", 32, 32,
            listOf("idle", "attack"))

        // Bomber (16x16)
        map[EnemyType.BOMBER] = loadEnemySet("sprites/enemies/bomber", 32, 32,
            listOf("idle", "run", "throw"))

        // Chaser (16x16)
        map[EnemyType.CHASER] = loadEnemySet("sprites/enemies/chaser", 32, 32,
            listOf("idle", "run", "attack", "dead"))

        enemyAnims = map
    }

    private fun loadEnemySet(basePath: String, frameW: Int, frameH: Int,
                             animNames: List<String>): Map<String, Animation<TextureRegion>> {
        val map = mutableMapOf<String, Animation<TextureRegion>>()
        for (name in animNames) {
            val path = "$basePath/$name.png"
            try {
                val mode = if (name == "dead" || name == "hit") Animation.PlayMode.NORMAL else Animation.PlayMode.LOOP
                map[name] = loadStrip(path, frameW, frameH, playMode = mode)
            } catch (e: Exception) {
                // Skip missing animations silently
            }
        }
        return map
    }

    // ── Boss ─────────────────────────────────────────────────────

    private fun loadBossAnims() {
        val map = mutableMapOf<String, Animation<TextureRegion>>()
        val base = "sprites/boss"
        for (name in listOf("idle", "run", "attack", "jump")) {
            map[name] = loadStrip("$base/$name.png", 64, 48)
        }
        map["hit"] = loadStrip("$base/hit.png", 64, 48, playMode = Animation.PlayMode.NORMAL)
        map["dead"] = loadStrip("$base/dead.png", 64, 48, playMode = Animation.PlayMode.NORMAL)
        bossAnims = map
    }

    fun getBossAnim(state: String): Animation<TextureRegion> {
        return bossAnims[state] ?: bossAnims["idle"]!!
    }

    // ── Collectibles ─────────────────────────────────────────────

    private fun loadCollectibleAnims() {
        val fruits = mutableListOf<Animation<TextureRegion>>()
        for (name in listOf("apple", "cherries", "orange", "bananas", "strawberry", "kiwi")) {
            fruits.add(loadStrip("sprites/collectibles/$name.png", 32, 32))
        }
        fruitAnims = fruits
        collectEffect = loadStrip("sprites/collectibles/collected.png", 32, 32,
            playMode = Animation.PlayMode.NORMAL)
    }

    // ── Gems ─────────────────────────────────────────────────────

    private fun loadGemAnims() {
        val map = mutableMapOf<String, Animation<TextureRegion>>()
        for (color in listOf("blue", "red", "gold", "purple", "turquoise", "light_green", "lilac", "dark_blue")) {
            map[color] = loadStrip("sprites/gems/gem_$color.png", 16, 16)
        }
        gemAnims = map
    }

    // ── Backgrounds ──────────────────────────────────────────────

    private fun loadBackgrounds() {
        val bgMap = mutableMapOf<BiomeType, List<Texture>>()
        val biomeNames = mapOf(
            BiomeType.SKY_GARDEN to "sky_garden",
            BiomeType.CLOUD_KINGDOM to "cloud_kingdom",
            BiomeType.NEON_CITY to "neon_city",
            BiomeType.CRYSTAL_CAVE to "crystal_cave",
            BiomeType.FIRE_RUINS to "fire_ruins",
            BiomeType.CANDY_LAND to "candy_land",
            BiomeType.SPACE_STATION to "space_station",
            BiomeType.HAUNTED_FOREST to "haunted_forest"
        )
        for ((biome, name) in biomeNames) {
            val layers = (0..2).map { i ->
                val t = Texture(Gdx.files.internal("backgrounds/bg_${name}_${i}.png"))
                t.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest)
                textures.add(t)
                t
            }
            bgMap[biome] = layers
        }
        bgLayers = bgMap
    }

    // ── Platforms ─────────────────────────────────────────────────

    private fun loadPlatforms() {
        // Load from atlas
        platformBrown = atlas.findRegion("tiles_platform_brown_off") ?: loadFallbackRegion("tiles/platform_brown_off.png")
        platformGrey = atlas.findRegion("tiles_platform_grey_off") ?: loadFallbackRegion("tiles/platform_grey_off.png")
        platformCrumble = atlas.findRegion("tiles_platform_falling_off") ?: loadFallbackRegion("tiles/platform_falling_off.png")

        // Rainbow bridge (animated glowing platform)
        rainbowBridge = loadStrip("tiles/platform_grey_on.png", 32, 8)
    }

    private fun loadFallbackRegion(path: String): TextureRegion {
        val tex = Texture(Gdx.files.internal(path))
        tex.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest)
        textures.add(tex)
        return TextureRegion(tex)
    }

    // ── Font ─────────────────────────────────────────────────────

    private fun loadFont() {
        val generator = FreeTypeFontGenerator(Gdx.files.internal("fonts/PublicPixel.ttf"))
        val param = FreeTypeFontGenerator.FreeTypeFontParameter().apply {
            size = 16
            minFilter = Texture.TextureFilter.Nearest
            magFilter = Texture.TextureFilter.Nearest
            mono = true
        }
        pixelFont = generator.generateFont(param)
        generator.dispose()
    }

    // ── Accessors ────────────────────────────────────────────────

    fun getPlayerAnim(character: PlayerCharacter, state: String): Animation<TextureRegion> {
        val charAnims = allPlayerAnims[character] ?: allPlayerAnims[PlayerCharacter.PINK_MAN]!!
        return charAnims[state] ?: charAnims["idle"]!!
    }

    fun getEnemyAnim(type: EnemyType, state: String): Animation<TextureRegion> {
        val typeAnims = enemyAnims[type] ?: return enemyAnims[EnemyType.WALKER]!!["idle"]!!
        return typeAnims[state] ?: typeAnims.values.first()
    }

    /** Get gem animation matching a biome's color theme */
    fun getGemAnimForBiome(biomeType: BiomeType): Animation<TextureRegion> {
        val color = when (biomeType) {
            BiomeType.SKY_GARDEN -> "blue"
            BiomeType.CLOUD_KINGDOM -> "gold"
            BiomeType.NEON_CITY -> "purple"
            BiomeType.CRYSTAL_CAVE -> "turquoise"
            BiomeType.FIRE_RUINS -> "red"
            BiomeType.CANDY_LAND -> "lilac"
            BiomeType.SPACE_STATION -> "dark_blue"
            BiomeType.HAUNTED_FOREST -> "light_green"
        }
        return gemAnims[color] ?: gemAnims["blue"]!!
    }

    fun getBackgroundLayers(biomeType: BiomeType): List<Texture> {
        return bgLayers[biomeType] ?: bgLayers[BiomeType.SKY_GARDEN]!!
    }

    fun getRandomFruit(seed: Int): Animation<TextureRegion> {
        return fruitAnims[seed.and(0x7FFFFFFF) % fruitAnims.size]
    }

    override fun dispose() {
        if (::atlas.isInitialized) atlas.dispose()
        textures.forEach { it.dispose() }
        textures.clear()
        if (::pixelFont.isInitialized) pixelFont.dispose()
    }
}
