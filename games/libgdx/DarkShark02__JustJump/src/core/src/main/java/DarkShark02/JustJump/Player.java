package DarkShark02.JustJump;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.Rectangle;

public class Player {
    public float x;
    public float y;
    private final float width;
    private final float height;
    private float velocityX;
    private float velocityY;
    private final float gravity;
    private final float jumpStrength;
    private final float baseMoveSpeed; // Velocità di movimento base
    private float currentMoveSpeed; // Velocità di movimento attuale, influenzata dagli effetti
    private boolean isDucking;
    public boolean isGameOver;
    private boolean isOnGround;
    private boolean isOnSnow; // Determina se il player è sulla neve
    private boolean isJumping; // Indica se il player è attualmente in un salto avviato da input

    public float currentHealth;
    public final float MAX_HEALTH = 5;

    private float invulnerabilityTimer;
    private final float INVULNERABILITY_DURATION = 1.5f;

    public float starEffectTimer;
    private final float STAR_EFFECT_DURATION = 10.0f; // Durata dell'effetto stella
    private final float STAR_SPEED_MULTIPLIER = 1.5f; // Moltiplicatore di velocità per la stella

    private final Rectangle feetRect;
    private final float FEET_RECT_HEIGHT = 10;
    private final float FEET_RECT_WIDTH_MULTIPLIER = 0.7f;

    private final float PLAYER_OFFSET_HEIGHT = 25;
    private final float PLAYER_OFFSET_HEIGHT_DUCKING = 15;

    private boolean isSpringActive;
    private final float SPRING_BOUNCE_STRENGTH;
    private final float SPRING_BOUNCE_STRENGTH_DUCKING;

    private final float GROUND_TOLERANCE = 5.0f;

    public Player(float groundY) {
        this.width = 60;
        this.height = 100;
        this.x = 100;
        this.y = groundY;
        this.velocityX = 0;
        this.velocityY = 0;

        this.gravity = -1300;
        this.jumpStrength = 650;
        this.SPRING_BOUNCE_STRENGTH = 900;
        this.SPRING_BOUNCE_STRENGTH_DUCKING = 1100;

        this.baseMoveSpeed = 200;
        this.currentMoveSpeed = baseMoveSpeed;

        this.isDucking = false;
        this.isGameOver = false;
        this.isOnSnow = false; // Inizializzazione corretta
        this.isOnGround = true; // Inizia a terra
        this.isJumping = false; // Importante: Inizialmente non sta saltando

        this.currentHealth = MAX_HEALTH;
        this.invulnerabilityTimer = 0;
        this.starEffectTimer = 0;

        this.feetRect = new Rectangle(x + width * (1 - FEET_RECT_WIDTH_MULTIPLIER) / 2, y, width * FEET_RECT_WIDTH_MULTIPLIER, FEET_RECT_HEIGHT);
        
        this.isSpringActive = false;
    }

    public void handleInput(float deltaTime, int screenWidth) {
        // Usa currentMoveSpeed per il movimento orizzontale
        if (Gdx.input.isKeyPressed(Input.Keys.LEFT)) {
            velocityX = -currentMoveSpeed;
        } else if (Gdx.input.isKeyPressed(Input.Keys.RIGHT)) {
            velocityX = currentMoveSpeed;
        } else {
            velocityX = 0;
        }

        if (Gdx.input.isKeyJustPressed(Input.Keys.UP)) { 
            jump();
        }

        isDucking = Gdx.input.isKeyPressed(Input.Keys.DOWN);

        if (x < 0) {
            x = 0;
        }
        if (x + width > screenWidth) {
            x = screenWidth - width;
        }
    }

    public void update(float deltaTime) {
        // Applica gravità
        velocityY += gravity * deltaTime;
        
        // Aggiorna la posizione
        x += velocityX * deltaTime;
        y += velocityY * deltaTime;

        // Controllo contatto con il suolo più robusto
        if (y <= JustJumpGame.GROUND_Y + GROUND_TOLERANCE && velocityY <= 0) {
            y = JustJumpGame.GROUND_Y; // Forzalo esattamente sul suolo
            velocityY = 0; // Azzera la velocità verticale
            isOnGround = true; // È a terra
            isJumping = false; // Quando tocca terra, resetta lo stato di salto
            isSpringActive = false; // Resetta lo stato della molla
        } else {
            // Se è sopra il suolo o sta salendo
            isOnGround = false;
        }

        // Aggiorna la posizione del feetRect
        feetRect.setPosition(x + width * (1 - FEET_RECT_WIDTH_MULTIPLIER) / 2, y);

        // Aggiorna i timer
        if (invulnerabilityTimer > 0) {
            invulnerabilityTimer -= deltaTime;
            if (invulnerabilityTimer < 0) invulnerabilityTimer = 0;
        }
        
        // Logica della stella per influenzare la velocità
        if (starEffectTimer > 0) {
            starEffectTimer -= deltaTime;
            if (starEffectTimer < 0) {
                starEffectTimer = 0;
            }
            currentMoveSpeed = baseMoveSpeed * STAR_SPEED_MULTIPLIER; 
        } else {
            currentMoveSpeed = baseMoveSpeed;
        }

        // Se il player è sulla neve E la stella NON è attiva, rallenta.
        if (isOnSnow && !hasStarEffect()) {
            currentMoveSpeed = baseMoveSpeed * 0.5f;
        }
    }

    public void draw(SpriteBatch batch, float stateTime, Animation<TextureRegion> walkAnimation, Animation<TextureRegion> jumpAnimation, Animation<TextureRegion> slipAnimation, Animation<TextureRegion> hitAnimation) {
        TextureRegion currentFrame;

        if (isGameOver) {
            currentFrame = hitAnimation.getKeyFrame(stateTime);
        } else if (isDucking) {
            currentFrame = slipAnimation.getKeyFrame(stateTime);
        } else if (!isOnGround) { // Se NON è a terra, mostra l'animazione di salto
            currentFrame = jumpAnimation.getKeyFrame(stateTime);
        } else if (velocityX != 0) {
            currentFrame = walkAnimation.getKeyFrame(stateTime);
        } else {
            currentFrame = walkAnimation.getKeyFrame(0);
        }

        if (isInvulnerable() && (int)(stateTime * 10) % 2 == 0) {
            // Non disegnare per l'effetto lampeggiante
        } else {
            batch.draw(currentFrame, x, y, width, height);
        }
    }

    public void jump() {
        if (!isJumping) { 
            System.out.println("Puo anche saltare su ape"); 
            isOnGround = false; // Il player non è più a terra
            isJumping = true;   // Il player è ora in fase di salto

            if (isOnSnow && !hasStarEffect()){ 
                velocityY = jumpStrength / 4; 
            } else {
                velocityY = jumpStrength; 
            }
            Gdx.app.log("Player", "Jump initiated. current Y: " + y + ", velocityY: " + velocityY);
        }
    }

    public void bounceSpring() {
        isSpringActive = true;
        isOnGround = false;
        isJumping = true; 
        if (isDucking){
            velocityY = SPRING_BOUNCE_STRENGTH_DUCKING;
        } else {
            velocityY = SPRING_BOUNCE_STRENGTH;
        }
        Gdx.app.log("Player", "Spring bounce. current Y: " + y + ", velocityY: " + velocityY);
    }

    public void takeDamage(float damage) {
        if (!isInvulnerable()) {

            currentHealth -= damage;
            invulnerabilityTimer = INVULNERABILITY_DURATION;
            Gdx.app.log("Player", "Health: " + currentHealth);
            if (currentHealth <= 0) {
                isGameOver = true;
                Gdx.app.log("Player", "Game Over!");
            }
        }
    }

    public void collectHeart() {
        if (currentHealth < MAX_HEALTH) {
            currentHealth++;
            Gdx.app.log("Player", "Collected heart. Health: " + currentHealth);
        }
    }

    public void collectStar() {
        starEffectTimer = STAR_EFFECT_DURATION; // Avvia il timer
        currentMoveSpeed = baseMoveSpeed * STAR_SPEED_MULTIPLIER; // Imposta la velocità accelerata
        Gdx.app.log("Player", "Collected star! Star effect active. Speed: " + currentMoveSpeed);
    }

    // Setter per impostare lo stato isOnSnow dal JustJumpGame
    public void setOnSnow(boolean onSnow) {
        this.isOnSnow = onSnow;
    }

    // Il metodo onSnow() nel player non imposta più la velocità, ma può essere usato per effetti futuri
    public void onSnow() {
        // La logica di rallentamento è in update(). Questo metodo è qui per coerenza.
        Gdx.app.log("Player", "Player is on snow. Current speed: " + currentMoveSpeed + ", Star effect: " + hasStarEffect());
    }

    public void resetSpeed() {
        // Questo metodo ora imposta la velocità alla base. La logica della neve e della stella in update() la modificherà se necessario.
        currentMoveSpeed = baseMoveSpeed;
    }

    public void bounceOffEnemy() {
        velocityY = 400; // Imposta la forza di rimbalzo verso l'alto (regola questo valore!)
        isJumping = false; // Fondamentale: Resetta isJumping per permettere un nuovo input di salto
        isOnGround = false; // Il player non è a terra
        Gdx.app.log("Player", "Rimbalzo sull'ape!"); // Messaggio di debug (opzionale)
    }

    public void reset() {
        this.x = 100;
        this.y = JustJumpGame.GROUND_Y;
        this.velocityX = 0;
        this.velocityY = 0;
        this.isDucking = false;
        this.isGameOver = false;
        this.currentHealth = MAX_HEALTH;
        this.invulnerabilityTimer = 0;
        this.starEffectTimer = 0;
        this.currentMoveSpeed = baseMoveSpeed; // Resetta la velocità corrente alla base
        this.isSpringActive = false;
        this.isOnGround = true;
        this.isOnSnow = false; // FONDAMENTALE: Resetta isOnSnow a false
        this.isJumping = false; // Resetta isJumping
    }

    public Rectangle getRect() {
        float currentHeight = isDucking ? height * 0.5f : height;
        if (isDucking){
            return new Rectangle(x, y, width, currentHeight + PLAYER_OFFSET_HEIGHT_DUCKING);
        } else{
            return new Rectangle(x, y, width, currentHeight - PLAYER_OFFSET_HEIGHT);
        }
    }

    public Rectangle getFeetRect() {
        feetRect.setPosition(x + width * (1 - FEET_RECT_WIDTH_MULTIPLIER) / 2, y);
        return feetRect;
    }

    public boolean isFallingOn(Rectangle objectRect) {
        return velocityY < 0 && getFeetRect().overlaps(objectRect);
    }

    public void updateInvulnerability(float delta) {
        if (invulnerabilityTimer > 0) {
            invulnerabilityTimer -= delta;
            if (invulnerabilityTimer < 0) {
                invulnerabilityTimer = 0;
            }
        }
    }

    public boolean isInvulnerable() {
        return invulnerabilityTimer > 0;
    }

    public boolean hasStarEffect() {
        return starEffectTimer > 0;
    }

    public boolean isSpringActive() {
        return isSpringActive;
    }

    public float getWidth() { return width; }
    public float getHeight() { return height; }
}