package fi.tamk.sunkensoft;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.physics.box2d.Body;
import com.badlogic.gdx.physics.box2d.BodyDef;
import com.badlogic.gdx.physics.box2d.FixtureDef;
import com.badlogic.gdx.physics.box2d.PolygonShape;

public class Knight {
    CastleGame game;
    private Texture enemySheet;
    private Texture enemySheetBoss;
    private Animation walkAnimation;
    private Animation walkAnimationBoss;
    private TextureRegion currentFrameTexture;
    private TextureRegion currentFrameTextureBoss;

    private float stateTime;
    private float x = 720f;
    private float y = 950f;
    private float speed = -40f;

    FixtureDef enemyFixtureDef;
    BodyDef enemyBodyDef;

    Body enemyBody;
    float enemyPos = x;

    int cLevel;
    float enemyRise = 0.001f;
    float enemyDensity = 1.0f;

    /**
     * Create textures, animations, bodies and all that is need to make an enemy.
     *
     * @param gam is part of Screens and it's needed here to use variables
     *             from CastleGame class.
     */
    public Knight(CastleGame gam) {
        game = gam;
        enemySheet = new Texture("goblin.png");
        enemySheetBoss = new Texture("orcboss.png");
        createAnimation();
        createEnemyBody();
    }

    /**
     * Creates enemy body for box2d world.
     */
    private void createEnemyBody() {
        BodyDef enemyBodyDef = new BodyDef();

        // Dynamic / Static / Kinematic
        enemyBodyDef.type = BodyDef.BodyType.DynamicBody;
        enemyBodyDef.position.set((x - ((enemySheet.getWidth() / 3) / 2)), y);
        enemyBody = GameScreen.world.createBody(enemyBodyDef);

        enemyFixtureDef = new FixtureDef();
        enemyFixtureDef.density = 1.0f;
        enemyFixtureDef.restitution = 0.0f;
        enemyFixtureDef.friction = 0.0f;

        PolygonShape enemyBox = new PolygonShape();
        enemyBox.setAsBox(55, 80);

        enemyFixtureDef.shape = enemyBox;
        enemyBody.createFixture(enemyFixtureDef);
        enemyBody.setFixedRotation(true);
        enemyBody.setUserData("enemy");
    }

    /**
     * Animate enemy's movement
     */
    public void createAnimation() {
        final int FRAME_COLS = 3;
        final int FRAME_ROWS = 1;

        int tileWidth = enemySheet.getWidth() / FRAME_COLS;
        int tileHeight = enemySheet.getHeight();

        // Create 2D array from the texture (REGIONS of a TEXTURE).
        TextureRegion[][] tmp = TextureRegion.split(enemySheet, tileWidth, tileHeight);

        // Transform the 2D array to 1D
        TextureRegion[] allFrames = toTextureArray(tmp, FRAME_COLS, FRAME_ROWS);

        walkAnimation = new Animation(3 / 30f, allFrames);
        currentFrameTexture = walkAnimation.getKeyFrame(stateTime, true);

        // --- BOSS ---
        TextureRegion[][] tmpBoss = TextureRegion.split(enemySheetBoss, tileWidth, tileHeight+10);
        TextureRegion[] allFramesBoss = toTextureArray(tmpBoss, FRAME_COLS, FRAME_ROWS);

        walkAnimationBoss = new Animation(3 / 30f, allFramesBoss);
        currentFrameTextureBoss = walkAnimationBoss.getKeyFrame(stateTime, true);
    }

    /**
     * Renders enemy and if player is at level 5 we draw boss which is a bit harder.
     *
     * @param batch SpriteBatch needed to draw textures
     */
    public void update(SpriteBatch batch) {
        if(cLevel%5 == 0){
            enemyRise = 0.002f;
            batch.draw(currentFrameTextureBoss, enemyBody.getPosition().x - ((enemySheet.getWidth() / 3) / 2), enemyBody.getPosition().y - 70);
        }else{
            batch.draw(currentFrameTexture, enemyBody.getPosition().x - ((enemySheet.getWidth() / 3) / 2), enemyBody.getPosition().y - 70);
            enemyRise = 0.001f;
        }
        stateTime += Gdx.graphics.getDeltaTime();

        restore();
        enemyBody.setLinearVelocity(speed, 0);
        enemyDensity = enemyDensity + enemyRise;

        currentFrameTexture = walkAnimation.getKeyFrame(stateTime, true);
        currentFrameTextureBoss = walkAnimationBoss.getKeyFrame(stateTime, true);
    }

    /**
     * Get correct frames from large sheet picture.
     *
     * @param tr Texture region table
     * @param cols Columns of the sheet
     * @param rows Rows of the sheet
     * @return correct frames
     */
    public static TextureRegion[] toTextureArray(TextureRegion[][] tr, int cols, int rows) {
        TextureRegion[] frames = new TextureRegion[cols * rows];

        int index = 0;
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                frames[index++] = tr[i][j];
            }
        }

        return frames;
    }

    /**
     * Returns correct position of the enemy's body.
     * @return position of enemy
     */
    public float Location(){
        return enemyBody.getPosition().x;
    }

    /**
     * Resets enemy location, speed, density and velocity.
     */
    public void Restart(){
        enemyBody.setTransform(x - ((enemySheet.getWidth()/3)/2), y, 0);
        enemyBody.setLinearVelocity(0,0);
        enemyBody.setAngularVelocity(0);
        speed = -40f;
        enemyDensity = 1f;
    }

    /**
     * Destroys enemy body so it can be created again in box2d world.
     */
    public void restore() {
        setEnemyPos();
        GameScreen.world.destroyBody(enemyBody);
        create();
        enemyBody.setLinearVelocity(speed, 0f);
    }

    /**
     * Create enemy body again needed for Density changes.
     */
    private void create(){
        enemyBodyDef = new BodyDef();

        // Dynamic / Static / Kinematic
        enemyBodyDef.type = BodyDef.BodyType.DynamicBody;
        enemyBodyDef.position.set(enemyPos, y);
        enemyBody = GameScreen.world.createBody(enemyBodyDef);

        enemyFixtureDef = new FixtureDef();
        enemyFixtureDef.density = enemyDensity;
        enemyFixtureDef.restitution = 0.0f;
        enemyFixtureDef.friction = 0.0f;

        PolygonShape enemyBox = new PolygonShape();
        enemyBox.setAsBox(55, 80);

        enemyFixtureDef.shape = enemyBox;
        enemyBody.createFixture(enemyFixtureDef);
        enemyBody.setFixedRotation(true);
        enemyBody.setUserData("enemy");

    }

    /**
     * Sets enemy position
     */
    private void setEnemyPos(){
        enemyPos = getPlayerPos();
    }

    /**
     * Gets enemy body position
     * @return enemy position.
     */
    public float getPlayerPos(){
        return enemyBody.getPosition().x;
    }

    public void dispose(){
        enemySheet.dispose();
        enemySheetBoss.dispose();
    }
}