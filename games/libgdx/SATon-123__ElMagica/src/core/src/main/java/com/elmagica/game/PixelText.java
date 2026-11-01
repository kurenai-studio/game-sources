package com.elmagica.game;

import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.TextureRegion;

public final class PixelText {
    private PixelText() {}

    public static BitmapFont createFont() {
        String letters = "";
        for (char letter = 32; letter <= 126; letter++) letters += letter;
        for (char letter = 'А'; letter <= 'я'; letter++) letters += letter;
        letters += "Ёё—";
        int rows = (letters.length() + 15) / 16;
        Pixmap picture = new Pixmap(128, rows * 10, Pixmap.Format.RGBA8888);
        picture.setColor(1, 1, 1, 1);
        BitmapFont.BitmapFontData data = new BitmapFont.BitmapFontData();
        data.lineHeight = 10;
        data.capHeight = 7;
        data.xHeight = 7;
        data.ascent = 0;
        data.descent = 0;
        data.down = -10;
        data.spaceXadvance = 6;

        for (int i = 0; i < letters.length(); i++) {
            char letter = letters.charAt(i);
            int x = i % 16 * 8 + 1;
            int y = i / 16 * 10 + 1;
            String[] pixels = glyph(letter).split("/");
            for (int row = 0; row < 7; row++) {
                for (int column = 0; column < 5; column++) {
                    if (pixels[row].charAt(column) == '1') picture.drawPixel(x + column, y + row);
                }
            }
            BitmapFont.Glyph fontLetter = new BitmapFont.Glyph();
            fontLetter.id = letter;
            fontLetter.srcX = x;
            fontLetter.srcY = y;
            fontLetter.width = 5;
            fontLetter.height = 7;
            fontLetter.xadvance = 6;
            fontLetter.yoffset = -7;
            data.setGlyph(letter, fontLetter);
        }
        Texture texture = new Texture(picture);
        texture.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
        picture.dispose();
        BitmapFont font = new BitmapFont(data, new TextureRegion(texture), true);
        font.setOwnsTexture(true);
        return font;
    }

    // Символы 5 на 7. Строчные рисуем так же, как заглавные.
    private static String glyph(char letter) {
        switch (Character.toUpperCase(letter)) {
            case 'А': case 'A': return "01110/10001/10001/11111/10001/10001/10001";
            case 'Б': return "11111/10000/10000/11110/10001/10001/11110";
            case 'В': case 'B': return "11110/10001/10001/11110/10001/10001/11110";
            case 'Г': return "11111/10000/10000/10000/10000/10000/10000";
            case 'Д': return "00110/01010/01010/01010/01010/11111/10001";
            case 'Е': case 'E': return "11111/10000/10000/11110/10000/10000/11111";
            case 'Ё': return "01010/00000/11111/10000/11110/10000/11111";
            case 'Ж': return "10101/10101/10101/01110/10101/10101/10101";
            case 'З': return "11110/00001/00001/01110/00001/00001/11110";
            case 'И': return "10001/10011/10011/10101/11001/11001/10001";
            case 'Й': return "01010/00100/10001/10011/10101/11001/10001";
            case 'К': case 'K': return "10001/10010/10100/11000/10100/10010/10001";
            case 'Л': return "00111/01001/01001/01001/01001/01001/10001";
            case 'М': case 'M': return "10001/11011/10101/10101/10001/10001/10001";
            case 'Н': case 'H': return "10001/10001/10001/11111/10001/10001/10001";
            case 'О': case 'O': return "01110/10001/10001/10001/10001/10001/01110";
            case 'П': return "11111/10001/10001/10001/10001/10001/10001";
            case 'Р': case 'P': return "11110/10001/10001/11110/10000/10000/10000";
            case 'С': case 'C': return "01111/10000/10000/10000/10000/10000/01111";
            case 'Т': case 'T': return "11111/00100/00100/00100/00100/00100/00100";
            case 'У': return "10001/10001/10001/01111/00001/00001/11110";
            case 'Ф': return "00100/01110/10101/10101/10101/01110/00100";
            case 'Х': case 'X': return "10001/10001/01010/00100/01010/10001/10001";
            case 'Ц': return "10010/10010/10010/10010/10010/11111/00001";
            case 'Ч': return "10001/10001/10001/01111/00001/00001/00001";
            case 'Ш': return "10101/10101/10101/10101/10101/10101/11111";
            case 'Щ': return "10101/10101/10101/10101/10101/11111/00001";
            case 'Ъ': return "11000/01000/01000/01110/01001/01001/01110";
            case 'Ы': return "10001/10001/10001/11001/10101/10101/11001";
            case 'Ь': return "10000/10000/10000/11110/10001/10001/11110";
            case 'Э': return "11110/00001/00001/01111/00001/00001/11110";
            case 'Ю': return "10010/10101/10101/11101/10101/10101/10010";
            case 'Я': return "01111/10001/10001/01111/00101/01001/10001";
            case 'D': return "11110/10001/10001/10001/10001/10001/11110";
            case 'F': return "11111/10000/10000/11110/10000/10000/10000";
            case 'G': return "01111/10000/10000/10111/10001/10001/01111";
            case 'I': return "01110/00100/00100/00100/00100/00100/01110";
            case 'J': return "00001/00001/00001/00001/10001/10001/01110";
            case 'L': return "10000/10000/10000/10000/10000/10000/11111";
            case 'N': return "10001/11001/11001/10101/10011/10011/10001";
            case 'Q': return "01110/10001/10001/10001/10101/10010/01101";
            case 'R': return "11110/10001/10001/11110/10100/10010/10001";
            case 'S': return "01111/10000/10000/01110/00001/00001/11110";
            case 'U': return "10001/10001/10001/10001/10001/10001/01110";
            case 'V': return "10001/10001/10001/10001/10001/01010/00100";
            case 'W': return "10001/10001/10001/10101/10101/10101/01010";
            case 'Y': return "10001/10001/01010/00100/00100/00100/00100";
            case 'Z': return "11111/00001/00010/00100/01000/10000/11111";
            case '0': return "01110/10001/10011/10101/11001/10001/01110";
            case '1': return "00100/01100/00100/00100/00100/00100/01110";
            case '2': return "01110/10001/00001/00010/00100/01000/11111";
            case '3': return "11110/00001/00001/01110/00001/00001/11110";
            case '4': return "00010/00110/01010/10010/11111/00010/00010";
            case '5': return "11111/10000/10000/11110/00001/00001/11110";
            case '6': return "01110/10000/10000/11110/10001/10001/01110";
            case '7': return "11111/00001/00010/00100/01000/01000/01000";
            case '8': return "01110/10001/10001/01110/10001/10001/01110";
            case '9': return "01110/10001/10001/01111/00001/00001/01110";
            case '-': case '—': return "00000/00000/00000/11111/00000/00000/00000";
            case '+': return "00000/00100/00100/11111/00100/00100/00000";
            case '>': return "10000/01000/00100/00010/00100/01000/10000";
            case '%': return "11001/11010/00010/00100/01000/01011/10011";
            case '_': return "00000/00000/00000/00000/00000/00000/11111";
            case '/': return "00001/00001/00010/00100/01000/10000/10000";
            case ':': return "00000/00100/00100/00000/00100/00100/00000";
            case '.': return "00000/00000/00000/00000/00000/00100/00100";
            case ',': return "00000/00000/00000/00000/00100/00100/01000";
            case '|': return "00100/00100/00100/00100/00100/00100/00100";
            case '!': return "00100/00100/00100/00100/00100/00000/00100";
            case '\'': return "00100/00100/01000/00000/00000/00000/00000";
            case '?': return "01110/10001/00001/00010/00100/00000/00100";
            case '(': return "00010/00100/01000/01000/01000/00100/00010";
            case ')': return "01000/00100/00010/00010/00010/00100/01000";
            default: return "00000/00000/00000/00000/00000/00000/00000";
        }
    }
}
