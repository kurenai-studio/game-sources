package com.otalona.neondash;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.PerspectiveCamera;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.Texture.TextureFilter;
import com.badlogic.gdx.graphics.VertexAttributes;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g3d.Environment;
import com.badlogic.gdx.graphics.g3d.Material;
import com.badlogic.gdx.graphics.g3d.Model;
import com.badlogic.gdx.graphics.g3d.ModelBatch;
import com.badlogic.gdx.graphics.g3d.ModelInstance;
import com.badlogic.gdx.graphics.g3d.attributes.ColorAttribute;
import com.badlogic.gdx.graphics.g3d.environment.DirectionalLight;
import com.badlogic.gdx.graphics.g3d.utils.ModelBuilder;
import com.badlogic.gdx.graphics.g3d.loader.ObjLoader;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ScreenUtils;
import java.util.Iterator;
import java.util.Random;

/** Neon Dash 3D: a touch-controlled endless runner built with libGDX. */
public class NeonDashGame extends ApplicationAdapter {
    private static final float[] LANES = {-2.1f, 0f, 2.1f};
    private static final Color[] SKIN_COLORS = {
        new Color(0.12f, 0.95f, 0.8f, 1f), new Color(0.72f, 0.48f, 1f, 1f),
        new Color(1f, 0.35f, 0.58f, 1f), new Color(1f, 0.72f, 0.2f, 1f)
    };
    private static final int COIN = 0, SHIELD = 1, MAGNET = 2, DOUBLE_SCORE = 3;
    private static final String[] DISTRICTS = {
        "METRO NEON", "VALE CRISTAL", "PORTO CIBERNETICO", "CIDADE AURORA"
    };
    private static final Color[] SKY = {
        new Color(0.018f, 0.035f, 0.085f, 1f), new Color(0.06f, 0.025f, 0.12f, 1f),
        new Color(0.015f, 0.075f, 0.095f, 1f), new Color(0.10f, 0.035f, 0.10f, 1f)
    };
    private static final Color[] NEON = {
        new Color(0.08f, 0.88f, 0.82f, 1f), new Color(0.68f, 0.35f, 1f, 1f),
        new Color(0.15f, 0.92f, 0.72f, 1f), new Color(1f, 0.38f, 0.70f, 1f)
    };

    private enum State { MENU, PLAYING, PAUSED, GAME_OVER, GARAGE }
    private final Random random = new Random();
    private final Array<Obstacle> obstacles = new Array<>();
    private final Array<Pickup> pickups = new Array<>();
    private final Array<ModelInstance> laneMarks = new Array<>();
    private final Array<Building> buildings = new Array<>();

    private PerspectiveCamera camera;
    private ModelBatch modelBatch;
    private Environment environment;
    private SpriteBatch uiBatch;
    private BitmapFont font;
    private Texture pixel, skylineTexture;
    private Model roadModel, markModel, railModel, playerModel, cockpitModel, wingModel, noseModel, engineModel, lampModel;
    private Model lowObstacleModel, tallObstacleModel, coinModel, shieldModel, magnetModel, doubleModel;
    private Model buildingModel, buildingLightModel;
    private Model importedShipModel;
    private ModelInstance road, leftRail, rightRail, player, cockpit, leftWing, rightWing, nose;
    private ModelInstance leftEngine, rightEngine, leftLamp, rightLamp;
    private ModelInstance importedShip;
    private final Vector3 shipCenter = new Vector3();
    private float shipScale = 1f;
    private State state = State.MENU;
    private float playerX, playerY, jumpTimer, spawnTimer, elapsed, speed = 11.5f;
    private float shieldTimer, magnetTimer, doubleTimer, hitFlash, worldScroll;
    private int lane = 1, score, best, runCoins, totalCoins, selectedSkin, zone;
    private boolean[] unlockedSkins = {true, false, false, false};
    private int touchStartX, touchStartY;

    @Override public void create() {
        modelBatch = new ModelBatch();
        uiBatch = new SpriteBatch();
        font = new BitmapFont();
        font.getData().setScale(1.12f);
        Pixmap pixmap = new Pixmap(1, 1, Pixmap.Format.RGBA8888);
        pixmap.setColor(Color.WHITE);
        pixmap.fill();
        pixel = new Texture(pixmap);
        pixmap.dispose();
        skylineTexture = new Texture(Gdx.files.internal("background/neon-city.jpg"));
        skylineTexture.setFilter(TextureFilter.Linear, TextureFilter.Linear);

        camera = new PerspectiveCamera(66f, Gdx.graphics.getWidth(), Gdx.graphics.getHeight());
        camera.position.set(0f, 7.0f, 11.5f);
        camera.lookAt(0f, 0.6f, -9f);
        camera.near = 0.1f;
        camera.far = 100f;
        camera.update();

        environment = new Environment();
        environment.set(new ColorAttribute(ColorAttribute.AmbientLight, 0.72f, 0.78f, 0.95f, 1f));
        environment.add(new DirectionalLight().set(0.92f, 0.94f, 1f, -0.45f, -1f, -0.3f));
        buildWorld();
        loadImportedShip();
        loadProgress();
        tintImportedShip();
        installInput();
        updatePlayer(0f);
    }

    private void buildWorld() {
        ModelBuilder b = new ModelBuilder();
        long attrs = VertexAttributes.Usage.Position | VertexAttributes.Usage.Normal;
        roadModel = b.createBox(9.2f, 0.35f, 72f, mat(new Color(0.045f, 0.065f, 0.13f, 1f)), attrs);
        markModel = b.createBox(0.07f, 0.04f, 1.25f, mat(new Color(0.18f, 0.28f, 0.42f, 1f)), attrs);
        railModel = b.createBox(0.13f, 0.18f, 72f, mat(NEON[0]), attrs);
        playerModel = b.createSphere(0.90f, 0.30f, 1.42f, 24, 16, mat(SKIN_COLORS[0]), attrs);
        cockpitModel = b.createSphere(0.43f, 0.30f, 0.70f, 20, 14, mat(new Color(0.08f, 0.22f, 0.48f, 1f)), attrs);
        noseModel = b.createCone(0.88f, 0.40f, 0.88f, 16, mat(SKIN_COLORS[0]), attrs);
        wingModel = b.createBox(0.74f, 0.085f, 0.62f, mat(new Color(0.24f, 0.91f, 1f, 1f)), attrs);
        engineModel = b.createCylinder(0.30f, 0.58f, 0.30f, 16, mat(new Color(0.12f, 0.22f, 0.42f, 1f)), attrs);
        lampModel = b.createBox(0.22f, 0.075f, 0.12f, mat(new Color(0.50f, 1f, 0.96f, 1f)), attrs);
        lowObstacleModel = b.createBox(1.35f, 0.82f, 0.95f, mat(new Color(1f, 0.22f, 0.48f, 1f)), attrs);
        tallObstacleModel = b.createBox(1.2f, 2.8f, 0.9f, mat(new Color(0.98f, 0.24f, 0.38f, 1f)), attrs);
        coinModel = b.createCylinder(0.64f, 0.16f, 0.64f, 18, mat(new Color(1f, 0.77f, 0.18f, 1f)), attrs);
        shieldModel = b.createSphere(0.78f, 0.78f, 0.78f, 16, 12, mat(new Color(0.15f, 0.72f, 1f, 1f)), attrs);
        magnetModel = b.createSphere(0.78f, 0.78f, 0.78f, 16, 12, mat(new Color(1f, 0.25f, 0.68f, 1f)), attrs);
        doubleModel = b.createSphere(0.78f, 0.78f, 0.78f, 16, 12, mat(new Color(0.55f, 1f, 0.38f, 1f)), attrs);
        buildingModel = b.createBox(1f, 1f, 1f, mat(new Color(0.10f, 0.14f, 0.3f, 1f)), attrs);
        buildingLightModel = b.createBox(0.1f, 1f, 0.06f, mat(new Color(0.12f, 0.8f, 1f, 1f)), attrs);

        road = new ModelInstance(roadModel); road.transform.setToTranslation(0f, -0.28f, -17f);
        leftRail = new ModelInstance(railModel); leftRail.transform.setToTranslation(-4.45f, -0.02f, -17f);
        rightRail = new ModelInstance(railModel); rightRail.transform.setToTranslation(4.45f, -0.02f, -17f);
        player = new ModelInstance(playerModel);
        cockpit = new ModelInstance(cockpitModel);
        nose = new ModelInstance(noseModel);
        leftWing = new ModelInstance(wingModel);
        rightWing = new ModelInstance(wingModel);
        leftEngine = new ModelInstance(engineModel);
        rightEngine = new ModelInstance(engineModel);
        leftLamp = new ModelInstance(lampModel);
        rightLamp = new ModelInstance(lampModel);

        for (int i = 0; i < 36; i++) {
            for (float x : new float[]{-1.05f, 1.05f}) {
                ModelInstance mark = new ModelInstance(markModel);
                mark.transform.setToTranslation(x, -0.08f, 9f - i * 2.0f);
                laneMarks.add(mark);
            }
        }
        for (int i = 0; i < 18; i++) {
            addBuilding(-1, -72f + i * 4.7f);
            addBuilding(1, -69.5f + i * 4.7f);
        }
    }

    private Material mat(Color c) { return new Material(ColorAttribute.createDiffuse(new Color(c))); }

    private void loadImportedShip() {
        try {
            importedShipModel = new ObjLoader().loadModel(Gdx.files.internal("models/quaternius/spaceships/OBJ/Spaceship3.obj"));
            com.badlogic.gdx.math.collision.BoundingBox bounds = new com.badlogic.gdx.math.collision.BoundingBox();
            importedShipModel.calculateBoundingBox(bounds);
            Vector3 size = bounds.getDimensions(new Vector3());
            bounds.getCenter(shipCenter);
            shipScale = 1.72f / Math.max(size.x, Math.max(size.y, size.z));
            importedShip = new ModelInstance(importedShipModel);
            tintImportedShip();
        } catch (RuntimeException error) {
            Gdx.app.error("NeonDash", "Optional ship model could not be loaded; using the built-in ship", error);
            if (importedShipModel != null) { importedShipModel.dispose(); importedShipModel = null; }
            importedShip = null;
        }
    }

    private void tintImportedShip() {
        if (importedShipModel == null) return;
        Color base = SKIN_COLORS[selectedSkin];
        for (Material material : importedShipModel.materials) {
            ColorAttribute diffuse = (ColorAttribute) material.get(ColorAttribute.Diffuse);
            if (diffuse != null) diffuse.color.set(base);
        }
    }

    private void addBuilding(int side, float z) {
        float width = 1.4f + random.nextFloat() * 2.4f;
        float height = 6f + random.nextFloat() * 17f;
        float depth = 2.2f + random.nextFloat() * 3.8f;
        float x = side * (6.2f + random.nextFloat() * 5f);
        ModelInstance body = new ModelInstance(buildingModel);
        body.transform.setToScaling(width, height, depth).setTranslation(x, height * 0.5f - 0.12f, z);
        ModelInstance light = new ModelInstance(buildingLightModel);
        light.transform.setToScaling(1f, height * (0.34f + random.nextFloat() * 0.4f), 1f)
            .setTranslation(x - side * width * 0.25f, height * 0.5f, z + depth * 0.51f);
        buildings.add(new Building(side, body, light, width, height, depth, x));
    }

    private void installInput() {
        Gdx.input.setInputProcessor(new InputAdapter() {
            @Override public boolean keyDown(int keycode) {
                if (keycode == Input.Keys.ESCAPE || keycode == Input.Keys.BACK) {
                    if (state == State.PLAYING) state = State.PAUSED;
                    else if (state == State.PAUSED || state == State.GARAGE) state = State.MENU;
                    else state = State.MENU;
                    return true;
                }
                if (state == State.PLAYING) {
                    if (keycode == Input.Keys.LEFT || keycode == Input.Keys.A) moveLane(-1);
                    if (keycode == Input.Keys.RIGHT || keycode == Input.Keys.D) moveLane(1);
                    if (keycode == Input.Keys.UP || keycode == Input.Keys.SPACE || keycode == Input.Keys.W) jump();
                }
                return true;
            }
            @Override public boolean touchDown(int x, int y, int pointer, int button) {
                touchStartX = x; touchStartY = y; return true;
            }
            @Override public boolean touchUp(int x, int y, int pointer, int button) {
                handleTouch(x, y); return true;
            }
        });
    }

    private void handleTouch(int x, int screenY) {
        float w = Gdx.graphics.getWidth(), h = Gdx.graphics.getHeight();
        float y = h - screenY;
        if (state == State.MENU) {
            if (inside(x, y, w * 0.2f, h * 0.31f, w * 0.6f, h * 0.105f)) startRun();
            else if (inside(x, y, w * 0.2f, h * 0.17f, w * 0.6f, h * 0.09f)) state = State.GARAGE;
            return;
        }
        if (state == State.GARAGE) {
            if (inside(x, y, w * 0.18f, h * 0.075f, w * 0.64f, h * 0.075f)) {
                state = State.MENU;
            } else {
                for (int i = 0; i < 4; i++) {
                    float cy = h * 0.66f - i * h * 0.112f;
                    float cardHeight = Math.min(h * 0.065f, 70f * uiScale(w));
                    if (inside(x, y, w * 0.10f, cy - cardHeight * 0.5f, w * 0.80f, cardHeight)) {
                        selectSkin(i);
                        break;
                    }
                }
            }
            return;
        }
        if (state == State.PAUSED) {
            if (inside(x, y, w * 0.16f, h * 0.34f, w * 0.68f, h * 0.12f)) state = State.PLAYING;
            else if (inside(x, y, w * 0.16f, h * 0.19f, w * 0.68f, h * 0.11f)) startRun();
            return;
        }
        if (state == State.GAME_OVER) {
            if (inside(x, y, w * 0.16f, h * 0.22f, w * 0.68f, h * 0.12f)) startRun();
            else if (inside(x, y, w * 0.16f, h * 0.075f, w * 0.68f, h * 0.10f)) state = State.MENU;
            return;
        }
        if (state == State.PLAYING) {
            if (inside(x, y, w - 96f, h - 82f, 80f, 64f)) { state = State.PAUSED; return; }
            int dx = x - touchStartX, dy = screenY - touchStartY;
            if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > 34) moveLane(dx < 0 ? -1 : 1);
            else if (dy < -25 || (Math.abs(dx) < 30 && Math.abs(dy) < 30)) jump();
        }
    }

    private boolean inside(float x, float y, float bx, float by, float bw, float bh) {
        return x >= bx && x <= bx + bw && y >= by && y <= by + bh;
    }

    private void loadProgress() {
        com.badlogic.gdx.Preferences p = Gdx.app.getPreferences("neon-dash");
        best = p.getInteger("best", 0);
        totalCoins = p.getInteger("coins", 0);
        selectedSkin = p.getInteger("skin", 0);
        for (int i = 0; i < unlockedSkins.length; i++) unlockedSkins[i] = p.getBoolean("skin_" + i, i == 0);
        if (selectedSkin < 0 || selectedSkin >= SKIN_COLORS.length || !unlockedSkins[selectedSkin]) selectedSkin = 0;
    }

    private void selectSkin(int index) {
        int[] prices = {0, 60, 120, 200};
        com.badlogic.gdx.Preferences p = Gdx.app.getPreferences("neon-dash");
        if (!unlockedSkins[index]) {
            if (totalCoins < prices[index]) return;
            totalCoins -= prices[index];
            unlockedSkins[index] = true;
            p.putInteger("coins", totalCoins).putBoolean("skin_" + index, true).flush();
        }
        selectedSkin = index;
        p.putInteger("skin", selectedSkin).flush();
        playerModel.materials.first().set(ColorAttribute.createDiffuse(new Color(SKIN_COLORS[selectedSkin])));
        noseModel.materials.first().set(ColorAttribute.createDiffuse(new Color(SKIN_COLORS[selectedSkin])));
        tintImportedShip();
    }

    private void startRun() {
        obstacles.clear(); pickups.clear();
        lane = 1; playerX = 0f; playerY = 0f; jumpTimer = 0f;
        spawnTimer = 0.7f; elapsed = 0f; score = 0; runCoins = 0; speed = 11.5f;
        shieldTimer = magnetTimer = doubleTimer = hitFlash = 0f;
        zone = 0; state = State.PLAYING;
        playerModel.materials.first().set(ColorAttribute.createDiffuse(new Color(SKIN_COLORS[selectedSkin])));
        noseModel.materials.first().set(ColorAttribute.createDiffuse(new Color(SKIN_COLORS[selectedSkin])));
    }

    private void moveLane(int direction) { lane = MathUtils.clamp(lane + direction, 0, 2); }
    private void jump() { if (jumpTimer <= 0.01f) jumpTimer = 0.68f; }

    @Override public void render() {
        float delta = Math.min(Gdx.graphics.getDeltaTime(), 0.05f);
        if (state == State.PLAYING) updateGame(delta);
        else updateScenery(delta * 0.22f);
        updatePlayer(delta);
        ScreenUtils.clear(SKY[zone], true);
        drawBackdrop();
        Gdx.gl.glClear(GL20.GL_DEPTH_BUFFER_BIT);
        Gdx.gl.glEnable(GL20.GL_DEPTH_TEST);
        camera.viewportWidth = Gdx.graphics.getWidth(); camera.viewportHeight = Gdx.graphics.getHeight(); camera.update();

        modelBatch.begin(camera);
        modelBatch.render(road, environment);
        modelBatch.render(leftRail, environment); modelBatch.render(rightRail, environment);
        for (ModelInstance mark : laneMarks) modelBatch.render(mark, environment);
        for (Building building : buildings) { modelBatch.render(building.body, environment); modelBatch.render(building.light, environment); }
        if (importedShip != null) modelBatch.render(importedShip, environment);
        else {
            modelBatch.render(player, environment); modelBatch.render(nose, environment); modelBatch.render(cockpit, environment);
            modelBatch.render(leftWing, environment); modelBatch.render(rightWing, environment);
            modelBatch.render(leftEngine, environment); modelBatch.render(rightEngine, environment);
            modelBatch.render(leftLamp, environment); modelBatch.render(rightLamp, environment);
        }
        for (Obstacle obstacle : obstacles) modelBatch.render(obstacle.body, environment);
        for (Pickup pickup : pickups) modelBatch.render(pickup.model, environment);
        modelBatch.end();
        drawInterface();
    }

    private void updateGame(float delta) {
        elapsed += delta;
        zone = ((int)(elapsed / 24f)) % DISTRICTS.length;
        railModel.materials.first().set(ColorAttribute.createDiffuse(new Color(NEON[zone])));
        speed = Math.min(23f, 11.5f + elapsed * 0.11f + zone * 0.55f);
        score = (int)(elapsed * (doubleTimer > 0 ? 20f : 10f));
        shieldTimer = Math.max(0f, shieldTimer - delta);
        magnetTimer = Math.max(0f, magnetTimer - delta);
        doubleTimer = Math.max(0f, doubleTimer - delta);
        hitFlash = Math.max(0f, hitFlash - delta);
        updateScenery(delta * speed);

        spawnTimer -= delta;
        if (spawnTimer <= 0f) spawnWave();
        moveObstacles(delta);
        movePickups(delta);
    }

    private void updateScenery(float amount) {
        worldScroll += amount;
        for (ModelInstance mark : laneMarks) {
            float z = mark.transform.getTranslation(new Vector3()).z + amount;
            if (z > 12f) z -= 72f;
            mark.transform.setToTranslation(mark.transform.getTranslation(new Vector3()).x, -0.08f, z);
        }
        for (Building b : buildings) {
            float z = b.body.transform.getTranslation(new Vector3()).z + amount;
            if (z > 17f) {
                z -= 84.6f;
                relocateBuilding(b, z);
            } else {
                b.body.transform.setToScaling(b.width, b.height, b.depth).setTranslation(b.x, b.height * 0.5f - 0.12f, z);
                b.light.transform.setToScaling(1f, b.height * 0.42f, 1f)
                    .setTranslation(b.x - b.side * b.width * 0.25f, b.height * 0.5f, z + b.depth * 0.51f);
            }
        }
    }

    private void relocateBuilding(Building b, float z) {
        b.width = 1.4f + random.nextFloat() * 2.4f;
        b.height = 6f + random.nextFloat() * 17f;
        b.depth = 2.2f + random.nextFloat() * 3.8f;
        b.x = b.side * (6.2f + random.nextFloat() * 5f);
        int colorIndex = random.nextInt(4);
        buildingModel.materials.first().set(ColorAttribute.createDiffuse(new Color(
            0.075f + colorIndex * 0.014f, 0.10f + colorIndex * 0.018f, 0.22f + colorIndex * 0.045f, 1f)));
        b.body.transform.setToScaling(b.width, b.height, b.depth).setTranslation(b.x, b.height * 0.5f - 0.12f, z);
        b.light.transform.setToScaling(1f, b.height * (0.34f + random.nextFloat() * 0.4f), 1f)
            .setTranslation(b.x - b.side * b.width * 0.25f, b.height * 0.5f, z + b.depth * 0.51f);
    }

    private void spawnWave() {
        int blocked = random.nextInt(3);
        boolean tall = random.nextFloat() < 0.38f;
        ModelInstance body = new ModelInstance(tall ? tallObstacleModel : lowObstacleModel);
        body.transform.setToTranslation(LANES[blocked], tall ? 1.38f : 0.42f, -34f);
        obstacles.add(new Obstacle(blocked, body, !tall));
        int safeLane = (blocked + 1 + random.nextInt(2)) % 3;
        for (int i = 0; i < 4; i++) addPickup(COIN, safeLane, -27f - i * 2.4f);
        if (random.nextFloat() < 0.17f) {
            int kind = random.nextInt(3) + 1;
            addPickup(kind, safeLane, -38f);
        }
        spawnTimer = Math.max(0.78f, 1.2f - elapsed * 0.0025f) + random.nextFloat() * 0.32f;
    }

    private void addPickup(int kind, int laneIndex, float z) {
        Model model = kind == COIN ? coinModel : kind == SHIELD ? shieldModel : kind == MAGNET ? magnetModel : doubleModel;
        ModelInstance instance = new ModelInstance(model);
        instance.transform.setToTranslation(LANES[laneIndex], kind == COIN ? 0.95f : 1.25f, z);
        if (kind == COIN) instance.transform.rotate(Vector3.X, 90f);
        pickups.add(new Pickup(kind, laneIndex, instance));
    }

    private void moveObstacles(float delta) {
        Iterator<Obstacle> it = obstacles.iterator();
        while (it.hasNext()) {
            Obstacle o = it.next();
            Vector3 p = o.body.transform.getTranslation(new Vector3());
            p.z += speed * delta;
            o.body.transform.setTranslation(LANES[o.lane], o.jumpable ? 0.42f : 1.38f, p.z);
            if (p.z > 3.5f) it.remove();
            else if (Math.abs(p.z - 1.1f) < 0.78f && o.lane == lane && !(o.jumpable && playerY > 0.88f)) {
                if (shieldTimer > 0f) { shieldTimer = 0f; hitFlash = 0.45f; it.remove(); }
                else { finishRun(); return; }
            }
        }
    }

    private void movePickups(float delta) {
        Iterator<Pickup> it = pickups.iterator();
        while (it.hasNext()) {
            Pickup p = it.next();
            Vector3 pos = p.model.transform.getTranslation(new Vector3());
            pos.z += speed * delta;
            if (p.kind == COIN && magnetTimer > 0f && pos.z > -9f && Math.abs(p.lane - lane) <= 1) {
                pos.x = MathUtils.lerp(pos.x, playerX, delta * 5f);
            }
            p.model.transform.setToTranslation(pos.x, p.kind == COIN ? 0.95f : 1.25f, pos.z);
            if (p.kind == COIN) p.model.transform.rotate(Vector3.X, 90f).rotate(Vector3.Y, 220f * delta);
            else p.model.transform.rotate(Vector3.Y, 100f * delta);
            float reach = magnetTimer > 0f && p.kind == COIN ? 1.65f : 0.85f;
            boolean near = Math.abs(pos.z - 1.1f) < reach && Math.abs(pos.x - playerX) < 0.85f;
            if (near && (p.kind == COIN || Math.abs(pos.x - playerX) < 1f)) {
                collect(p.kind); it.remove();
            } else if (pos.z > 5f) it.remove();
        }
    }

    private void collect(int kind) {
        if (kind == COIN) { runCoins++; score += 25; }
        if (kind == SHIELD) shieldTimer = 8f;
        if (kind == MAGNET) magnetTimer = 10f;
        if (kind == DOUBLE_SCORE) doubleTimer = 10f;
        hitFlash = 0.12f;
    }

    private void finishRun() {
        state = State.GAME_OVER;
        totalCoins += runCoins;
        best = Math.max(best, score);
        com.badlogic.gdx.Preferences p = Gdx.app.getPreferences("neon-dash");
        p.putInteger("best", best).putInteger("coins", totalCoins).putInteger("skin", selectedSkin).flush();
    }

    private void updatePlayer(float delta) {
        playerX = MathUtils.lerp(playerX, LANES[lane], Math.min(1f, delta * 12f));
        if (jumpTimer > 0f) {
            jumpTimer = Math.max(0f, jumpTimer - delta);
            playerY = (float)Math.sin((0.68f - jumpTimer) / 0.68f * Math.PI) * 1.62f;
        } else playerY = 0f;
        float bob = state == State.PLAYING ? (float)Math.sin(elapsed * 9f) * 0.035f : 0f;
        float y = 0.42f + playerY + bob;
        if (importedShip != null) {
            importedShip.transform.setToScaling(shipScale, shipScale, shipScale)
                .translate(-shipCenter.x, -shipCenter.y, -shipCenter.z)
                .translate(playerX, y + 0.08f, 1.1f);
        }
        player.transform.setToTranslation(playerX, y, 1.1f);
        nose.transform.setToRotation(Vector3.X, -90f).setTranslation(playerX, y + 0.03f, 0.38f);
        cockpit.transform.setToTranslation(playerX, y + 0.25f, 1.08f);
        leftWing.transform.setToTranslation(playerX - 0.72f, y - 0.035f, 1.20f);
        rightWing.transform.setToTranslation(playerX + 0.72f, y - 0.035f, 1.20f);
        leftEngine.transform.setToRotation(Vector3.X, 90f).setTranslation(playerX - 0.48f, y - 0.02f, 1.32f);
        rightEngine.transform.setToRotation(Vector3.X, 90f).setTranslation(playerX + 0.48f, y - 0.02f, 1.32f);
        leftLamp.transform.setToTranslation(playerX - 0.28f, y + 0.14f, 0.17f);
        rightLamp.transform.setToTranslation(playerX + 0.28f, y + 0.14f, 0.17f);
    }

    private void drawBackdrop() {
        float w = Gdx.graphics.getWidth(), h = Gdx.graphics.getHeight();
        float screenAspect = w / h;
        float imageAspect = (float)skylineTexture.getWidth() / skylineTexture.getHeight();
        float crop = Math.max(0f, (1f - screenAspect / imageAspect) * 0.5f);
        Color tint = zone == 1 ? new Color(0.82f, 0.78f, 1f, 1f)
            : zone == 2 ? new Color(0.75f, 1f, 0.9f, 1f)
            : zone == 3 ? new Color(1f, 0.76f, 0.9f, 1f) : Color.WHITE;
        Gdx.gl.glDisable(GL20.GL_DEPTH_TEST);
        uiBatch.begin();
        uiBatch.setColor(tint);
        uiBatch.draw(skylineTexture, 0, 0, w, h, crop, 0, 1f - crop, 1f);
        uiBatch.setColor(Color.WHITE);
        uiBatch.end();
    }

    private void drawInterface() {
        float w = Gdx.graphics.getWidth(), h = Gdx.graphics.getHeight();
        Gdx.gl.glDisable(GL20.GL_DEPTH_TEST);
        uiBatch.begin();
        if (state == State.PLAYING) {
            drawRect(18, h - 82, 184, 64, new Color(0.02f, 0.04f, 0.1f, 0.72f));
            drawText("PONTOS  " + score, 32, h - 40, Color.WHITE, 1.1f);
            drawText("MOEDAS  " + runCoins, 32, h - 65, new Color(1f, 0.8f, 0.25f, 1f), 0.9f);
            drawRect(w - 82, h - 72, 64, 54, new Color(0.04f, 0.08f, 0.16f, 0.85f));
            drawText("II", w - 63, h - 36, Color.WHITE, 1.1f);
            drawText(DISTRICTS[zone], 20, 38, new Color(0.62f, 0.83f, 1f, 1f), 0.82f);
            if (shieldTimer > 0) drawText("ESCUDO " + (int)shieldTimer + "s", 20, 64, new Color(0.3f, 0.85f, 1f, 1f), 0.82f);
            if (magnetTimer > 0) drawText("IMA " + (int)magnetTimer + "s", 20, 88, new Color(1f, 0.45f, 0.8f, 1f), 0.82f);
            if (doubleTimer > 0) drawText("2X PONTOS", 20, 112, new Color(0.65f, 1f, 0.45f, 1f), 0.82f);
        } else if (state == State.MENU) {
            drawRect(w * 0.07f, h * 0.56f, w * 0.86f, h * 0.32f, new Color(0.015f, 0.025f, 0.08f, 0.76f));
            drawText("NEON", w * 0.29f, h * 0.81f, new Color(0.22f, 1f, 0.86f, 1f), 2.2f);
            drawText("DASH 3D", w * 0.29f, h * 0.74f, Color.WHITE, 1.6f);
            drawText("4 DISTRITOS  •  PODERES  •  GARAGEM", w * 0.13f, h * 0.64f, new Color(0.72f, 0.84f, 1f, 1f), 0.78f);
            drawButton("JOGAR", w * 0.2f, h * 0.31f, w * 0.6f, h * 0.105f, NEON[zone]);
            drawButton("GARAGEM  •  " + totalCoins + " MOEDAS", w * 0.2f, h * 0.17f, w * 0.6f, h * 0.09f, new Color(0.48f, 0.28f, 0.85f, 1f));
            drawText("RECORDE  " + best, w * 0.33f, h * 0.1f, Color.WHITE, 0.9f);
        } else if (state == State.GARAGE) {
            drawRect(w * 0.07f, h * 0.78f, w * 0.86f, h * 0.14f, new Color(0.015f, 0.025f, 0.08f, 0.90f));
            drawRect(w * 0.07f, h * 0.78f, 5f * uiScale(w), h * 0.14f, NEON[zone]);
            drawTextCentered("GARAGEM", w * 0.5f, h * 0.865f, Color.WHITE, 1.65f, w);
            drawTextCentered("ESCOLHA SEU HOVER  •  " + totalCoins + " MOEDAS", w * 0.5f, h * 0.805f,
                new Color(1f, 0.8f, 0.25f, 1f), 0.82f, w);
            String[] names = {"TURQUESA", "VIOLETA", "MAGENTA", "DOURADO"};
            int[] prices = {0, 60, 120, 200};
            for (int i = 0; i < 4; i++) {
                float cy = h * 0.66f - i * h * 0.112f;
                float cardX = w * 0.10f, cardW = w * 0.80f;
                float cardH = Math.min(h * 0.065f, 70f * uiScale(w));
                float cardY = cy - cardH * 0.5f;
                drawRect(cardX, cardY, cardW, cardH, new Color(0.025f, 0.045f, 0.12f, 0.94f));
                if (selectedSkin == i) {
                    float border = 4f * uiScale(w);
                    drawRect(cardX, cardY, border, cardH, NEON[zone]);
                    drawRect(cardX + border, cardY, cardW - border, 2f * uiScale(w),
                        new Color(NEON[zone].r, NEON[zone].g, NEON[zone].b, 0.46f));
                }
                float swatch = Math.min(cardH * 0.44f, 25f * uiScale(w));
                drawRect(cardX + cardW * 0.065f, cy - swatch * 0.5f, swatch, swatch, SKIN_COLORS[i]);
                drawText(names[i], cardX + cardW * 0.17f, cy + 5f * uiScale(w), Color.WHITE, 0.87f);
                String status = selectedSkin == i ? "EQUIPADO" : unlockedSkins[i] ? "USAR" : prices[i] + " MOEDAS";
                drawTextRight(status, cardX + cardW * 0.94f, cy + 5f * uiScale(w),
                    selectedSkin == i ? NEON[zone] : new Color(0.77f, 0.84f, 1f, 1f), 0.72f, w);
            }
            drawButton("VOLTAR", w * 0.18f, h * 0.075f, w * 0.64f, h * 0.075f, NEON[zone], w);
        } else {
            drawRect(w * 0.10f, h * 0.43f, w * 0.80f, h * 0.37f, new Color(0.015f, 0.025f, 0.08f, 0.9f));
            if (state == State.PAUSED) {
                drawText("PAUSADO", w * 0.3f, h * 0.72f, Color.WHITE, 1.8f);
                drawButton("CONTINUAR", w * 0.16f, h * 0.34f, w * 0.68f, h * 0.12f, NEON[zone]);
                drawButton("RECOMEÇAR", w * 0.16f, h * 0.19f, w * 0.68f, h * 0.11f, new Color(0.48f, 0.28f, 0.85f, 1f));
            } else {
                drawText("FIM DE JOGO", w * 0.22f, h * 0.73f, new Color(1f, 0.38f, 0.65f, 1f), 1.65f);
                drawText("PONTOS " + score + "     RECORDE " + best, w * 0.16f, h * 0.65f, Color.WHITE, 0.92f);
                drawText("+" + runCoins + " MOEDAS", w * 0.34f, h * 0.57f, new Color(1f, 0.8f, 0.25f, 1f), 1.05f);
                drawButton("JOGAR DE NOVO", w * 0.16f, h * 0.22f, w * 0.68f, h * 0.12f, NEON[zone]);
                drawButton("MENU", w * 0.16f, h * 0.075f, w * 0.68f, h * 0.10f, new Color(0.48f, 0.28f, 0.85f, 1f));
            }
        }
        uiBatch.end();
        Gdx.gl.glEnable(GL20.GL_DEPTH_TEST);
    }

    private void drawRect(float x, float y, float width, float height, Color color) {
        uiBatch.setColor(color); uiBatch.draw(pixel, x, y, width, height); uiBatch.setColor(Color.WHITE);
    }

    private void drawButton(String label, float x, float y, float width, float height, Color color) {
        drawButton(label, x, y, width, height, color, Gdx.graphics.getWidth());
    }

    private void drawButton(String label, float x, float y, float width, float height, Color color, float screenWidth) {
        drawRect(x, y, width, height, new Color(color.r, color.g, color.b, 0.92f));
        drawTextCentered(label, x + width * 0.5f, y + height * 0.58f, Color.WHITE, 0.94f, screenWidth);
    }

    private void drawText(String text, float x, float y, Color color, float scale) {
        font.getData().setScale(scale * uiScale(Gdx.graphics.getWidth()));
        font.setColor(color);
        font.draw(uiBatch, text, x, y);
        font.getData().setScale(1.12f);
        font.setColor(Color.WHITE);
    }

    private void drawTextCentered(String text, float centerX, float y, Color color, float scale, float screenWidth) {
        font.getData().setScale(scale * uiScale(screenWidth));
        font.setColor(color);
        com.badlogic.gdx.graphics.g2d.GlyphLayout layout = new com.badlogic.gdx.graphics.g2d.GlyphLayout(font, text);
        font.draw(uiBatch, layout, centerX - layout.width * 0.5f, y);
        font.getData().setScale(1.12f);
        font.setColor(Color.WHITE);
    }

    private void drawTextRight(String text, float rightX, float y, Color color, float scale, float screenWidth) {
        font.getData().setScale(scale * uiScale(screenWidth));
        font.setColor(color);
        com.badlogic.gdx.graphics.g2d.GlyphLayout layout = new com.badlogic.gdx.graphics.g2d.GlyphLayout(font, text);
        font.draw(uiBatch, layout, rightX - layout.width, y);
        font.getData().setScale(1.12f);
        font.setColor(Color.WHITE);
    }

    private float uiScale(float screenWidth) { return MathUtils.clamp(screenWidth / 400f, 0.72f, 2.0f); }

    @Override public void resize(int width, int height) {
        if (camera != null) { camera.viewportWidth = width; camera.viewportHeight = height; camera.update(); }
    }
    @Override public void pause() { if (state == State.PLAYING) state = State.PAUSED; }
    @Override public void resume() { }

    @Override public void dispose() {
        if (modelBatch != null) modelBatch.dispose();
        if (uiBatch != null) uiBatch.dispose();
        if (font != null) font.dispose();
        if (pixel != null) pixel.dispose();
        if (skylineTexture != null) skylineTexture.dispose();
        if (roadModel != null) roadModel.dispose();
        if (markModel != null) markModel.dispose();
        if (railModel != null) railModel.dispose();
        if (playerModel != null) playerModel.dispose();
        if (cockpitModel != null) cockpitModel.dispose();
        if (wingModel != null) wingModel.dispose();
        if (noseModel != null) noseModel.dispose();
        if (engineModel != null) engineModel.dispose();
        if (lampModel != null) lampModel.dispose();
        if (lowObstacleModel != null) lowObstacleModel.dispose();
        if (tallObstacleModel != null) tallObstacleModel.dispose();
        if (coinModel != null) coinModel.dispose();
        if (shieldModel != null) shieldModel.dispose();
        if (magnetModel != null) magnetModel.dispose();
        if (doubleModel != null) doubleModel.dispose();
        if (buildingModel != null) buildingModel.dispose();
        if (buildingLightModel != null) buildingLightModel.dispose();
        if (importedShipModel != null) importedShipModel.dispose();
    }

    private static final class Obstacle {
        final int lane; final ModelInstance body; final boolean jumpable;
        Obstacle(int lane, ModelInstance body, boolean jumpable) { this.lane = lane; this.body = body; this.jumpable = jumpable; }
    }
    private static final class Pickup {
        final int kind, lane; final ModelInstance model;
        Pickup(int kind, int lane, ModelInstance model) { this.kind = kind; this.lane = lane; this.model = model; }
    }
    private static final class Building {
        final int side; final ModelInstance body, light;
        float width, height, depth, x;
        Building(int side, ModelInstance body, ModelInstance light, float width, float height, float depth, float x) {
            this.side = side; this.body = body; this.light = light; this.width = width; this.height = height; this.depth = depth; this.x = x;
        }
    }
}
