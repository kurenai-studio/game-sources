package ru.samsung.gamestudio.components;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.freetype.FreeTypeFontGenerator;

public class FontManager {

    private static final String FONT_PATH = "fonts/font.ttf";
    private static final String CYRILLIC_CHARS =
        "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя";

    private static final String[] SYSTEM_FONT_PATHS = {
        "/system/fonts/Roboto-Regular.ttf",
        "/system/fonts/NotoSans-Regular.ttf",
        "/system/fonts/DroidSans.ttf",
        "/system/fonts/NotoSerif-Regular.ttf",
        "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/Arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/TTF/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    };

    public static BitmapFont createFont(int size, Color color) {
        FileHandle fontFile = findFontFile();
        if (fontFile == null) {
            BitmapFont fallback = new BitmapFont();
            fallback.getData().setScale(size / 15f);
            fallback.setColor(color);
            return fallback;
        }
        FreeTypeFontGenerator generator = new FreeTypeFontGenerator(fontFile);
        FreeTypeFontGenerator.FreeTypeFontParameter params =
            new FreeTypeFontGenerator.FreeTypeFontParameter();
        params.size = size;
        params.color = color;
        params.characters = FreeTypeFontGenerator.DEFAULT_CHARS + CYRILLIC_CHARS;
        BitmapFont font = generator.generateFont(params);
        generator.dispose();
        return font;
    }

    private static FileHandle findFontFile() {
        FileHandle internal = Gdx.files.internal(FONT_PATH);
        if (internal.exists()) return internal;

        for (String path : SYSTEM_FONT_PATHS) {
            FileHandle system = Gdx.files.absolute(path);
            if (system.exists()) return system;
        }
        return null;
    }
}
