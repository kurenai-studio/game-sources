package DarkShark02.JustJump;

import java.util.ArrayList;
import java.util.Iterator;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.GL20; // Necessario per il debug delle hitbox
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.badlogic.gdx.utils.viewport.Viewport;

public class JustJumpGame extends ApplicationAdapter {
    // Definizione della telecamera e del viewport
    OrthographicCamera camera; // Telecamera per il mondo di gioco
    OrthographicCamera uiCamera; // Telecamera per l'interfaccia utente (HUD)
    Viewport viewport; 
    
    SpriteBatch batch;
    ShapeRenderer shapeRenderer;
    BitmapFont font;

    Animation<TextureRegion> walkAnimation, jumpAnimation, slipAnimation, hitAnimation;
    Animation<TextureRegion> springAnimation;

    float stateTime;

    Player player;
    LevelManager levelManager;

    // Liste per gli oggetti attivi nel livello
    ArrayList<Spike> activeSpikes;
    ArrayList<Star> activeStars;
    ArrayList<Heart> activeHearts;
    ArrayList<SnowPatch> activeSnowPatches;
    ArrayList<Spring> activeSprings;
    ArrayList<Bee> activeBees;

    // Texture di sfondo e UI
    Texture grass, dirt, sky;
    Texture heartUITexture;
    Texture halfHeartUITexture; // Texture per il cuore a metà
    Texture starIconTexture; // Texture per l'icona della stella UI

    // Costanti di gioco
    public static final float GROUND_Y = 50;
    public static final int TILE_SIZE = 64;
    // Queste SCREEN_WIDTH e SCREEN_HEIGHT ora rappresentano la DIMENSIONE DELLA TUA FINESTRA VIRTUALE,
    // ovvero quanto del mondo è visibile in un dato momento. NON più la larghezza totale del livello.
    public static final int SCREEN_WIDTH = 1600; // Larghezza della viewport virtuale
    public static final int SCREEN_HEIGHT = 900; // Altezza della viewport virtuale

    // Larghezza del mondo (Verrà aggiornata dal LevelManager in base al livello caricato)
    public float currentLevelWidth; 
    
    int rows = (int) (SCREEN_HEIGHT / TILE_SIZE); 
    
    int[][] backgroundTiles; // Matrice di sfondo inizializzata in resetGameForLevel

    int beesDefeated = 0;

    @Override
    public void create() {
        // --- Inizializzazione telecamera e viewport ---
        camera = new OrthographicCamera();
        viewport = new FitViewport(SCREEN_WIDTH, SCREEN_HEIGHT, camera);
        viewport.apply(); 
        
        // --- Inizializzazione UI Camera ---
        uiCamera = new OrthographicCamera();
        uiCamera.setToOrtho(false, SCREEN_WIDTH, SCREEN_HEIGHT); // (0,0) in basso a sinistra, dimensioni virtuali fisse
        uiCamera.update();
        // --- Fine inizializzazione telecamera e viewport ---

        batch = new SpriteBatch();
        shapeRenderer = new ShapeRenderer();
        font = new BitmapFont();
        font.getData().setScale(0.8f);

        // Inizializza le liste degli oggetti di gioco
        activeSpikes = new ArrayList<>();
        activeStars = new ArrayList<>();
        activeHearts = new ArrayList<>();
        activeSnowPatches = new ArrayList<>();
        activeSprings = new ArrayList<>();
        activeBees = new ArrayList<>();

        loadTextures();
        initializeAnimations();

        player = new Player(GROUND_Y);

        levelManager = new LevelManager(this);
        levelManager.loadCurrentLevel();
    }

    private void loadTextures() {
        grass = new Texture("background_solid_grass.png");
        dirt = new Texture("background_solid_dirt.png");
        sky = new Texture("background_solid_sky.png");
        heartUITexture = new Texture("hud_heart.png");
        halfHeartUITexture = new Texture("hud_heart_half.png"); // Carica la texture del mezzo cuore
        starIconTexture = new Texture("star.png"); 
    }

    private void initializeAnimations() {
        walkAnimation = new Animation<>(0.3f, new TextureRegion(new Texture("character_yellow_walk_a.png")), new TextureRegion(new Texture("character_yellow_walk_b.png")));
        walkAnimation.setPlayMode(Animation.PlayMode.LOOP);
        jumpAnimation = new Animation<>(0.3f, new TextureRegion(new Texture("character_yellow_jump.png")));
        slipAnimation = new Animation<>(0.3f, new TextureRegion(new Texture("character_yellow_duck.png")));
        hitAnimation = new Animation<>(0.5f, new TextureRegion(new Texture("character_yellow_hit.png")));

        springAnimation = new Animation<>(0.5f, new TextureRegion(new Texture("spring.png")));
    }

    public void resetGameForLevel(LevelData levelData) {
        player.reset();
        player.x = levelData.playerStartX;
        player.y = levelData.playerStartY;

        disposeCurrentLevelObjects(); // Dispone le texture degli oggetti del livello precedente

        activeSpikes.clear();
        activeStars.clear();
        activeHearts.clear();
        activeSnowPatches.clear();
        activeSprings.clear();
        activeBees.clear();

        beesDefeated = 0;
        
        // --- Imposta la larghezza del livello corrente dal LevelData ---
        currentLevelWidth = levelData.levelWidth; 
        // --- Fine modifica ---

        // Inizializza backgroundTiles basandosi sulla larghezza del livello
        int colsInLevel = (int) (currentLevelWidth / TILE_SIZE); 
        backgroundTiles = new int[rows][colsInLevel]; 

        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < colsInLevel; c++) { 
                if (r < rows - 3) {
                    backgroundTiles[r][c] = 2; // Sky
                } else {
                    backgroundTiles[r][c] = levelData.backgroundType; // 0=Grass, 1=Dirt
                }
            }
        }

        // Aggiungi oggetti dal LevelData alle liste attive
        for (LevelData.SpikeData sd : levelData.spikes) {
            activeSpikes.add(new Spike(sd.x, sd.y, 50, 15, new Texture("spikes.png")));
        }
        for (LevelData.HeartData hd : levelData.hearts) {
            activeHearts.add(new Heart(hd.x, hd.y, 40, 40, new Texture("heart.png")));
        }
        for (LevelData.StarData std : levelData.stars) {
            activeStars.add(new Star(std.x, std.y, 40, 40, new Texture("star.png")));
        }
        for (LevelData.SnowPatchData snd : levelData.snowPatches) {
            activeSnowPatches.add(new SnowPatch(snd.x, snd.y, snd.width, snd.height, new Texture("snow.png")));
        }
        for (LevelData.SpringData spd : levelData.springs) {
            activeSprings.add(new Spring(spd.x, spd.y, 50, 50, new Texture("spring.png"), new Texture("spring_out.png")));
        }
        for (LevelData.BeeData bd : levelData.bees) {
            activeBees.add(new Bee(bd.x, bd.y, bd.initialVelocityX));
        }
    }

    // Metodo per disporre le texture degli oggetti del livello precedente
    private void disposeCurrentLevelObjects() {
        for (Spike s : activeSpikes) s.dispose();
        for (Star s : activeStars) s.dispose();
        for (Heart h : activeHearts) h.dispose();
        for (SnowPatch s : activeSnowPatches) s.dispose();
        for (Spring s : activeSprings) s.dispose();
        for (Bee b : activeBees) b.dispose();
    }

    @Override
    public void render() {
        float delta = Gdx.graphics.getDeltaTime();
        stateTime += delta;

        if (!player.isGameOver) {
            player.handleInput(delta, (int) currentLevelWidth); // Passa la larghezza del livello al player
            player.update(delta);
            checkCollisions(delta);
            player.updateInvulnerability(delta);

            // --- Aggiorna la posizione della telecamera per seguire il player ---
            camera.position.x = MathUtils.clamp(player.x + player.getWidth() / 2, 
                                                SCREEN_WIDTH / 2, 
                                                currentLevelWidth - SCREEN_WIDTH / 2);
            camera.update(); 
            // --- Fine aggiornamento telecamera ---

            if (levelManager.getCurrentLevelData() != null && player.x >= levelManager.getCurrentLevelData().exitX) {
                levelManager.goToNextLevel();
            }

            updateBees(delta);
        } else if (Gdx.input.isKeyJustPressed(Input.Keys.R)) {
            levelManager.resetLevelIndex();
            levelManager.loadCurrentLevel();
            player.isGameOver = false;
        }

        drawGame();
    }

    private void updateBees(float deltaTime) {
        Iterator<Bee> iterator = activeBees.iterator();
        while (iterator.hasNext()) {
            Bee bee = iterator.next();
            bee.update(deltaTime);

            // Rimuovi l'ape se è fuori dallo schermo (a sinistra) VISIBILE, o se colpita e il timer è scaduto
            if (bee.x < camera.position.x - SCREEN_WIDTH / 2 - bee.getRect().width || (bee.isHit() && bee.getDespawnTimer() <= 0)) {
                bee.dispose();
                iterator.remove();
            }
        }
    }

    private void checkCollisions(float delta) {
        boolean playerIsInvulnerable = player.isInvulnerable();

        for (Spike spike : activeSpikes) {
            if (player.getRect().overlaps(spike.getRect()) && !playerIsInvulnerable) {
                player.takeDamage(0.5f);
            }
        }
        
        for (Heart heart : activeHearts) {
            // Controlla se il cuore non è già stato raccolto e se la vita del player non è al massimo
            if (player.getRect().overlaps(heart.getRect()) && !heart.isCollected() && player.currentHealth < player.MAX_HEALTH) {
                player.collectHeart();
                heart.setCollected(true);
            }
        }

        for (Star star : activeStars) {
            if (player.getRect().overlaps(star.getRect()) && !star.isCollected()) {
                player.collectStar();
                star.setCollected(true);
            }
        }

        boolean onAnySnowThisFrame = false;
        for (SnowPatch snowPatch : activeSnowPatches) {
            if (player.getFeetRect().overlaps(snowPatch.getRect())) {
                onAnySnowThisFrame = true;
                break;
            }
        }
        player.setOnSnow(onAnySnowThisFrame);

        for (Spring spring : activeSprings) {
            spring.update(delta);
            if (player.getRect().overlaps(spring.getRect()) && !spring.isActive()) {
                player.bounceSpring();
                spring.activate();
            }
        }

        for (Bee bee : activeBees) {
            if (!bee.isHit()) { 
                if (player.getRect().overlaps(bee.getRect())) {
                    if (player.isFallingOn(bee.getRect())) {
                        bee.hit();
                        beesDefeated++;
                        player.bounceOffEnemy();
                    } else if (!playerIsInvulnerable) {
                        player.takeDamage(1);
                    }
                }
            }
        }
    }

    private void drawGame() {
        Gdx.gl.glClearColor(0.1f, 0.1f, 0.1f, 1);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        // --- Disegno degli oggetti del mondo (seguono la telecamera) ---
        batch.setProjectionMatrix(camera.combined); 
        batch.begin();
        drawBackground(); 

        player.draw(batch, stateTime, walkAnimation, jumpAnimation, slipAnimation, hitAnimation);

        for (Spike s : activeSpikes) s.draw(batch);
        for (Star s : activeStars) { if (!s.isCollected()) s.draw(batch); }
        for (Heart h : activeHearts) { if (!h.isCollected()) h.draw(batch); }
        for (SnowPatch s : activeSnowPatches) s.draw(batch);
        for (Spring s : activeSprings) s.draw(batch, stateTime, springAnimation);
        for (Bee b : activeBees) b.draw(batch);

        // Visualizza l'icona della stella sopra il player se l'effetto è attivo
        if (player.hasStarEffect()) {
            batch.draw(starIconTexture, player.x + 20, player.y + player.getHeight(), 30, 30);
        }
        
        batch.end(); // Termina il batch per gli oggetti del mondo

        // --- Disegno dell'interfaccia utente (UI) (fissa sullo schermo) ---
        batch.setProjectionMatrix(uiCamera.combined); // Imposta la matrice di proiezione della UI Camera
        batch.begin(); // Inizia un nuovo batch per l'UI

        // Calcola la posizione iniziale x per allineare a destra.
        // SCREEN_WIDTH e SCREEN_HEIGHT sono le dimensioni della viewport virtuale della UI camera.
        // 40 è la dimensione stimata del cuore + spazio, 20 è un piccolo margine dal bordo.
        float heartUIStartX1 = 20; // 20 pixel di margine dal bordo sinistro

        for (int i = 0; i < player.MAX_HEALTH; i++) {
            Texture heartToDraw;
            
            if (player.currentHealth >= i + 1.0f) { 
                heartToDraw = heartUITexture;
            } else if (player.currentHealth > i && player.currentHealth < i + 1.0f) { 
                heartToDraw = halfHeartUITexture; 
            } else { 
                continue; 
            }
            
            // Disegna i cuori partendo da heartUIStartX
            // La posizione Y (SCREEN_HEIGHT - 50) è già corretta per metterli in alto
            batch.draw(heartToDraw, heartUIStartX1 + i * 40, SCREEN_HEIGHT - 50, 30, 30);
        }

        // Sposta anche il contatore delle api e la vita testuale
        font.draw(batch, "Bees Defeated: " + beesDefeated, heartUIStartX1, SCREEN_HEIGHT - 100); 
        font.draw(batch, "Health: " + String.format("%.1f", player.currentHealth), heartUIStartX1, SCREEN_HEIGHT - 150); 

        if (player.isGameOver) {
            // Centra il testo "GAME OVER" sullo schermo virtuale dell'UI
            String gameOverText = "GAME OVER! Press R to restart";
            com.badlogic.gdx.graphics.g2d.GlyphLayout layout = new com.badlogic.gdx.graphics.g2d.GlyphLayout(font, gameOverText);
            float textWidth = layout.width;
            font.draw(batch, gameOverText, (SCREEN_WIDTH - textWidth) / 2, SCREEN_HEIGHT / 2);
        }
        
        batch.end(); // Termina il batch per l'UI

        // --- DEBUG DELLE HITBOX (Mantenerlo attivo durante lo sviluppo) ---
        // Rimettere la proiezione della telecamera del mondo per il debug delle hitbox
        /*
        shapeRenderer.setProjectionMatrix(camera.combined); 
        shapeRenderer.begin(ShapeRenderer.ShapeType.Line);

        shapeRenderer.setColor(Color.RED);
        shapeRenderer.rect(player.getRect().x, player.getRect().y, player.getRect().width, player.getRect().height);
        
        shapeRenderer.setColor(Color.GREEN);
        shapeRenderer.rect(player.getFeetRect().x, player.getFeetRect().y, player.getFeetRect().width, player.getFeetRect().height);
        
        shapeRenderer.setColor(Color.BLUE);
        for (Bee bee : activeBees) {
            if (bee.getDespawnTimer() > 0) // Disegna solo se l'ape non è "morta"
                shapeRenderer.rect(bee.getRect().x, bee.getRect().y, bee.getRect().width, bee.getRect().height);
        }
        
        shapeRenderer.setColor(Color.YELLOW);
        for (Spike s : activeSpikes) shapeRenderer.rect(s.getRect().x, s.getRect().y, s.getRect().width, s.getRect().height);
        
        shapeRenderer.setColor(Color.CYAN);
        for (Heart h : activeHearts) {
            if (!h.isCollected())
                shapeRenderer.rect(h.getRect().x, h.getRect().y, h.getRect().width, h.getRect().height);
        }
        
        shapeRenderer.setColor(Color.MAGENTA);
        for (Star s : activeStars) {
            if (!s.isCollected())
                shapeRenderer.rect(s.getRect().x, s.getRect().y, s.getRect().width, s.getRect().height);
        }
        
        shapeRenderer.setColor(Color.GRAY);
        for (SnowPatch s : activeSnowPatches) shapeRenderer.rect(s.getRect().x, s.getRect().y, s.getRect().width, s.getRect().height);
        
        shapeRenderer.setColor(Color.ORANGE);
        for (Spring s : activeSprings) shapeRenderer.rect(s.getRect().x, s.getRect().y, s.getRect().width, s.getRect().height);

        shapeRenderer.end();
        */
    }

    private void drawBackground() {
        float startX = camera.position.x - (SCREEN_WIDTH / 2);
        int startCol = (int) (startX / TILE_SIZE);
        int endCol = (int) ((startX + SCREEN_WIDTH) / TILE_SIZE) + 1;
        
        // Assicurati di non andare fuori dai limiti della matrice backgroundTiles
        startCol = MathUtils.clamp(startCol, 0, backgroundTiles[0].length);
        endCol = MathUtils.clamp(endCol, 0, backgroundTiles[0].length);

        for (int r = 0; r < rows; r++) {
            for (int c = startCol; c < endCol; c++) { 
                Texture tile;
                switch (backgroundTiles[r][c]) {
                    case 0: tile = grass; break;
                    case 1: tile = dirt; break;
                    case 2: tile = sky; break;
                    default: tile = null; break;
                }
                if (tile != null) {
                    batch.draw(tile, c * TILE_SIZE, SCREEN_HEIGHT - (r + 1) * TILE_SIZE, TILE_SIZE, TILE_SIZE);
                }
            }
        }
    }

    @Override
    public void resize(int width, int height) {
        viewport.update(width, height, true); 
        // Se la tua UI Camera deve ridimensionarsi con la finestra, potresti voler aggiornarla qui.
        // Ad esempio: uiCamera.setToOrtho(false, width, height); uiCamera.update();
        // Ma con FitViewport e UI virtuale, è meglio lasciare SCREEN_WIDTH/HEIGHT per coerenza.
    }

    @Override
    public void pause() { }

    @Override
    public void resume() { }

    @Override
    public void dispose() {
        batch.dispose();
        shapeRenderer.dispose();
        font.dispose();

        grass.dispose();
        dirt.dispose();
        sky.dispose();
        heartUITexture.dispose();
        halfHeartUITexture.dispose(); // Disponi anche la texture del cuore a metà
        starIconTexture.dispose(); 

        // Disporre le texture delle animazioni del player
        if (walkAnimation.getKeyFrames().length > 0) {
            for (TextureRegion region : walkAnimation.getKeyFrames()) {
                if (region.getTexture() != null) region.getTexture().dispose();
            }
        }
        if (jumpAnimation.getKeyFrames().length > 0) {
            if (jumpAnimation.getKeyFrames()[0].getTexture() != null) jumpAnimation.getKeyFrames()[0].getTexture().dispose();
        }
        if (slipAnimation.getKeyFrames().length > 0) {
            if (slipAnimation.getKeyFrames()[0].getTexture() != null) slipAnimation.getKeyFrames()[0].getTexture().dispose();
        }
        if (hitAnimation.getKeyFrames().length > 0) {
            if (hitAnimation.getKeyFrames()[0].getTexture() != null) hitAnimation.getKeyFrames()[0].getTexture().dispose();
        }
        
        if (springAnimation.getKeyFrames().length > 0) {
            if (springAnimation.getKeyFrames()[0].getTexture() != null) springAnimation.getKeyFrames()[0].getTexture().dispose();
        }

        disposeCurrentLevelObjects(); // Dispone gli oggetti del livello corrente
    }
}