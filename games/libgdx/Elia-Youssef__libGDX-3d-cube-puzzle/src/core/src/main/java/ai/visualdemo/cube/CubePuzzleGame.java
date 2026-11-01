package ai.visualdemo.cube;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input.Keys;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.PerspectiveCamera;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.PixmapIO;
import com.badlogic.gdx.graphics.VertexAttributes.Usage;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g3d.Environment;
import com.badlogic.gdx.graphics.g3d.Material;
import com.badlogic.gdx.graphics.g3d.Model;
import com.badlogic.gdx.graphics.g3d.ModelBatch;
import com.badlogic.gdx.graphics.g3d.ModelInstance;
import com.badlogic.gdx.graphics.g3d.attributes.ColorAttribute;
import com.badlogic.gdx.graphics.g3d.environment.DirectionalLight;
import com.badlogic.gdx.graphics.g3d.model.Node;
import com.badlogic.gdx.graphics.g3d.utils.MeshPartBuilder;
import com.badlogic.gdx.graphics.g3d.utils.ModelBuilder;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Interpolation;
import com.badlogic.gdx.math.Matrix4;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.math.collision.BoundingBox;

import java.util.Random;

/**
 * Owns the whole desktop presentation: the 3D scene (two suspended puzzle pieces, or the
 * completed cube after a win), the selection glow, and the HUD (timer + win/lose text). The
 * only class in this project that touches {@code Gdx.*}; all puzzle rules live in the GL-free
 * {@link CubePuzzleWorld}.
 */
public class CubePuzzleGame extends ApplicationAdapter {

    // Chosen together with the camera distance below so that, at every possible rotation, a
    // piece's farthest reach stays clear of the timer panel at the top AND a wide gap is left
    // at screen center - large enough for the "You Lose" message to sit in without ever
    // overlapping the (still separated) pieces. See BUILD-PLAN.md -> "Camera + HUD layout".
    private static final float PIECE_OFFSET_Y = 4.8f;
    private static final float MODEL_SCALE = 1.35f;
    private static final float SEAM_EXPANSION = 0.018f;
    private static final float SELECTION_BOX_PADDING = 14f;
    private static final float PULSE_SPEED = 6f;

    private static final Color BACKGROUND = new Color(0.04f, 0.04f, 0.08f, 1f);
    private static final Color GLOW_COLOR = new Color(1f, 0.95f, 0.55f, 1f);
    private static final Color SEAM_COLOR = new Color(0.015f, 0.02f, 0.04f, 1f);
    private static final Color WIN_TEXT_COLOR = new Color(0.35f, 0.95f, 0.45f, 1f);
    private static final Color LOSE_TEXT_COLOR = new Color(0.95f, 0.35f, 0.35f, 1f);
    private static final Color PANEL_COLOR = new Color(0f, 0f, 0f, 0.55f);

    // QA-only offscreen capture support (set on the instance via Lwjgl3Launcher's --capture /
    // --capture-frame / --scenario arguments, before create() runs). Never touched during
    // normal play: a plain `./gradlew lwjgl3:run` leaves captureEnabled false and these are all
    // no-ops.
    public boolean captureEnabled = false;
    public String captureFile = null;
    public int captureFrame = 2;
    public String scenario = null;
    private int frame = 0;

    private CubePuzzleWorld world;

    private PerspectiveCamera camera;
    private OrthographicCamera hudCamera;
    private Environment environment;
    private ModelBatch modelBatch;

    private Model pieceAModel;
    private Model pieceBModel;
    private Model assembledModel;
    private Model pieceASeamModel;
    private Model pieceBSeamModel;
    private Model assembledSeamModel;
    private ModelInstance pieceAInstance;
    private ModelInstance pieceBInstance;
    private ModelInstance assembledInstance;
    private ModelInstance pieceASeamInstance;
    private ModelInstance pieceBSeamInstance;
    private ModelInstance assembledSeamInstance;

    private Material pieceAMaterial;
    private Material pieceBMaterial;

    // Each piece's own local bounding box (before rotation/translation), used to draw the
    // selection glow: the box corners are transformed and projected to screen space every
    // frame to find where to draw the highlight around the selected piece.
    private final BoundingBox pieceALocalBounds = new BoundingBox();
    private final BoundingBox pieceBLocalBounds = new BoundingBox();
    private final Vector3[] boundsCorners = new Vector3[8];
    private final Matrix4 rotationMatrix = new Matrix4();
    private final Matrix4 selectionTransform = new Matrix4();

    private ShapeRenderer shapeRenderer;
    private SpriteBatch spriteBatch;
    private BitmapFont font;
    private GlyphLayout layout;

    private float pulseTime;

    @Override
    public void create() {
        world = new CubePuzzleWorld(new Random());
        if (scenario != null) {
            world.forceScenarioForQA(scenario);
        }

        camera = new PerspectiveCamera(55f, Gdx.graphics.getWidth(), Gdx.graphics.getHeight());
        // A slightly elevated, off-axis view exposes three faces at once. A straight-on camera
        // makes axis-aligned voxel rotations read like flat 2D silhouettes.
        camera.position.set(7.5f, 5f, 19.2f);
        camera.lookAt(0f, 0f, 0f);
        camera.near = 0.1f;
        camera.far = 100f;
        camera.update();

        hudCamera = new OrthographicCamera();
        hudCamera.setToOrtho(false, 800, 600);
        hudCamera.update();

        environment = new Environment();
        environment.set(ColorAttribute.createAmbientLight(0.45f, 0.45f, 0.5f, 1f));
        environment.add(new DirectionalLight().set(0.85f, 0.85f, 0.8f, -0.6f, -0.8f, -0.3f));

        modelBatch = new ModelBatch();

        pieceAModel = CubePuzzleFactory.createPieceA();
        pieceBModel = CubePuzzleFactory.createPieceB();
        assembledModel = CubePuzzleFactory.createAssembledCube();

        // Build thin edge overlays from the actual factory model nodes. This keeps the provided
        // geometry authoritative while making each one-unit voxel boundary legible, including
        // the otherwise coplanar boundaries on the completed cube.
        pieceASeamModel = createSeamModel(pieceAModel);
        pieceBSeamModel = createSeamModel(pieceBModel);
        assembledSeamModel = createSeamModel(assembledModel);

        pieceAInstance = new ModelInstance(pieceAModel);
        pieceBInstance = new ModelInstance(pieceBModel);
        assembledInstance = new ModelInstance(assembledModel);
        pieceASeamInstance = new ModelInstance(pieceASeamModel);
        pieceBSeamInstance = new ModelInstance(pieceBSeamModel);
        assembledSeamInstance = new ModelInstance(assembledSeamModel);
        assembledInstance.transform.setToScaling(MODEL_SCALE, MODEL_SCALE, MODEL_SCALE);
        assembledSeamInstance.transform.setToScaling(MODEL_SCALE, MODEL_SCALE, MODEL_SCALE);

        // Each piece's Model has exactly one shared Material across all of its unit cubes (see
        // CubePuzzleFactory), so grabbing it once here lets the selection glow recolor the whole
        // piece uniformly every frame without rebuilding any geometry.
        pieceAMaterial = pieceAModel.materials.first();
        pieceBMaterial = pieceBModel.materials.first();

        pieceAModel.calculateBoundingBox(pieceALocalBounds);
        pieceBModel.calculateBoundingBox(pieceBLocalBounds);
        for (int i = 0; i < boundsCorners.length; i++) {
            boundsCorners[i] = new Vector3();
        }

        shapeRenderer = new ShapeRenderer();
        spriteBatch = new SpriteBatch();
        font = new BitmapFont();
        font.getData().setScale(1.4f);
        layout = new GlyphLayout();
    }

    @Override
    public void render() {
        float delta = Gdx.graphics.getDeltaTime();
        world.update(delta);

        // Advance the clock before sampling gameplay input. This makes expiration authoritative
        // on the exact frame it occurs instead of allowing one final rotation after time ran out.
        if (!captureEnabled) {
            handleInput();
        }
        pulseTime += delta;

        Gdx.gl.glClearColor(BACKGROUND.r, BACKGROUND.g, BACKGROUND.b, 1f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT | GL20.GL_DEPTH_BUFFER_BIT);
        Gdx.gl.glEnable(GL20.GL_DEPTH_TEST);

        updateSelectionGlow();

        modelBatch.begin(camera);
        if (world.getState() == GameState.WON) {
            modelBatch.render(assembledInstance, environment);
            modelBatch.render(assembledSeamInstance, environment);
        } else {
            renderPiece(world.getPieceA(), pieceAInstance, pieceASeamInstance, +1f);
            renderPiece(world.getPieceB(), pieceBInstance, pieceBSeamInstance, -1f);
        }
        modelBatch.end();

        renderHud();

        if (captureEnabled && captureFile != null) {
            frame++;
            if (frame >= captureFrame) {
                saveFrame(captureFile);
                Gdx.app.exit();
            }
        }
    }

    private void handleInput() {
        // R always works, regardless of state - mid-game, mid-animation, won, or lost.
        if (Gdx.input.isKeyJustPressed(Keys.R)) {
            world.reset();
            return;
        }
        if (Gdx.input.isKeyJustPressed(Keys.TAB)) {
            world.selectNext();
        }
        if (Gdx.input.isKeyJustPressed(Keys.UP)) {
            world.rotateSelected(RotationDirection.UP);
        } else if (Gdx.input.isKeyJustPressed(Keys.DOWN)) {
            world.rotateSelected(RotationDirection.DOWN);
        } else if (Gdx.input.isKeyJustPressed(Keys.LEFT)) {
            world.rotateSelected(RotationDirection.LEFT);
        } else if (Gdx.input.isKeyJustPressed(Keys.RIGHT)) {
            world.rotateSelected(RotationDirection.RIGHT);
        }
    }

    private void updateSelectionGlow() {
        boolean interactive = world.getState() == GameState.PLAYING;
        float pulse = 0.5f + 0.5f * (float) Math.sin(pulseTime * PULSE_SPEED);
        setGlow(pieceAMaterial, interactive && world.getSelectedIndex() == 0, pulse);
        setGlow(pieceBMaterial, interactive && world.getSelectedIndex() == 1, pulse);
    }

    private void setGlow(Material material, boolean glowing, float pulse) {
        material.remove(ColorAttribute.Emissive);
        if (glowing) {
            float intensity = 0.25f + 0.55f * pulse;
            material.set(ColorAttribute.createEmissive(
                    GLOW_COLOR.r * intensity, GLOW_COLOR.g * intensity, GLOW_COLOR.b * intensity, 1f));
        }
    }

    /** Renders one suspended piece at its current animated offset and orientation. */
    private void renderPiece(PuzzlePiece piece, ModelInstance instance, ModelInstance seamInstance, float sign) {
        float offsetY = sign * currentOffsetMagnitude();
        buildTransform(instance.transform, piece, offsetY, MODEL_SCALE);
        seamInstance.transform.set(instance.transform);
        modelBatch.render(instance, environment);
        modelBatch.render(seamInstance, environment);
    }

    /** How far from center a piece currently sits - animates toward 0 while ASSEMBLING. */
    private float currentOffsetMagnitude() {
        if (world.getState() == GameState.ASSEMBLING) {
            float eased = Interpolation.pow2Out.apply(world.getAssemblyProgress());
            return PIECE_OFFSET_Y * (1f - eased);
        }
        return PIECE_OFFSET_Y;
    }

    private void buildTransform(Matrix4 out, PuzzlePiece piece, float offsetY, float scale) {
        out.setToTranslation(0f, offsetY, 0f);
        rotationMatrix.idt();
        piece.getOrientation().applyRotation(rotationMatrix);
        out.mul(rotationMatrix);
        if (scale != 1f) {
            out.scale(scale, scale, scale);
        }
    }

    private void renderHud() {
        GameState state = world.getState();
        Rectangle selectionBox = state == GameState.PLAYING ? computeSelectedPieceScreenBox() : null;

        Gdx.gl.glEnable(GL20.GL_BLEND);
        shapeRenderer.setProjectionMatrix(hudCamera.combined);

        if (selectionBox != null) {
            // A pulsing box around the selected piece's projected screen bounds - the "glowing
            // highlighted outline" the prompt asks for. Drawn as a few nested rectangles of
            // falling alpha so it reads as a soft glow rather than one hard line.
            float pulse = 0.5f + 0.5f * (float) Math.sin(pulseTime * PULSE_SPEED);
            shapeRenderer.begin(ShapeRenderer.ShapeType.Line);
            for (int layer = 0; layer < 3; layer++) {
                float grow = layer * 3f;
                float alpha = (0.85f - layer * 0.25f) * (0.6f + 0.4f * pulse);
                shapeRenderer.setColor(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, alpha);
                shapeRenderer.rect(selectionBox.x - grow, selectionBox.y - grow,
                        selectionBox.width + grow * 2f, selectionBox.height + grow * 2f);
            }
            shapeRenderer.end();
        }

        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);
        shapeRenderer.setColor(PANEL_COLOR);
        shapeRenderer.rect(310f, 552f, 180f, 42f);
        if (state == GameState.WON) {
            // The assembled cube sits centered on screen, so the message panel goes low,
            // clear of it (see the camera-framing math in BUILD-PLAN.md).
            shapeRenderer.rect(190f, 35f, 420f, 78f);
        } else if (state == GameState.LOST) {
            // The two pieces stay pushed apart here (never centered), which leaves a wide gap
            // free at screen center - unlike the low band, that gap stays clear of the pieces
            // at every possible rotation, so the message goes there instead of at the bottom.
            shapeRenderer.rect(190f, 262f, 420f, 78f);
        }
        shapeRenderer.end();
        Gdx.gl.glDisable(GL20.GL_BLEND);

        spriteBatch.setProjectionMatrix(hudCamera.combined);
        spriteBatch.begin();

        drawCentered(formatTime(world.getTimeRemaining()), Color.WHITE, 588f);

        if (state == GameState.WON) {
            drawCentered("You Win", WIN_TEXT_COLOR, 90f);
            drawCentered("Press R to Restart", Color.WHITE, 55f);
        } else if (state == GameState.LOST) {
            drawCentered("You Lose", LOSE_TEXT_COLOR, 317f);
            drawCentered("Press R to Restart", Color.WHITE, 282f);
        }

        spriteBatch.end();
    }

    /**
     * Finds the selected piece's current screen-space bounding rectangle, by transforming its
     * local bounding box corners the same way it is rendered and projecting each to screen
     * space. Used to draw a selection glow that always exactly frames the piece, however it is
     * currently rotated or positioned.
     */
    private Rectangle computeSelectedPieceScreenBox() {
        PuzzlePiece piece = world.selectedPiece();
        BoundingBox localBounds = piece.index == 0 ? pieceALocalBounds : pieceBLocalBounds;
        float sign = piece.index == 0 ? +1f : -1f;
        float offsetY = sign * currentOffsetMagnitude();

        buildTransform(selectionTransform, piece, offsetY, MODEL_SCALE);

        boundsCorners[0].set(localBounds.min.x, localBounds.min.y, localBounds.min.z);
        boundsCorners[1].set(localBounds.max.x, localBounds.min.y, localBounds.min.z);
        boundsCorners[2].set(localBounds.min.x, localBounds.max.y, localBounds.min.z);
        boundsCorners[3].set(localBounds.max.x, localBounds.max.y, localBounds.min.z);
        boundsCorners[4].set(localBounds.min.x, localBounds.min.y, localBounds.max.z);
        boundsCorners[5].set(localBounds.max.x, localBounds.min.y, localBounds.max.z);
        boundsCorners[6].set(localBounds.min.x, localBounds.max.y, localBounds.max.z);
        boundsCorners[7].set(localBounds.max.x, localBounds.max.y, localBounds.max.z);

        float minX = Float.MAX_VALUE;
        float minY = Float.MAX_VALUE;
        float maxX = -Float.MAX_VALUE;
        float maxY = -Float.MAX_VALUE;
        for (Vector3 corner : boundsCorners) {
            corner.mul(selectionTransform);
            camera.project(corner);
            minX = Math.min(minX, corner.x);
            maxX = Math.max(maxX, corner.x);
            minY = Math.min(minY, corner.y);
            maxY = Math.max(maxY, corner.y);
        }

        return new Rectangle(minX - SELECTION_BOX_PADDING, minY - SELECTION_BOX_PADDING,
                (maxX - minX) + SELECTION_BOX_PADDING * 2f, (maxY - minY) + SELECTION_BOX_PADDING * 2f);
    }

    private void drawCentered(String text, Color color, float y) {
        font.setColor(color);
        layout.setText(font, text);
        font.draw(spriteBatch, layout, 400f - layout.width / 2f, y);
    }

    private static String formatTime(float secondsRemaining) {
        int wholeSeconds = (int) Math.ceil(secondsRemaining);
        int minutes = wholeSeconds / 60;
        int seconds = wholeSeconds % 60;
        return String.format("%02d:%02d", minutes, seconds);
    }

    /**
     * Creates a dark wireframe box around every voxel node in a factory model. Bounds are read
     * directly from the supplied model, so this presentation layer cannot silently diverge from
     * CubePuzzleFactory's puzzle geometry.
     */
    private static Model createSeamModel(Model source) {
        ModelBuilder builder = new ModelBuilder();
        Material seamMaterial = new Material(
                ColorAttribute.createDiffuse(SEAM_COLOR),
                ColorAttribute.createEmissive(SEAM_COLOR));
        BoundingBox bounds = new BoundingBox();
        Vector3 center = new Vector3();
        Vector3 dimensions = new Vector3();

        builder.begin();
        int partIndex = 0;
        for (Node node : source.nodes) {
            node.calculateBoundingBox(bounds, true);
            bounds.getCenter(center);
            bounds.getDimensions(dimensions);

            builder.node();
            MeshPartBuilder part = builder.part(
                    "voxel_seam_" + partIndex++, GL20.GL_LINES, Usage.Position, seamMaterial);
            part.box(center.x, center.y, center.z,
                    dimensions.x + SEAM_EXPANSION,
                    dimensions.y + SEAM_EXPANSION,
                    dimensions.z + SEAM_EXPANSION);
        }
        return builder.end();
    }

    @Override
    public void resize(int width, int height) {
        camera.viewportWidth = width;
        camera.viewportHeight = height;
        camera.update();
    }

    /** QA-only: dumps the current backbuffer to a PNG file. */
    private void saveFrame(String path) {
        int w = Gdx.graphics.getBackBufferWidth();
        int h = Gdx.graphics.getBackBufferHeight();
        Pixmap raw = Pixmap.createFromFrameBuffer(0, 0, w, h);
        Pixmap flipped = new Pixmap(w, h, Pixmap.Format.RGBA8888);
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                flipped.drawPixel(x, h - 1 - y, raw.getPixel(x, y));
            }
        }
        FileHandle target = Gdx.files.local(path);
        PixmapIO.writePNG(target, flipped);
        raw.dispose();
        flipped.dispose();
    }

    @Override
    public void dispose() {
        modelBatch.dispose();
        pieceAModel.dispose();
        pieceBModel.dispose();
        assembledModel.dispose();
        pieceASeamModel.dispose();
        pieceBSeamModel.dispose();
        assembledSeamModel.dispose();
        shapeRenderer.dispose();
        spriteBatch.dispose();
        font.dispose();
    }
}
