package DarkShark02.JustJump;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.Rectangle;

public class Spring {
    private final float x, y;
    private final float width, height;
    private final Rectangle bounds;
    private final Texture textureActive; // Texture per la molla attiva (es. "spring_out.png")
    private final Texture textureInactive; // Texture per la molla inattiva (es. "spring.png")
    private boolean active;

    private float activeTimer; // Timer per quanto tempo la molla rimane attiva
    private final float ACTIVE_DURATION = 0.2f; // Durata in secondi della molla attiva (puoi aggiustarla)

    public Spring(float x, float y, float width, float height, Texture textureInactive, Texture textureActive) {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.bounds = new Rectangle(x, y, width, height);
        this.textureInactive = textureInactive;
        this.textureActive = textureActive;
        this.active = false;
        this.activeTimer = 0; // Inizia inattiva
    }

    // Metodo update per gestire il timer della molla
    public void update(float deltaTime) {
        if (active) {
            activeTimer -= deltaTime;
            if (activeTimer <= 0) {
                deactivate(); // Disattiva la molla quando il timer scade
            }
        }
    }

    public void draw(SpriteBatch batch, float stateTime, Animation<TextureRegion> springAnimation) {
        // Puoi usare l'animazione della molla se ne hai una, altrimenti usa le texture fisse
        if (active) {
            // Se usi un'animazione per la molla attiva, potresti voler usare springAnimation qui
            // Ad esempio: batch.draw(springAnimation.getKeyFrame(stateTime), x, y, width, height);
            batch.draw(textureActive, x, y, width, height); // Per ora, usiamo la texture fissa
        } else {
            batch.draw(textureInactive, x, y, width, height);
        }
    }

    public void activate() {
        active = true;
        activeTimer = ACTIVE_DURATION; // Avvia il timer quando la molla è attivata
    }

    public void deactivate() {
        active = false;
        activeTimer = 0;
    }

    public boolean isActive() {
        return active;
    }

    public Rectangle getRect() {
        return bounds;
    }

    public void dispose() {
        // Non disporre le texture qui se sono caricate una sola volta in JustJumpGame
        // e passate come riferimento. Se le carichi in ogni istanza di Spring, allora disponile qui.
        // textureActive.dispose();
        // textureInactive.dispose();
    }
}