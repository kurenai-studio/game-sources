package DarkShark02.JustJump;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Rectangle;

public class Bee {
    public float x, y;
    public float velocityX;
    private final Rectangle rect; // Hitbox dell'ape
    private final Texture beeTextureA; // Texture per lo stato "vivo"
    private final Texture beeTextureRest; // Texture per lo stato "colpito/sconfitto"
    private boolean hit = false; // Indica se l'ape è stata colpita
    private float despawnTimer = 0.5f; // Timer per la scomparsa dopo essere stata colpita

    // Dimensioni visive del singolo frame dell'ape (assumendo che le texture siano 30x30)
    private final float BEE_VISUAL_WIDTH = 30;
    private final float BEE_VISUAL_HEIGHT = 30;

    // Offset per la hitbox dell'ape rispetto alla sua posizione di disegno (x, y)
    // Questi valori riducono le dimensioni della hitbox rispetto a quelle visive.
    private final float BEE_HITBOX_OFFSET_X_LEFT = 5; // Offset dal bordo sinistro visivo
    private final float BEE_HITBOX_OFFSET_X_RIGHT = 5; // Offset dal bordo destro visivo
    private final float BEE_HITBOX_OFFSET_Y_BOTTOM = 5; // Offset dal bordo inferiore visivo
    private final float BEE_HITBOX_OFFSET_Y_TOP = 5;   // Offset dal bordo superiore visivo


    public Bee(float x, float y, float velocityX) { // Rimosso width, height dal costruttore, usiamo BEE_VISUAL_WIDTH/HEIGHT
        this.x = x;
        this.y = y;
        this.velocityX = velocityX;
        
        // Calcola le dimensioni effettive della hitbox
        float hitboxWidth = BEE_VISUAL_WIDTH - BEE_HITBOX_OFFSET_X_LEFT - BEE_HITBOX_OFFSET_X_RIGHT;
        float hitboxHeight = BEE_VISUAL_HEIGHT - BEE_HITBOX_OFFSET_Y_BOTTOM - BEE_HITBOX_OFFSET_Y_TOP;

        // Inizializza la hitbox con gli offset corretti.
        // La hitbox parte da x + offset_left e y + offset_bottom.
        this.rect = new Rectangle(x + BEE_HITBOX_OFFSET_X_LEFT,
                                  y + BEE_HITBOX_OFFSET_Y_BOTTOM,
                                  hitboxWidth,
                                  hitboxHeight);
                                  
        beeTextureA = new Texture("bee_a.png"); // Texture per l'ape che vola
        beeTextureRest = new Texture("bee_rest.png"); // Texture per l'ape "stordita" o sconfitta
    }

    public void update(float delta) {
        if (!hit) {
            // Se l'ape non è stata colpita, si muove normalmente.
            x += velocityX * delta;
            // Aggiorna la posizione della hitbox. Ricorda gli offset!
            rect.setPosition(x + BEE_HITBOX_OFFSET_X_LEFT, y + BEE_HITBOX_OFFSET_Y_BOTTOM);
        } else {
            // Se l'ape è stata colpita, attiva il timer di scomparsa.
            despawnTimer -= delta;
        }
    }

    public void draw(SpriteBatch batch) {
        // Disegna l'ape solo se il timer di scomparsa è ancora attivo.
        if (despawnTimer > 0) {
            Texture currentBeeTexture = hit ? beeTextureRest : beeTextureA;
            batch.draw(currentBeeTexture, x, y, BEE_VISUAL_WIDTH, BEE_VISUAL_HEIGHT);
        }
    }

    // Metodo chiamato quando il player salta sopra l'ape.
    public void hit() {
        this.hit = true;
        this.velocityX = 0; // Ferma il movimento dell'ape quando viene colpita.
    }

    // Controlla se l'ape è stata colpita.
    public boolean isHit() {
        return hit;
    }

    // Restituisce il timer rimanente per la scomparsa.
    public float getDespawnTimer() {
        return despawnTimer;
    }

    // Restituisce la hitbox dell'ape.
    public Rectangle getRect() {
        return rect;
    }

    // Libera le risorse delle texture dell'ape.
    public void dispose() {
        beeTextureA.dispose();
        beeTextureRest.dispose();
    }
}