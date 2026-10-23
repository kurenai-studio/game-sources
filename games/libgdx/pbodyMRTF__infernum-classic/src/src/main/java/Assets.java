import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.Texture;


public class Assets {
    private static AssetManager manager;

    


    
    public static class Sounds {
        public static final String SHOOT = "sfx/shot.mp3";
        public static final String POP = "sfx/pop.mp3";
        public static final String WOOD = "sfx/wood.mp3";
        public static final String CONFIRM = "sfx/confirm.ogg";
        public static final String SELECT = "sfx/select.ogg";
    }

    
    public static class Textures {
        public static final String PLAYER = "player64.png";
        public static final String GUN = "gun.png";
        public static final String SHOTGUN = "spas.png";
        public static final String SMG = "mp5.png";
        public static final String BULLET = "bullet8.png";
        public static final String ENEMY = "enemy.png";
        public static final String BLOOD = "particles/blood.png";
        public static final String HEART = "kalp.png";
        public static final String HEART_EMPTY = "kalp2.png";
    }

    public static void load() {
        manager = new AssetManager();
        manager.load(Textures.PLAYER, Texture.class);
        manager.load(Textures.GUN, Texture.class);
        manager.load(Textures.BULLET, Texture.class);
        manager.load(Textures.ENEMY, Texture.class);
        manager.load(Textures.BLOOD, Texture.class);
        manager.load(Textures.HEART, Texture.class);
        manager.load(Textures.HEART_EMPTY, Texture.class);
        manager.load(Textures.SHOTGUN, Texture.class);
        manager.load(Textures.SMG, Texture.class);
        manager.load(Sounds.SHOOT, Sound.class);
        manager.load(Sounds.POP, Sound.class);
        manager.load(Sounds.WOOD, Sound.class);
        manager.load(Sounds.CONFIRM, Sound.class);
        manager.load(Sounds.SELECT, Sound.class);
    }

    public static boolean update() {
        return manager.update();
    }

    public static float getProgress() {
        return manager.getProgress();
    }

    public static Texture getTexture(String path) {
        return (Texture) manager.get(path, Texture.class);
    }

    public static Sound getSound(String path) {
        return (Sound) manager.get(path, Sound.class);
    }

    public static Music getMusic(String path) {
        return (Music) manager.get(path, Music.class);
    }

    public static void dispose() {
        if (manager != null) {
            manager.dispose();
        }
    }

    public static boolean isLoaded() {
        return manager != null && manager.getProgress() >= 1.0f;
    }
}
