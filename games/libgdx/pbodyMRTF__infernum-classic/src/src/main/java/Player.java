
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Vector3;


public class Player {
    private Weapons currentWeapon;
    public float x;
    public float y;
    private Texture texture;
    private Texture gun;
    private static final float DEFAULT_SPEED = 1000.0f;
    private static final int MAX_HP = 3;
    private GameTickManager.TickTimer hitCooldown;
    public float speed = 1000.0f;
    public boolean dead = false;
    private int hp = 3;
    private Sound hitSound = Assets.getSound(Assets.Sounds.WOOD);

    public Player(float x, float y, Texture playerTexture, int controlScheme) {
        this.x = x;
        this.y = y;
        this.texture = playerTexture;
    }

    public void setHitCooldown(GameTickManager.TickTimer cooldown) {
        this.hitCooldown = cooldown;
    }

    public void update(float dt) {
        if (this.dead) {
            return;
        }
        float w = Gdx.graphics.getWidth();
        float h = Gdx.graphics.getHeight();
        handleMovement(dt);
        handleSwapping();
        clampToScreen(w, h);
    }

    private void handleSwapping() {
        if (Gdx.input.isKeyJustPressed(8)) {
            setWeapon(new Weapons(Weapons.WeaponType.PISTOL));
        }
        if (Gdx.input.isKeyJustPressed(9)) {
            setWeapon(new Weapons(Weapons.WeaponType.SHOTGUN));
        }
        if (Gdx.input.isKeyJustPressed(10)) {
            setWeapon(new Weapons(Weapons.WeaponType.SMG));
        }
    }

    private void handleMovement(float dt) {
        if (Gdx.input.isKeyPressed(51)) {
            this.y += this.speed * dt;
        }
        if (Gdx.input.isKeyPressed(47)) {
            this.y -= this.speed * dt;
        }
        if (Gdx.input.isKeyPressed(29)) {
            this.x -= this.speed * dt;
        }
        if (Gdx.input.isKeyPressed(32)) {
            this.x += this.speed * dt;
        }
    }

    private void clampToScreen(float w, float h) {
        if (this.x < 0.0f) {
            this.x = 0.0f;
        }
        if (this.y < 0.0f) {
            this.y = 0.0f;
        }
        if (this.x > w - this.texture.getWidth()) {
            this.x = w - this.texture.getWidth();
        }
        if (this.y > h - this.texture.getHeight()) {
            this.y = h - this.texture.getHeight();
        }
    }

    public void damage(int amount) {
        if (this.dead) {
            return;
        }
        if (this.hitCooldown == null || !this.hitCooldown.isRunning()) {
            this.hitSound.play(0.9f);
            this.hp -= amount;
            if (this.hp <= 0) {
                this.hp = 0;
                this.dead = true;
            }
        }
    }

    public void draw(SpriteBatch batch) {
        batch.draw(this.texture, this.x, this.y);
    }

    public void drawGun(SpriteBatch batch) {
        if (this.dead || this.currentWeapon == null) {
            return;
        }
        float angle = getAngleToMouse();
        float scale = this.currentWeapon.getGunScale();
        batch.draw(this.gun, this.x + (this.texture.getWidth() / 15.0f), this.y + (this.texture.getHeight() / 2.0f), 0.0f, 0.0f, this.gun.getWidth(), this.gun.getHeight(), scale, scale, angle, 0, 0, this.gun.getWidth(), this.gun.getHeight(), false, false);
    }

    public float getAngleToMouse() {
        Vector3 mouse = new Vector3(Gdx.input.getX(), Gdx.input.getY(), 0.0f);
        mouse.y = Gdx.graphics.getHeight() - mouse.y;
        return (float) Math.toDegrees(Math.atan2(mouse.y - (this.y + (this.texture.getHeight() / 2.0f)), mouse.x - (this.x + (this.texture.getWidth() / 2.0f))));
    }

    public void setWeapon(Weapons weapon) {
        this.currentWeapon = weapon;
        this.gun = Assets.getTexture(weapon.getGunTexturePath());
    }

    public float getCenterX() {
        return this.x + (this.texture.getWidth() / 2.0f);
    }

    public float getCenterY() {
        return this.y + (this.texture.getHeight() / 2.0f);
    }

    public void resetSpeed() {
        this.speed = 1000.0f;
    }

    public void slowDown(float slowSpeed) {
        this.speed = slowSpeed;
    }

    public boolean isDead() {
        return this.dead;
    }

    public Weapons getWeapon() {
        return this.currentWeapon;
    }

    public int getHp() {
        return this.hp;
    }

    public int getMaxHp() {
        return 3;
    }

    public Texture getTexture() {
        return this.texture;
    }

    public void dispose() {
    }
}
