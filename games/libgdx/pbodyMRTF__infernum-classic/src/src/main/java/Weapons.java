import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.Texture;


public class Weapons {
    private String gunTexturePath;
    private WeaponType type;
    private String name;
    private Texture texture;
    private Sound shootSound;
    private Float gunScale;
    private int fireRateTicks;
    private int bulletCount;
    private float bulletSpeed;
    private float bulletSpread;
    private boolean isAutomatic;

    
    public enum WeaponType {
        PISTOL,
        SHOTGUN,
        SMG
    }

    private void initializeWeapon() {
        switch (this.type) {
            case PISTOL:
                this.gunTexturePath = Assets.Textures.GUN;
                this.gunScale = Float.valueOf(1.0f);
                this.fireRateTicks = 16;
                this.bulletCount = 1;
                this.bulletSpeed = 800.0f;
                this.bulletSpread = 0.0f;
                this.isAutomatic = false;
                break;
            case SHOTGUN:
                this.gunTexturePath = Assets.Textures.SHOTGUN;
                this.gunScale = Float.valueOf(2.0f);
                this.fireRateTicks = 40;
                this.bulletCount = 8;
                this.bulletSpeed = 600.0f;
                this.bulletSpread = 15.0f;
                this.isAutomatic = false;
                break;
            case SMG:
                this.gunTexturePath = Assets.Textures.SMG;
                this.gunScale = Float.valueOf(1.5f);
                this.fireRateTicks = 3;
                this.bulletCount = 1;
                this.bulletSpeed = 900.0f;
                this.bulletSpread = 5.0f;
                this.isAutomatic = true;
                break;
        }
    }

    public Weapons(WeaponType type) {
        this.type = type;
        initializeWeapon();
    }

    public int getFireRateTicks() {
        return this.fireRateTicks;
    }

    public float getGunScale() {
        return this.gunScale.floatValue();
    }

    public String getGunTexturePath() {
        return this.gunTexturePath;
    }

    public int getBulletCount() {
        return this.bulletCount;
    }

    public float getBulletSpread() {
        return this.bulletSpread;
    }

    public boolean isAutomatic() {
        return this.isAutomatic;
    }
}
