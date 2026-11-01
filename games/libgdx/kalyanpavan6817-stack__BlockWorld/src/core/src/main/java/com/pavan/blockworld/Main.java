
package com.pavan.blockworld;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.PerspectiveCamera;
import com.badlogic.gdx.graphics.VertexAttributes;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g3d.*;
import com.badlogic.gdx.graphics.g3d.attributes.ColorAttribute;
import com.badlogic.gdx.graphics.g3d.environment.DirectionalLight;
import com.badlogic.gdx.graphics.g3d.utils.ModelBuilder;
import com.badlogic.gdx.graphics.g3d.utils.MeshPartBuilder;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.utils.Array;

public class Main extends ApplicationAdapter {

    private PerspectiveCamera camera;
    private ModelBatch batch;
    private Environment environment;

    private Model grassModel, dirtModel, stoneModel;
    private final Array<Block> blocks = new Array<>();

    // HUD
    private ShapeRenderer hudShapes;
    private SpriteBatch hudBatch;
    private BitmapFont hudFont;
    private com.badlogic.gdx.math.Matrix4 hudProjection;

    // 0 = Grass, 1 = Dirt, 2 = Stone
    private int selectedBlockType = 0;

    private float yaw = -90f;
    private float pitch = -15f;
    private float verticalVelocity = 0f;
    private boolean onGround = false;

    private static final int WORLD_SIZE = 24;
    private static final int DEPTH = 5;

    private static final float EYE_HEIGHT = 1.7f;
    private static final float PLAYER_HEIGHT = 1.8f;
    private static final float PLAYER_RADIUS = 0.30f;
    private static final float SPEED = 5f;
    private static final float GRAVITY = 22f;
    private static final float JUMP_SPEED = 8f;
    private static final float REACH = 6f;
    private static final float MAX_DELTA = 0.033f;

    private static class Block {
        int x, y, z, type;
        ModelInstance instance;

        Block(int x, int y, int z, int type, Model model) {
            this.x = x;
            this.y = y;
            this.z = z;
            this.type = type;

            instance = new ModelInstance(model);
            instance.transform.setToTranslation(x, y, z);
        }
    }

    private static class Hit {
        Block block;
        int previousX, previousY, previousZ;

        Hit(Block block, int x, int y, int z) {
            this.block = block;
            previousX = x;
            previousY = y;
            previousZ = z;
        }
    }

    @Override
    public void create() {
        batch = new ModelBatch();

        camera = new PerspectiveCamera(
            75f,
            Gdx.graphics.getWidth(),
            Gdx.graphics.getHeight()
        );

        camera.near = 0.1f;
        camera.far = 100f;

        environment = new Environment();

        environment.set(new ColorAttribute(
            ColorAttribute.AmbientLight,
            0.48f, 0.48f, 0.48f, 1f
        ));

        environment.add(new DirectionalLight().set(
            0.75f, 0.75f, 0.75f,
            -1f, -0.8f, -0.4f
        ));

        grassModel = createGrassModel();

        dirtModel = createCube(
            new Color(0.43f, 0.23f, 0.10f, 1f)
        );

        stoneModel = createCube(
            new Color(0.48f, 0.50f, 0.53f, 1f)
        );

        generateTerrain();

        float sx = WORLD_SIZE / 2f;
        float sz = WORLD_SIZE / 2f;

        camera.position.set(
            sx,
            getGroundHeight(sx, sz) + EYE_HEIGHT,
            sz
        );

        camera.direction.set(0f, -0.15f, -1f).nor();
        camera.up.set(Vector3.Y);
        camera.update();

        // Initialize HUD objects.
        hudShapes = new ShapeRenderer();
        hudBatch = new SpriteBatch();
        hudFont = new BitmapFont();
        hudFont.getData().setScale(1.1f);

        hudProjection = new com.badlogic.gdx.math.Matrix4();

        onGround = true;
        Gdx.input.setCursorCatched(true);
    }

    private Material material(Color color) {
        return new Material(
            ColorAttribute.createDiffuse(color)
        );
    }

    private Model createCube(Color color) {
        ModelBuilder builder = new ModelBuilder();

        return builder.createBox(
            1f, 1f, 1f,
            material(color),
            VertexAttributes.Usage.Position |
            VertexAttributes.Usage.Normal
        );
    }

    // Grass top is green; the sides and bottom are brown.
    private Model createGrassModel() {
        ModelBuilder builder = new ModelBuilder();

        Material green = material(
            new Color(0.22f, 0.48f, 0.12f, 1f)
        );

        Material brown = material(
            new Color(0.43f, 0.23f, 0.10f, 1f)
        );

        long attrs = VertexAttributes.Usage.Position |
                     VertexAttributes.Usage.Normal;

        builder.begin();

        MeshPartBuilder top = builder.part(
            "top", GL20.GL_TRIANGLES, attrs, green
        );

        top.rect(
            new Vector3(-0.5f, 0.5f, -0.5f),
            new Vector3(-0.5f, 0.5f,  0.5f),
            new Vector3( 0.5f, 0.5f,  0.5f),
            new Vector3( 0.5f, 0.5f, -0.5f),
            new Vector3(0f, 1f, 0f)
        );

        MeshPartBuilder sides = builder.part(
            "sides", GL20.GL_TRIANGLES, attrs, brown
        );

        // Front
        sides.rect(
            new Vector3(-0.5f, -0.5f, 0.5f),
            new Vector3(-0.5f,  0.5f, 0.5f),
            new Vector3( 0.5f,  0.5f, 0.5f),
            new Vector3( 0.5f, -0.5f, 0.5f),
            new Vector3(0f, 0f, 1f)
        );

        // Back
        sides.rect(
            new Vector3(0.5f, -0.5f, -0.5f),
            new Vector3(0.5f,  0.5f, -0.5f),
            new Vector3(-0.5f, 0.5f, -0.5f),
            new Vector3(-0.5f, -0.5f, -0.5f),
            new Vector3(0f, 0f, -1f)
        );

        // Right
        sides.rect(
            new Vector3(0.5f, -0.5f, 0.5f),
            new Vector3(0.5f,  0.5f, 0.5f),
            new Vector3(0.5f,  0.5f, -0.5f),
            new Vector3(0.5f, -0.5f, -0.5f),
            new Vector3(1f, 0f, 0f)
        );

        // Left
        sides.rect(
            new Vector3(-0.5f, -0.5f, -0.5f),
            new Vector3(-0.5f,  0.5f, -0.5f),
            new Vector3(-0.5f,  0.5f, 0.5f),
            new Vector3(-0.5f, -0.5f, 0.5f),
            new Vector3(-1f, 0f, 0f)
        );

        // Bottom
        sides.rect(
            new Vector3(-0.5f, -0.5f, -0.5f),
            new Vector3(-0.5f, -0.5f,  0.5f),
            new Vector3( 0.5f, -0.5f,  0.5f),
            new Vector3( 0.5f, -0.5f, -0.5f),
            new Vector3(0f, -1f, 0f)
        );

        return builder.end();
    }

    private int terrainHeight(int x, int z) {
        return 2 + Math.round((float) (
            Math.sin(x * 0.38) * 1.5
            + Math.cos(z * 0.31) * 1.3
            + Math.sin((x + z) * 0.22)
        ));
    }

    private void generateTerrain() {
        for (int x = 0; x < WORLD_SIZE; x++) {
            for (int z = 0; z < WORLD_SIZE; z++) {
                int height = terrainHeight(x, z);

                for (int depth = 0; depth < DEPTH; depth++) {
                    int y = height - depth;

                    int type = depth == 0 ? 0 :
                               depth <= 2 ? 1 : 2;

                    Model model = getModel(type);

                    blocks.add(
                        new Block(x, y, z, type, model)
                    );
                }
            }
        }
    }

    private Model getModel(int type) {
        if (type == 1) return dirtModel;
        if (type == 2) return stoneModel;
        return grassModel;
    }

    private Block findBlock(int x, int y, int z) {
        for (Block b : blocks) {
            if (b.x == x && b.y == y && b.z == z) {
                return b;
            }
        }
        return null;
    }

    private void addBlock(int x, int y, int z, int type) {
        if (findBlock(x, y, z) != null) return;

        blocks.add(new Block(
            x, y, z, type, getModel(type)
        ));
    }

private boolean horizontalOverlap(float x, float z, Block b) {
    float closestX = Math.max(b.x - 0.5f,
        Math.min(x, b.x + 0.5f));
    float closestZ = Math.max(b.z - 0.5f,
        Math.min(z, b.z + 0.5f));

    float dx = x - closestX;
    float dz = z - closestZ;

    return dx * dx + dz * dz <
        PLAYER_RADIUS * PLAYER_RADIUS;
}

   private boolean collidesAt(float x, float feet, float z) {
    float head = feet + PLAYER_HEIGHT;

    for (Block b : blocks) {
        float blockBottom = b.y - 0.5f;
        float blockTop = b.y + 0.5f;

        if (head <= blockBottom + 0.001f ||
            feet >= blockTop - 0.001f) {
            continue;
        }

        if (horizontalOverlap(x, z, b)) {
            return true;
        }
    }

    return false;
}

    private float getGroundHeight(float x, float z) {
        float highest = Float.NEGATIVE_INFINITY;

        for (Block b : blocks) {
            if (horizontalOverlap(x, z, b)) {
                highest = Math.max(highest, b.y + 0.5f);
            }
        }

        return highest;
    }

  private float findLandingSurface(
    float x, float z, float oldFeet, float nextFeet
) {
    float landing = Float.NEGATIVE_INFINITY;

    for (Block b : blocks) {
        if (!horizontalOverlap(x, z, b)) {
            continue;
        }

        float top = b.y + 0.5f;

        if (oldFeet >= top - 0.06f &&
            nextFeet <= top) {
            landing = Math.max(landing, top);
        }
    }

    return landing;
}

  private void updatePlayer(float delta) {
    Vector3 forward = new Vector3(
        camera.direction.x, 0f, camera.direction.z
    );

    if (forward.len2() > 0.0001f) {
        forward.nor();
    }

    Vector3 right = new Vector3(forward)
        .crs(Vector3.Y).nor();

    Vector3 move = new Vector3();

    if (Gdx.input.isKeyPressed(Input.Keys.W)) move.add(forward);
    if (Gdx.input.isKeyPressed(Input.Keys.S)) move.sub(forward);
    if (Gdx.input.isKeyPressed(Input.Keys.D)) move.add(right);
    if (Gdx.input.isKeyPressed(Input.Keys.A)) move.sub(right);

    if (move.len2() > 0f) {
        move.nor().scl(SPEED * delta);

        float distance = move.len();
        int steps = Math.max(1,
            (int) Math.ceil(distance / 0.04f));

        float stepX = move.x / steps;
        float stepZ = move.z / steps;

        for (int i = 0; i < steps; i++) {
            float feet = camera.position.y - EYE_HEIGHT;

            float nextX = camera.position.x + stepX;
            if (!collidesAt(nextX, feet, camera.position.z)) {
                camera.position.x = nextX;
            }

            float nextZ = camera.position.z + stepZ;
            if (!collidesAt(camera.position.x, feet, nextZ)) {
                camera.position.z = nextZ;
            }
        }
    }

    float feet = camera.position.y - EYE_HEIGHT;

    if (onGround &&
        Gdx.input.isKeyJustPressed(Input.Keys.SPACE)) {
        verticalVelocity = JUMP_SPEED;
        onGround = false;
    }

    float oldFeet = feet;

    verticalVelocity -= GRAVITY * delta;
    float nextFeet = oldFeet + verticalVelocity * delta;

    if (verticalVelocity <= 0f) {
        float landing = findLandingSurface(
            camera.position.x,
            camera.position.z,
            oldFeet,
            nextFeet
        );

        if (landing != Float.NEGATIVE_INFINITY) {
            camera.position.y = landing + EYE_HEIGHT;
            verticalVelocity = 0f;
            onGround = true;
        } else if (!collidesAt(
            camera.position.x, nextFeet, camera.position.z
        )) {
            camera.position.y = nextFeet + EYE_HEIGHT;
            onGround = false;
        } else {
            verticalVelocity = 0f;
        }
    } else {
        if (!collidesAt(
            camera.position.x, nextFeet, camera.position.z
        )) {
            camera.position.y = nextFeet + EYE_HEIGHT;
        } else {
            verticalVelocity = 0f;
        }
    }

    camera.position.x = Math.max(
        0.55f, Math.min(WORLD_SIZE - 0.55f, camera.position.x)
    );

    camera.position.z = Math.max(
        0.55f, Math.min(WORLD_SIZE - 0.55f, camera.position.z)
    );
}
    private Hit raycast() {
        Vector3 origin = camera.position;
        Vector3 direction = camera.direction;

        for (float d = 0.1f; d <= REACH; d += 0.04f) {
            int x = Math.round(origin.x + direction.x * d);
            int y = Math.round(origin.y + direction.y * d);
            int z = Math.round(origin.z + direction.z * d);

            Block b = findBlock(x, y, z);

            if (b != null) {
                float prev = Math.max(0f, d - 0.08f);

                return new Hit(
                    b,
                    Math.round(origin.x + direction.x * prev),
                    Math.round(origin.y + direction.y * prev),
                    Math.round(origin.z + direction.z * prev)
                );
            }
        }

        return null;
    }

    private void mineBlock() {
        Hit hit = raycast();

        if (hit == null || hit.block.y <= -3) return;

        blocks.removeValue(hit.block, true);
    }

    private void placeBlock() {
    Hit hit = raycast();
    if (hit == null) return;

    int x = hit.previousX;
    int y = hit.previousY;
    int z = hit.previousZ;

    if (findBlock(x, y, z) != null) return;

    float feet = camera.position.y - EYE_HEIGHT;
    float head = feet + PLAYER_HEIGHT;

    // Check whether the new block would overlap the player.
    boolean overlapsVertically =
        head > y - 0.5f && feet < y + 0.5f;

    if (overlapsVertically) {
        float closestX = Math.max(
            x - 0.5f,
            Math.min(camera.position.x, x + 0.5f)
        );

        float closestZ = Math.max(
            z - 0.5f,
            Math.min(camera.position.z, z + 0.5f)
        );

        float dx = camera.position.x - closestX;
        float dz = camera.position.z - closestZ;

        if (dx * dx + dz * dz <
            PLAYER_RADIUS * PLAYER_RADIUS) {
            return;
        }
    }

    addBlock(x, y, z, selectedBlockType);
}

    private static class BlockPosition {
    int x, y, z;

    BlockPosition(int x, int y, int z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
}

    private void renderHud() {
        float w = Gdx.graphics.getWidth();
        float h = Gdx.graphics.getHeight();

        hudProjection.setToOrtho2D(0f, 0f, w, h);

        float slot = 52f;
        float gap = 6f;
        float totalWidth = slot * 3f + gap * 2f;
        float startX = (w - totalWidth) / 2f;
        float barY = 22f;

        // Hotbar background and block previews.
        hudShapes.setProjectionMatrix(hudProjection);
        hudShapes.begin(ShapeRenderer.ShapeType.Filled);

        for (int i = 0; i < 3; i++) {
            float x = startX + i * (slot + gap);

            hudShapes.setColor(0.08f, 0.08f, 0.08f, 0.90f);
            hudShapes.rect(x, barY, slot, slot);

            if (i == 0) {
                hudShapes.setColor(0.22f, 0.48f, 0.12f, 1f);
            } else if (i == 1) {
                hudShapes.setColor(0.43f, 0.23f, 0.10f, 1f);
            } else {
                hudShapes.setColor(0.48f, 0.50f, 0.53f, 1f);
            }

            hudShapes.rect(
                x + 13f, barY + 12f, 26f, 26f
            );
        }

        hudShapes.end();

        // Selected slot and crosshair.
        hudShapes.begin(ShapeRenderer.ShapeType.Line);

        hudShapes.setColor(1f, 1f, 1f, 1f);

        float selectedX =
            startX + selectedBlockType * (slot + gap);

        hudShapes.rect(
            selectedX - 2f, barY - 2f,
            slot + 4f, slot + 4f
        );

        float cx = w / 2f;
        float cy = h / 2f;

        hudShapes.setColor(0f, 0f, 0f, 1f);
        hudShapes.rectLine(cx - 9f, cy, cx + 9f, cy, 4f);
        hudShapes.rectLine(cx, cy - 9f, cx, cy + 9f, 4f);

        hudShapes.setColor(1f, 1f, 1f, 1f);
        hudShapes.rectLine(cx - 8f, cy, cx + 8f, cy, 2f);
        hudShapes.rectLine(cx, cy - 8f, cx, cy + 8f, 2f);

        hudShapes.end();

        // Hotbar labels.
        hudBatch.setProjectionMatrix(hudProjection);
        hudFont.setColor(Color.WHITE);

        String[] names = {"Grass", "Dirt", "Stone"};

        hudBatch.begin();

        for (int i = 0; i < 3; i++) {
            float x = startX + i * (slot + gap);

            hudFont.draw(
                hudBatch,
                String.valueOf(i + 1),
                x + 4f,
                barY + slot - 4f
            );
        }

        hudFont.draw(
            hudBatch,
            "Selected: " + names[selectedBlockType],
            startX,
            barY + slot + 25f
        );

        hudBatch.end();
    }

    @Override
    public void render() {
        float delta = Math.min(
            Gdx.graphics.getDeltaTime(), MAX_DELTA
        );

        if (Gdx.input.isKeyJustPressed(Input.Keys.ESCAPE)) {
            Gdx.input.setCursorCatched(false);
        }

        if (Gdx.input.isButtonJustPressed(Input.Buttons.LEFT)
            && !Gdx.input.isCursorCatched()) {
            Gdx.input.setCursorCatched(true);
        } else if (Gdx.input.isCursorCatched()) {
            yaw += Gdx.input.getDeltaX() * 0.20f;
            pitch -= Gdx.input.getDeltaY() * 0.20f;
            pitch = Math.max(-89f, Math.min(89f, pitch));
        }

        // Select the hotbar slot.
        if (Gdx.input.isKeyJustPressed(Input.Keys.NUM_1)) {
            selectedBlockType = 0;
        }
        if (Gdx.input.isKeyJustPressed(Input.Keys.NUM_2)) {
            selectedBlockType = 1;
        }
        if (Gdx.input.isKeyJustPressed(Input.Keys.NUM_3)) {
            selectedBlockType = 2;
        }

        camera.direction.set(
            (float) (
                Math.cos(Math.toRadians(yaw)) *
                Math.cos(Math.toRadians(pitch))
            ),
            (float) Math.sin(Math.toRadians(pitch)),
            (float) (
                Math.sin(Math.toRadians(yaw)) *
                Math.cos(Math.toRadians(pitch))
            )
        ).nor();

        if (Gdx.input.isCursorCatched()) {
            if (Gdx.input.isButtonJustPressed(Input.Buttons.LEFT)) {
                mineBlock();
            }

            if (Gdx.input.isButtonJustPressed(Input.Buttons.RIGHT)) {
                placeBlock();
            }
        }

        updatePlayer(delta);
        camera.update();

        Gdx.gl.glViewport(
            0, 0,
            Gdx.graphics.getWidth(),
            Gdx.graphics.getHeight()
        );

        Gdx.gl.glClearColor(0.53f, 0.76f, 0.91f, 1f);

        Gdx.gl.glClear(
            GL20.GL_COLOR_BUFFER_BIT |
            GL20.GL_DEPTH_BUFFER_BIT
        );

        Gdx.gl.glEnable(GL20.GL_DEPTH_TEST);

        batch.begin(camera);

        for (Block b : blocks) {
            batch.render(b.instance, environment);
        }

        batch.end();

        // HUD must be drawn after the 3D world.
        renderHud();
    }

    @Override
    public void resize(int width, int height) {
        if (camera == null) return;

        camera.viewportWidth = width;
        camera.viewportHeight = height;
        camera.update();
    }

    @Override
    public void dispose() {
        if (batch != null) batch.dispose();

        if (grassModel != null) grassModel.dispose();
        if (dirtModel != null) dirtModel.dispose();
        if (stoneModel != null) stoneModel.dispose();

        if (hudShapes != null) hudShapes.dispose();
        if (hudBatch != null) hudBatch.dispose();
        if (hudFont != null) hudFont.dispose();
    }
}
