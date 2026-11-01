package com.micro1.mooncourier;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.PixmapIO;

/**
 * QA-only helper that dumps the current back buffer to a PNG. Used solely by the offscreen
 * {@code --capture} path; it is never touched by a normal desktop run. The GL frame buffer origin is
 * bottom-left, so the read-back rows are flipped vertically to produce a correctly oriented image.
 */
public final class ScreenshotUtil {

    private ScreenshotUtil() {
    }

    public static void saveFrame(String path) {
        int w = Gdx.graphics.getBackBufferWidth();
        int h = Gdx.graphics.getBackBufferHeight();
        Pixmap raw = Pixmap.createFromFrameBuffer(0, 0, w, h);
        try {
            Pixmap flipped = new Pixmap(w, h, Pixmap.Format.RGBA8888);
            try {
                for (int y = 0; y < h; y++) {
                    for (int x = 0; x < w; x++) {
                        flipped.drawPixel(x, h - 1 - y, raw.getPixel(x, y));
                    }
                }
                FileHandle file = looksAbsolute(path) ? Gdx.files.absolute(path) : Gdx.files.local(path);
                PixmapIO.writePNG(file, flipped);
                Gdx.app.log("MoonCourier", "Saved capture: " + file.path());
            } finally {
                flipped.dispose();
            }
        } finally {
            raw.dispose();
        }
    }

    private static boolean looksAbsolute(String path) {
        return path != null && (path.startsWith("/") || (path.length() > 1 && path.charAt(1) == ':'));
    }
}
