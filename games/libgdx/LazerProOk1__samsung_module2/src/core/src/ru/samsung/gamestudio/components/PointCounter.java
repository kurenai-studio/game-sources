package ru.samsung.gamestudio.components;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.BitmapFont;

public class PointCounter {

    int x, y;
    BitmapFont font;

    public PointCounter(int x, int y) {
        this.x = x;
        this.y = y;

        font = FontManager.createFont(64, Color.WHITE);
    }

    public void draw(Batch batch, int countOfPoints) {
        font.draw(batch, "Очки: " + countOfPoints, x, y);
    }

    public void drawBest(Batch batch, int bestScore) {
        font.draw(batch, "Рекорд: " + bestScore, x, y);
    }

    public void drawText(Batch batch, String text) {
        font.draw(batch, text, x, y);
    }

    public void dispose() {
        font.dispose();
    }

}
