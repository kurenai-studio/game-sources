package com.micro1.shadowclash;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.Disposable;
import com.badlogic.gdx.utils.JsonReader;
import com.badlogic.gdx.utils.JsonValue;

import java.util.ArrayDeque;
import java.util.HashMap;
import java.util.Map;

/**
 * Loads the supplied duel_assets sheets (white background keyed to transparent) plus the arena
 * background, slices them with the shipped region tables, and builds the per-fighter animation set
 * and the shared effect / projectile clips. Everything the render layer needs, in one place.
 */
public final class Assets implements Disposable {

    private final Texture background, userTex, cpuTex;
    private final Array<Texture> isolatedFrames = new Array<Texture>();
    public final BitmapFont font = new BitmapFont();      // ~15px default Arial; scaled at draw time

    public final Map<String, Animation<TextureRegion>> player = new HashMap<String, Animation<TextureRegion>>();
    public final Map<String, Animation<TextureRegion>> cpu = new HashMap<String, Animation<TextureRegion>>();

    public Assets() {
        background = tex("background.png", Texture.TextureFilter.Linear);
        userTex = tex("user_sheet.png", Texture.TextureFilter.Nearest);
        cpuTex = tex("cpu_sheet.png", Texture.TextureFilter.Nearest);
        load("regions_user.json", "user_sheet.png", userTex, player);
        load("regions_cpu.json", "cpu_sheet.png", cpuTex, cpu);
        font.setUseIntegerPositions(false);
    }

    private static Texture tex(String path, Texture.TextureFilter filter) {
        // Animation frames sit close together on the supplied sheets. Disabling mipmaps prevents
        // neighbouring frames and guide lines from bleeding into a region at runtime.
        Texture t = new Texture(Gdx.files.internal(path), false);
        t.setFilter(filter, filter);
        return t;
    }

    public Texture background() { return background; }

    private void load(String jsonFile, String sheetFile, Texture tex,
                      Map<String, Animation<TextureRegion>> out) {
        Pixmap sheet = new Pixmap(Gdx.files.internal(sheetFile));
        JsonValue root = new JsonReader().parse(Gdx.files.internal(jsonFile));
        for (JsonValue anim = root.child; anim != null; anim = anim.next) {
            String key = anim.name;
            Array<TextureRegion> frames = new Array<TextureRegion>();
            for (JsonValue box = anim.child; box != null; box = box.next) {
                int x = box.getInt(0), y = box.getInt(1), w = box.getInt(2), h = box.getInt(3);
                frames.add(needsIsolation(key)
                    ? isolateMainSprite(sheet, x, y, w, h)
                    : new TextureRegion(tex, x, y, w, h));
            }
            if (frames.size == 0) continue;
            out.put(key, new Animation<TextureRegion>(frameDur(key), frames, playMode(key)));
        }
        sheet.dispose();
    }

    /**
     * The supplied sheets are presentation boards, not padded atlases: an extended hand or foot
     * can overlap the next frame's rectangle. For body-only clips, retain the largest connected
     * opaque shape so a neighbour never appears as a floating limb. Effects and guarded/special
     * poses deliberately contain separate energy shapes and therefore keep their original region.
     */
    private TextureRegion isolateMainSprite(Pixmap sheet, int sx, int sy, int w, int h) {
        int[] labels = new int[w * h];
        ArrayDeque<Integer> open = new ArrayDeque<Integer>();
        int nextLabel = 0;
        int largestLabel = 0;
        int largestSize = 0;

        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                int start = y * w + x;
                if (labels[start] != 0 || (sheet.getPixel(sx + x, sy + y) & 0xff) == 0) continue;

                int label = ++nextLabel;
                int size = 0;
                labels[start] = label;
                open.add(start);
                while (!open.isEmpty()) {
                    int pixel = open.removeFirst();
                    int px = pixel % w;
                    int py = pixel / w;
                    size++;
                    for (int ny = Math.max(0, py - 1); ny <= Math.min(h - 1, py + 1); ny++) {
                        for (int nx = Math.max(0, px - 1); nx <= Math.min(w - 1, px + 1); nx++) {
                            int neighbour = ny * w + nx;
                            if (labels[neighbour] == 0
                                && (sheet.getPixel(sx + nx, sy + ny) & 0xff) != 0) {
                                labels[neighbour] = label;
                                open.add(neighbour);
                            }
                        }
                    }
                }
                if (size > largestSize) {
                    largestSize = size;
                    largestLabel = label;
                }
            }
        }

        Pixmap clean = new Pixmap(w, h, Pixmap.Format.RGBA8888);
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                if (labels[y * w + x] == largestLabel) {
                    clean.drawPixel(x, y, sheet.getPixel(sx + x, sy + y));
                }
            }
        }
        Texture texture = new Texture(clean, false);
        texture.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
        clean.dispose();
        isolatedFrames.add(texture);
        return new TextureRegion(texture);
    }

    private static boolean needsIsolation(String key) {
        return key.equals("idle") || key.equals("walk") || key.equals("run")
            || key.equals("jump") || key.equals("crouch") || key.equals("backdash")
            || key.equals("jab") || key.equals("crouchjab") || key.equals("standkick")
            || key.equals("strongpunch") || key.equals("sweep") || key.equals("shadowblast")
            || key.equals("lighthit") || key.equals("heavyhit") || key.equals("launch")
            || key.equals("victory") || key.equals("defeat");
    }

    /** Look up an animation for a fighter, falling back to idle if a key is somehow missing. */
    public Animation<TextureRegion> anim(boolean isPlayer, String key) {
        Map<String, Animation<TextureRegion>> m = isPlayer ? player : cpu;
        Animation<TextureRegion> a = m.get(key);
        return a != null ? a : m.get("idle");
    }

    private static float frameDur(String key) {
        switch (key) {
            case "idle": return 0.13f;
            case "walk": return 0.08f;
            case "run": return 0.07f;
            case "jump": return 0.11f;
            case "crouch": return 0.13f;
            case "backdash": return 0.06f;
            case "jab": case "crouchjab": case "standkick": return 0.055f;
            case "strongpunch": case "sweep": case "uppercut": return 0.10f;
            case "shadowblast": return 0.10f;
            case "darkcharge": return 0.075f;
            case "spinslash": return 0.06f;
            case "standblock": case "crouchblock": return 0.12f;
            case "lighthit": return 0.10f;
            case "heavyhit": return 0.11f;
            case "launch": return 0.10f;
            case "victory": return 0.18f;
            case "defeat": return 0.16f;
            case "projectile": return 0.05f;
            default: return 0.06f; // fx_*
        }
    }

    private static Animation.PlayMode playMode(String key) {
        switch (key) {
            case "idle": case "walk": case "run": case "crouch":
            case "standblock": case "crouchblock": case "spinslash": case "projectile":
                return Animation.PlayMode.LOOP;
            default:
                return Animation.PlayMode.NORMAL; // attacks, reactions, jump, outcomes, fx
        }
    }

    @Override
    public void dispose() {
        background.dispose();
        userTex.dispose();
        cpuTex.dispose();
        for (Texture frame : isolatedFrames) frame.dispose();
        font.dispose();
    }
}
