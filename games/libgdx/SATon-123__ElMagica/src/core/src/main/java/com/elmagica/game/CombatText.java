package com.elmagica.game;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.utils.Array;

public class CombatText {
    public enum Kind { WEAK, NORMAL, STRONG, HEAL, DODGE, COIN }
    public static class Label {
        public final String text;
        public final Kind kind;
        public final float x, y;
        private float age;
        Label(String text, Kind kind, float x, float y) { this.text = text; this.kind = kind; this.x = x; this.y = y; }
    }
    private static CombatText current;
    public final Array<Label> labels = new Array<>();
    public CombatText() { current = this; }
    public static Kind damageKind(int matchup) {
        return matchup == 1 || matchup == 5 ? Kind.WEAK : matchup == 3 || matchup == 20 ? Kind.STRONG : Kind.NORMAL;
    }
    public static void add(String text, Kind kind, float x, float y) {
        if (current == null) return;
        if (current.labels.size >= 96) current.labels.removeIndex(0);
        // Раздвигаем свежие цифры, чтобы урон не закрывал хил.
        int nearby = 0;
        for (Label label : current.labels) {
            if (Math.abs(label.x - x) < 48 && Math.abs(label.y - y) < 90 && label.age < 0.45f) nearby++;
        }
        current.labels.add(new Label(text, kind, x + (nearby % 2) * 9, y + nearby * 24));
    }
    public void clear() { labels.clear(); }
    public void update(float delta) {
        for (int i = labels.size - 1; i >= 0; i--) {
            Label label = labels.get(i); label.age += delta;
            if (label.age >= 1.1f) labels.removeIndex(i);
        }
    }
    public static Color color(Kind kind) {
        switch (kind) {
            case WEAK: return new Color(0.6f, 0.63f, 0.68f, 1);
            case STRONG: return new Color(1, 0.27f, 0.22f, 1);
            case HEAL: return new Color(0.35f, 1, 0.48f, 1);
            case DODGE: return new Color(0.4f, 0.9f, 1, 1);
            case COIN: return new Color(1, 0.82f, 0.35f, 1);
            default: return Color.WHITE.cpy();
        }
    }
    public void draw(SpriteBatch batch, BitmapFont font) {
        for (Label label : labels) {
            String text = GameText.tr(label.text);
            float pop = Math.max(0, 1 - label.age / 0.18f);
            float scale = 2 + pop * 0.65f;
            float alpha = MathUtils.clamp((1.1f - label.age) / 0.3f, 0, 1);
            float x = label.x - (text.length() * 6 - 1) * scale / 2;
            float y = label.y + label.age * 40;
            font.getData().setScale(scale);
            font.setColor(0.025f, 0.015f, 0.05f, alpha);
            font.draw(batch, text, x - 1.5f, y); font.draw(batch, text, x + 1.5f, y);
            font.draw(batch, text, x, y - 1.5f); font.draw(batch, text, x, y + 1.5f);
            Color ink = color(label.kind); ink.a = alpha; font.setColor(ink);
            font.draw(batch, text, x, y);
        }
    }
    public void dispose() { clear(); if (current == this) current = null; }
}
