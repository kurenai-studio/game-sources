package com.micro1.tilemap;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.PixmapIO;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.maps.tiled.TiledMapTileLayer;
import com.badlogic.gdx.maps.tiled.TmxMapLoader;
import com.badlogic.gdx.maps.tiled.renderers.OrthogonalTiledMapRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.ScreenUtils;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.badlogic.gdx.utils.viewport.Viewport;

/**
 * The single game screen: loads map.tmx, renders the background layer, the player (WASD-driven, tile
 * collision, 90-degree facing), then the foreground layer, with an OrthographicCamera that follows the
 * player and is clamped to the map bounds so scrolling never reveals past the edge.
 *
 * A capture mode (-Dcapture=DIR) renders a fixed set of scenes (the four facings, a scrolled view, and
 * a map-corner view) to PNGs for offline visual QA, then exits.
 */
public class GameScreen extends ScreenAdapter {

    // world model: 1 world unit = 1 pixel; tiles are 16px; map is 128x128 tiles = 2048x2048 px.
    private static final int TILE = 16;
    private static final int MAP_TILES = 128;
    private static final float MAP_PX = MAP_TILES * TILE; // 2048
    private static final float VIEW_W = 400f;             // 2x zoom on the 800x480 window (both 5:3)
    private static final float VIEW_H = 240f;
    private static final float DRAW_W = 32f;              // player draw size in world px (~2 tiles)
    private static final float DRAW_H = 27f;              // keeps the 258:220 frame aspect
    private static final float SPAWN_X = 64 * TILE + TILE / 2f; // 1032
    private static final float SPAWN_Y = 64 * TILE + TILE / 2f; // 1032

    private OrthographicCamera camera;
    private Viewport viewport;
    private TiledMap map;
    private OrthogonalTiledMapRenderer renderer;
    private SpriteBatch batch;
    private Texture playerSheet;
    private Animation<TextureRegion> anim;
    private Player player;
    private TileCollision collision;
    private int[] bgLayers;
    private int[] fgLayers;

    // capture mode
    private String captureDir;
    private float[][] scenes;
    private int sceneIdx = 0;

    /** Clamp a camera axis so the half-viewport never shows past the [0, mapPx] map edge. */
    public static float clampCam(float centre, float halfView, float mapPx) {
        return MathUtils.clamp(centre, halfView, mapPx - halfView);
    }

    @Override
    public void show() {
        camera = new OrthographicCamera();
        viewport = new FitViewport(VIEW_W, VIEW_H, camera);
        viewport.update(Gdx.graphics.getWidth(), Gdx.graphics.getHeight(), false);

        // Nearest filtering on the tileset keeps 16px tiles crisp with no bleeding at tile seams.
        TmxMapLoader.Parameters params = new TmxMapLoader.Parameters();
        params.textureMinFilter = Texture.TextureFilter.Nearest;
        params.textureMagFilter = Texture.TextureFilter.Nearest;
        map = new TmxMapLoader().load("map.tmx", params);

        batch = new SpriteBatch();
        renderer = new OrthogonalTiledMapRenderer(map, 1f, batch);

        bgLayers = new int[]{map.getLayers().getIndex("background")};
        fgLayers = new int[]{map.getLayers().getIndex("foreground")};
        TiledMapTileLayer collisionLayer = (TiledMapTileLayer) map.getLayers().get("collision");
        collision = new TileCollision(collisionLayer, TILE);

        playerSheet = new Texture(Gdx.files.internal("player_move_spritesheet.png"));
        playerSheet.setFilter(Texture.TextureFilter.Linear, Texture.TextureFilter.Linear);
        anim = buildAnimation(playerSheet);

        player = new Player(SPAWN_X, SPAWN_Y);

        captureDir = System.getProperty("capture");
        if (captureDir != null) {
            setupCaptureScenes(collisionLayer);
        }
        logSummary(collisionLayer);
    }

    /** Split the 4x4 sheet and keep the 15 populated frames (the last cell is empty), 0.033s each. */
    private Animation<TextureRegion> buildAnimation(Texture sheet) {
        int fw = sheet.getWidth() / 4;   // 258
        int fh = sheet.getHeight() / 4;  // 220
        TextureRegion[][] grid = TextureRegion.split(sheet, fw, fh);
        TextureRegion[] frames = new TextureRegion[15];
        int i = 0;
        for (int r = 0; r < 4; r++) {
            for (int c = 0; c < 4; c++) {
                if (r == 3 && c == 3) {
                    continue; // the 16th cell is empty
                }
                frames[i++] = grid[r][c];
            }
        }
        Animation<TextureRegion> a = new Animation<TextureRegion>(0.033f, frames);
        a.setPlayMode(Animation.PlayMode.LOOP);
        return a;
    }

    @Override
    public void render(float delta) {
        if (captureDir != null) {
            float[] s = scenes[sceneIdx];
            player.pos.set(s[0], s[1]);
            player.angleDeg = s[2];
            player.stateTime = s[3];
        } else {
            handleInput(delta);
        }

        camera.position.set(
            clampCam(player.pos.x, VIEW_W / 2f, MAP_PX),
            clampCam(player.pos.y, VIEW_H / 2f, MAP_PX),
            0f);
        camera.update();

        ScreenUtils.clear(0f, 0f, 0f, 1f);
        renderer.setView(camera);
        renderer.render(bgLayers);

        batch.setProjectionMatrix(camera.combined);
        batch.begin();
        TextureRegion frame = anim.getKeyFrame(player.stateTime);
        batch.draw(frame,
            player.pos.x - DRAW_W / 2f, player.pos.y - DRAW_H / 2f,
            DRAW_W / 2f, DRAW_H / 2f,
            DRAW_W, DRAW_H,
            1f, 1f,
            player.angleDeg);
        batch.end();

        renderer.render(fgLayers);

        if (captureDir != null) {
            captureFrame();
            sceneIdx++;
            if (sceneIdx >= scenes.length) {
                Gdx.app.exit();
            }
        }
    }

    private void handleInput(float delta) {
        boolean up = Gdx.input.isKeyPressed(Input.Keys.W);
        boolean down = Gdx.input.isKeyPressed(Input.Keys.S);
        boolean left = Gdx.input.isKeyPressed(Input.Keys.A);
        boolean right = Gdx.input.isKeyPressed(Input.Keys.D);
        if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) {
            Gdx.app.exit();
        }
        // Clamp the frame delta so a stall (e.g. a lag spike or a paused/dragged window) cannot move
        // the player far enough in one step to tunnel through a wall.
        player.move(up, down, left, right, Math.min(delta, 0.05f), collision);
    }

    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, false);
    }

    @Override
    public void dispose() {
        if (renderer != null) {
            renderer.dispose();
        }
        if (map != null) {
            map.dispose();
        }
        if (batch != null) {
            batch.dispose();
        }
        if (playerSheet != null) {
            playerSheet.dispose();
        }
    }

    // --- capture / QA helpers -------------------------------------------------------------------

    private void setupCaptureScenes(TiledMapTileLayer col) {
        float[] corner = nearestOpen(col, 6, 6);
        float[] far = nearestOpen(col, 100, 100);
        scenes = new float[][]{
            {SPAWN_X, SPAWN_Y, 0f, 0f},        // facing East
            {SPAWN_X, SPAWN_Y, 90f, 0.099f},   // facing North
            {SPAWN_X, SPAWN_Y, 180f, 0.198f},  // facing West
            {SPAWN_X, SPAWN_Y, 270f, 0.297f},  // facing South
            {SPAWN_X + 260f, SPAWN_Y, 0f, 0.05f}, // scrolled East (camera moved, new tiles)
            {corner[0], corner[1], 0f, 0f},    // map corner (clamped camera, border wall visible)
            {far[0], far[1], 0f, 0f},          // far interior (scroll revealed a new region)
        };
    }

    /** Spiral out from (tx,ty) for the nearest open (null) collision cell; return its world centre. */
    private float[] nearestOpen(TiledMapTileLayer col, int tx, int ty) {
        for (int r = 0; r < MAP_TILES; r++) {
            for (int dx = -r; dx <= r; dx++) {
                for (int dy = -r; dy <= r; dy++) {
                    if (Math.max(Math.abs(dx), Math.abs(dy)) != r) {
                        continue;
                    }
                    int x = tx + dx;
                    int y = ty + dy;
                    if (x >= 0 && y >= 0 && x < MAP_TILES && y < MAP_TILES && col.getCell(x, y) == null) {
                        return new float[]{x * TILE + TILE / 2f, y * TILE + TILE / 2f};
                    }
                }
            }
        }
        return new float[]{SPAWN_X, SPAWN_Y};
    }

    private void captureFrame() {
        int w = Gdx.graphics.getBackBufferWidth();
        int h = Gdx.graphics.getBackBufferHeight();
        Pixmap pm = Pixmap.createFromFrameBuffer(0, 0, w, h);
        PixmapIO.writePNG(Gdx.files.absolute(captureDir + "/tm_scene_" + sceneIdx + ".png"), pm);
        pm.dispose();
        System.out.println("captured scene " + sceneIdx);
    }

    private void logSummary(TiledMapTileLayer col) {
        int solid = 0;
        for (int y = 0; y < col.getHeight(); y++) {
            for (int x = 0; x < col.getWidth(); x++) {
                if (col.getCell(x, y) != null) {
                    solid++;
                }
            }
        }
        System.out.println("[TiledMap] layers=" + map.getLayers().getCount()
            + " names=[background=" + map.getLayers().getIndex("background")
            + ",collision=" + map.getLayers().getIndex("collision")
            + ",foreground=" + map.getLayers().getIndex("foreground") + "]"
            + " map=" + MAP_TILES + "x" + MAP_TILES + "@" + TILE + " (" + (int) MAP_PX + "px)"
            + " collisionSolids=" + solid
            + " spawnOpen=" + (col.getCell(64, 64) == null)
            + " animFrames=" + anim.getKeyFrames().length);
    }
}
