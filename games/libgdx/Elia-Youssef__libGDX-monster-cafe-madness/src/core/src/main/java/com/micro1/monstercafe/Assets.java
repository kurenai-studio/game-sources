package com.micro1.monstercafe;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.Texture.TextureFilter;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.Disposable;
import java.util.EnumMap;

/**
 * Central asset loader + owner. Loads every runtime texture ONCE (from the supplied {@code assets/}
 * subfolders via relative internal paths, structure preserved) and exposes them. Each 1024x1536 sprite is
 * cropped to its measured opaque content box so the surrounding transparent padding does not affect on-screen
 * placement or click hit-testing; the two backgrounds are used whole. The four reference images are never
 * referenced here. {@link #dispose()} releases every native texture.
 */
public class Assets implements Disposable {

    /** Pixels added around each measured content box, so the coarse-scan measurement never clips the art. */
    private static final int CROP_MARGIN = 12;

    private final Array<Texture> allTextures = new Array<>();

    public final Texture menuBackground;
    public final Texture cafeBackground;

    public final TextureRegion playButton;
    public final TextureRegion retryButton;
    public final TextureRegion scorePanel;
    public final TextureRegion chef;

    private final EnumMap<MonsterType, TextureRegion> monsters = new EnumMap<>(MonsterType.class);
    private final EnumMap<FoodType, TextureRegion> foods = new EnumMap<>(FoodType.class);

    public Assets() {
        // Backgrounds (1536x1024, opaque) - used whole, stretched to fill the window by the screens.
        menuBackground = loadFull("backgrounds/menu_background.png");
        cafeBackground = loadFull("backgrounds/cafe_background.png");

        // UI + sprites (1024x1536, transparent padding) - cropped to measured content box (x, yFromTop, w, h).
        playButton = loadCropped("ui/play_button.png", 192, 480, 648, 456);
        retryButton = loadCropped("ui/retry_button.png", 180, 480, 690, 480);
        scorePanel = loadCropped("ui/score_panel.png", 108, 456, 816, 540);
        chef = loadCropped("characters/chef.png", 192, 408, 630, 750);

        monsters.put(MonsterType.GREEN, loadCropped("characters/monster_green.png", 186, 396, 708, 432));
        monsters.put(MonsterType.BLUE, loadCropped("characters/monster_blue.png", 180, 492, 702, 372));
        monsters.put(MonsterType.RED, loadCropped("characters/monster_red.png", 192, 480, 666, 384));

        foods.put(FoodType.BURGER, loadCropped("food/burger.png", 204, 270, 642, 708));
        foods.put(FoodType.CUPCAKE, loadCropped("food/cupcake.png", 252, 270, 558, 744));
        foods.put(FoodType.POTION, loadCropped("food/potion_drink.png", 264, 264, 504, 786));
    }

    public TextureRegion monster(MonsterType type) {
        return monsters.get(type);
    }

    public TextureRegion food(FoodType type) {
        return foods.get(type);
    }

    private Texture loadFull(String path) {
        Texture t = new Texture(Gdx.files.internal(path));
        t.setFilter(TextureFilter.Linear, TextureFilter.Linear);
        allTextures.add(t);
        return t;
    }

    private TextureRegion loadCropped(String path, int x, int y, int w, int h) {
        Texture t = loadFull(path);
        int cx = Math.max(0, x - CROP_MARGIN);
        int cy = Math.max(0, y - CROP_MARGIN);
        int cw = Math.min(t.getWidth(), x + w + CROP_MARGIN) - cx;
        int ch = Math.min(t.getHeight(), y + h + CROP_MARGIN) - cy;
        return new TextureRegion(t, cx, cy, cw, ch);
    }

    @Override
    public void dispose() {
        for (Texture t : allTextures) {
            t.dispose();
        }
        allTextures.clear();
    }
}
