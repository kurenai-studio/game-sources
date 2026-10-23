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

public class Player {
    private Texture playerSheet;
    private Animation walkAnimation;
    private TextureRegion currentFrameTexture;

    private float stateTime;
    private float x = 0;
    private float y = 950f;
    private float speed = 40f;

    public float score = 0;
    public int scored = 0;

    private Body playerBody;

    FixtureDef playerFixtureDef;
    BodyDef playerBodyDef;

    private float playerPos = x;

    public float playerDensity = 1f;
    public float playerComboValue = 0f;

    /**
     * Create texture sheet for the player and calls creation of player body and animation
     */
    public Player(){
        playerSheet = new Texture("knight.png");
        createAnimation();
        createPlayerBody();
        playerBody.setLinearVelocity(speed,0f);
    }

    /**
     * Creates player body in the box2d world.
     */
    private void createPlayerBody(){
        playerBodyDef = new BodyDef();

        // Dynamic / Static / Kinematic
        playerBodyDef.type = BodyDef.BodyType.DynamicBody;
        playerBodyDef.position.set(x + ((playerSheet.getWidth()/3)/2), y);
        playerBody = GameScreen.world.createBody(playerBodyDef);

        playerFixtureDef = new FixtureDef();
        playerFixtureDef.density = 1.0f;
        playerFixtureDef.restitution = 0.0f;
        playerFixtureDef.friction = 0.0f;

        PolygonShape playerBox = new PolygonShape();
        playerBox.setAsBox(55,80);

        playerFixtureDef.shape = playerBox;
        playerBody.createFixture(playerFixtureDef);
        playerBody.setFixedRotation(true);
        playerBody.setUserData("player");
    }

    /**
     * Animates the player movement
     */
    public void createAnimation(){
        final int FRAME_COLS = 3;
        final int FRAME_ROWS = 1;

        int tileWidth = playerSheet.getWidth() / FRAME_COLS;
        int tileHeight = playerSheet.getHeight();

        // Create 2D array from the texture (REGIONS of a TEXTURE).
        TextureRegion [][] tmp = TextureRegion.split(playerSheet, tileWidth, tileHeight);

        // Transform the 2D array to 1D
        TextureRegion[] allFrames = toTextureArray(tmp, FRAME_COLS, FRAME_ROWS );

        walkAnimation = new Animation(3 / 30f, allFrames);
        currentFrameTexture = walkAnimation.getKeyFrame(stateTime, true);
    }

    /**
     * Updates player density when scored, also draw player texture on the screen.
     *
     * @param batch SpriteBatch is needed to draw texture
     */
    public void update(SpriteBatch batch) {
        batch.draw(currentFrameTexture, playerBody.getPosition().x - ((playerSheet.getWidth()/3)/2),playerBody.getPosition().y-70);
        stateTime += Gdx.graphics.getDeltaTime();

        restore();
        playerBody.setLinearVelocity(speed,0);
        if(scored == 1){
            playerDensity = playerDensity + (playerComboValue/2f);
            scored = 0;
        }
        currentFrameTexture = walkAnimation.getKeyFrame(stateTime, true);
    }

    /**
     *
     * @param tr Texture region table
     * @param cols Columns of the sheet
     * @param rows Rows of the sheet
     * @return correct frames
     */
    public static TextureRegion[] toTextureArray( TextureRegion [][]tr, int cols, int rows ) {
        TextureRegion [] frames = new TextureRegion[cols * rows];

        int index = 0;
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                frames[index++] = tr[i][j];
            }
        }
        return frames;
    }

    /**
     * Gets location of the player body in the box2d world.
     * @return player's body position
     */
    public float Location(){
        return playerBody.getPosition().x;
    }

    /**
     * Resets player position, speed, score etc.
     */
    public void Restart(){
        playerBody.setTransform(x + ((playerSheet.getWidth() / 3) / 2), y, 0);
        playerBody.setLinearVelocity(0, 0);
        playerBody.setAngularVelocity(0);
        score = 0;
        speed = 40f;
        playerDensity = 1f;
    }

    /**
     * Restores player state if density changes
     */
    public void restore(){
        setPlayerPos();
        GameScreen.world.destroyBody(playerBody);
        create();
    }

    /**
     * Create player body again with different density
     */
    public void create(){
        playerBodyDef = new BodyDef();

        // Dynamic / Static / Kinematic
        playerBodyDef.type = BodyDef.BodyType.DynamicBody;
        playerBodyDef.position.set(playerPos, y);
        playerBody = GameScreen.world.createBody(playerBodyDef);

        playerFixtureDef = new FixtureDef();
        playerFixtureDef.density = playerDensity;
        playerFixtureDef.restitution = 0.0f;
        playerFixtureDef.friction = 0.0f;

        PolygonShape playerBox = new PolygonShape();
        playerBox.setAsBox(55,80);

        playerFixtureDef.shape = playerBox;
        playerBody.createFixture(playerFixtureDef);
        playerBody.setFixedRotation(true);
        playerBody.setUserData("player");
    }

    /**
     * Setter for player position
     */
    private void setPlayerPos(){
        playerPos = getPlayerPos();
    }

    /**
     * Getter for player position.
     * @return player body position
     */
    public float getPlayerPos(){
        return playerBody.getPosition().x;
    }

    public void dispose(){
        playerSheet.dispose();
    }
}



