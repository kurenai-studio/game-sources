package com.elmagica.game;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;

public class MenuGuide {
    public static final int PAGE_COUNT = 6;
    public static final int TAB_STEP = 188;
    public static final int TAB_WIDTH = 170;
    private final ShapeRenderer shapes;
    private final SpriteBatch batch;
    private final BitmapFont font;
    private final MenuCover cover;
    public MenuGuide(ShapeRenderer shapes, SpriteBatch batch, BitmapFont font, MenuCover cover) {
        this.shapes = shapes; this.batch = batch; this.font = font;
        this.cover = cover;
    }

    private void text(String text, float x, float y, int scale, Color color) {
        text = GameText.tr(text);
        font.getData().setScale(scale);
        font.setColor(color);
        font.draw(batch, text, x, y);
    }
    private void center(String text, float x, float y, int scale, Color color) {
        text = GameText.tr(text);
        text(text, x - (text.length() * 6 - 1) * scale / 2, y, scale, color);
    }
    private void panel(float x, float y, float width, float height) {
        cover.panel(x, y, width, height);
    }

    public void drawControls() {
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        panel(180, 198, 920, 350);
        for (int i = 0; i < 7; i++) {
            shapes.setColor(0.15f, 0.12f, 0.21f, 1);
            shapes.rect(208, 478 - i * 46, 170, 36);
            shapes.setColor(0.30f, 0.23f, 0.32f, 1);
            shapes.rect(400, 475 - i * 46, 672, 1);
        }
        shapes.end();
        cover.heading("Управление", 638);
        batch.begin();
        String[] keys = {"WASD", "Курсор", "ЛКМ", "1 — 4", "ESC", "Мышь", "E"};
        String[] actions = {"Движение мага", "Направление заклинания", "Удерживать для автоатаки",
            "Выбор стихии после старта", "Меню паузы или назад", "Кнопки и карточки меню", "Купить товар или поговорить"};
        for (int i = 0; i < keys.length; i++) {
            text(keys[i], 224, 506 - i * 46, 2, new Color(1, 0.91f, 0.70f, 1));
            text(actions[i], 414, 506 - i * 46, 2, Color.WHITE);
        }
        center("Вначале 2 выстрела в секунду. Улучшения ускоряют атаку.", 640, 160, 2, Color.LIGHT_GRAY);
        batch.end();
    }

    public void drawMechanics(int page) {
        String[] tabs = {"Стихии", "Заклинания", "Враги", "Боссы", "Башня", "Торговец"};
        for (int i = 0; i < tabs.length; i++) {
            cover.drawButton(tabs[i], 84 + i * TAB_STEP, 560, TAB_WIDTH, 42, i == page, false);
        }
        shapes.begin(ShapeRenderer.ShapeType.Filled);
        panel(84, 100, 1110, 440);
        if (page != 0) {
            shapes.setColor(0.30f, 0.23f, 0.32f, 1);
            shapes.rect(639, 122, 2, 392);
        }
        if (page == 0) drawCircle();
        shapes.end();
        cover.heading("Механики", 660);
        batch.begin();
        if (page == 0) explainCircle();
        if (page == 1) explainSpells();
        if (page == 2) explainEnemies();
        if (page == 3) explainBosses();
        if (page == 4) explainTower();
        if (page == 5) explainMerchant();
        batch.end();
    }

    private void drawCircle() {
        ElementType[] order = {ElementType.WATER, ElementType.FIRE, ElementType.AIR, ElementType.EARTH};
        shapes.setColor(0.04f, 0.03f, 0.075f, 1);
        shapes.circle(350, 315, 195, 48);
        ring(194, new Color(0.50f, 0.35f, 0.18f, 1));
        ring(184, new Color(0.23f, 0.16f, 0.25f, 1));
        ring(92, new Color(0.50f, 0.35f, 0.18f, 1));
        ring(84, new Color(0.23f, 0.16f, 0.25f, 1));
        for (int i = 0; i < 16; i++) {
            float angle = i * 22.5f;
            float x = 350 + MathUtils.cosDeg(angle) * 179;
            float y = 315 + MathUtils.sinDeg(angle) * 179;
            shapes.setColor(0.70f, 0.49f, 0.25f, 1);
            shapes.rect(x - 2, y - 2, 4, 4);
        }
        // По часовой: вода, огонь, воздух, земля.
        for (int i = 0; i < 4; i++) {
            ElementType type = order[i];
            float angle = 90 - i * 90;
            shapes.setColor(type.color);
            for (int step = 0; step < 18; step++) {
                float a = angle - 19 - step * 3;
                float b = a - 3;
                shapes.rectLine(350 + MathUtils.cosDeg(a) * 150, 315 + MathUtils.sinDeg(a) * 150,
                    350 + MathUtils.cosDeg(b) * 150, 315 + MathUtils.sinDeg(b) * 150, 5);
            }
            float end = angle - 73;
            float tipX = 350 + MathUtils.cosDeg(end) * 150, tipY = 315 + MathUtils.sinDeg(end) * 150;
            float dx = MathUtils.sinDeg(end), dy = -MathUtils.cosDeg(end);
            shapes.triangle(tipX + dx * 9, tipY + dy * 9,
                tipX - dx * 9 - dy * 8, tipY - dy * 9 + dx * 8,
                tipX - dx * 9 + dy * 8, tipY - dy * 9 - dx * 8);
            float x = 350 + MathUtils.cosDeg(angle) * 150;
            float y = 315 + MathUtils.sinDeg(angle) * 150;
            shapes.setColor(0.88f, 0.65f, 0.32f, 1);
            shapes.circle(x, y, 43, 8);
            shapes.setColor(0.18f, 0.13f, 0.23f, 1);
            shapes.circle(x, y, 39, 8);
            shapes.setColor(type.color.r * 0.25f, type.color.g * 0.25f, type.color.b * 0.25f, 1);
            shapes.circle(x, y, 34, 8);
            shapes.setColor(type.color);
            if (type == ElementType.WATER) {
                shapes.circle(x, y - 8, 17, 16);
                shapes.triangle(x - 16, y - 1, x + 16, y - 1, x, y + 25);
            }
            if (type == ElementType.FIRE) {
                shapes.triangle(x - 22, y - 19, x + 22, y - 19, x + 3, y + 25);
                shapes.triangle(x - 20, y - 4, x - 4, y + 13, x - 18, y + 20);
                shapes.setColor(1, 0.7f, 0.3f, 1);
                shapes.triangle(x - 8, y - 19, x + 10, y - 19, x + 1, y + 6);
            }
            if (type == ElementType.EARTH) {
                shapes.triangle(x - 28, y - 16, x + 8, y - 16, x - 10, y + 21);
                shapes.triangle(x - 5, y - 16, x + 27, y - 16, x + 11, y + 9);
            }
            if (type == ElementType.AIR) {
                shapes.rect(x - 24, y + 12, 40, 5);
                shapes.rect(x - 10, y, 36, 5);
                shapes.rect(x - 24, y - 12, 29, 5);
                shapes.rect(x + 16, y + 8, 5, 9);
            }
        }
    }

    private void ring(float radius, Color color) {
        shapes.setColor(color);
        for (int i = 0; i < 48; i++) {
            float a = i * 7.5f;
            float b = a + 7.5f;
            shapes.rectLine(350 + MathUtils.cosDeg(a) * radius, 315 + MathUtils.sinDeg(a) * radius,
                350 + MathUtils.cosDeg(b) * radius, 315 + MathUtils.sinDeg(b) * radius, 2);
        }
    }

    private void explainCircle() {
        ElementType[] order = {ElementType.WATER, ElementType.FIRE, ElementType.AIR, ElementType.EARTH};
        for (int i = 0; i < 4; i++) {
            float angle = 90 - i * 90;
            float x = 350 + MathUtils.cosDeg(angle) * 150;
            float y = 315 + MathUtils.sinDeg(angle) * 150 - 52;
            // Выносим боковые подписи, чтобы не налезали на стрелки.
            if (i == 1) { x = 582; y = 322; }
            if (i == 3) { x = 126; y = 322; }
            center(order[i].label, x, y, 2, order[i].color);
        }
        center("Круг", 350, 335, 3, new Color(1, 0.91f, 0.70f, 1));
        center("стихий", 350, 306, 2, Color.LIGHT_GRAY);
        text("Кто кого бьёт", 660, 497, 3, Color.WHITE);
        text("По стрелке — сильный удар.", 660, 446, 2, Color.LIGHT_GRAY);
        text("Против стрелки — слабый.", 660, 414, 2, Color.LIGHT_GRAY);
        text("Стартовый урон мага", 660, 366, 2, Color.WHITE);
        text("Сильное: 20 урона", 660, 332, 2, Color.GREEN);
        text("Нейтральное: 10 урона", 660, 300, 2, Color.WHITE);
        text("Слабое: 5 урона", 660, 268, 2, Color.YELLOW);
        text("По магу: урон зависит от врага.", 660, 216, 2, Color.WHITE);
        text("Та же стихия и стихия напротив:", 660, 174, 2, Color.LIGHT_GRAY);
        text("обычный удар. У босса два типа.", 660, 148, 2, Color.LIGHT_GRAY);
    }

    private void explainSpells() {
        ElementType[] types = DamageSystem.PLAYER_ELEMENTS;
        String[][] lines = {
            {"Взрывается при попадании.", "Задевает врагов рядом с целью.", "Хорош против толпы."},
            {"Проходит сквозь первого врага.", "Может задеть ещё одного за ним.", "Выстраивай врагов в линию."},
            {"Отталкивает и ненадолго замедляет.", "Помогает держать врагов подальше.", "Босса отталкивает слабее."},
            {"Перескакивает на соседнего врага.", "Один выстрел — до двух целей.", "Хорош против врагов рядом."}
        };
        for (int i = 0; i < 4; i++) {
            float x = 110 + i % 2 * 555;
            float y = 505 - i / 2 * 205;
            text(types[i].label, x, y, 3, types[i].color);
            for (int line = 0; line < 3; line++) text(lines[i][line], x, y - 48 - line * 28, 2, Color.LIGHT_GRAY);
        }
    }

    private void explainEnemies() {
        text("Слизни", 110, 510, 3, ElementType.EARTH.color);
        text("30 ХП. Базовый урон: 2.", 110, 466, 2, Color.WHITE);
        text("Кусают и отпрыгивают. Живучие.", 110, 434, 2, Color.LIGHT_GRAY);
        text("Змеи", 110, 354, 3, ElementType.FIRE.color);
        text("20 ХП. Базовый урон: 3.", 110, 310, 2, Color.WHITE);
        text("Атакуют рывком без линии-подсказки.", 110, 278, 2, Color.LIGHT_GRAY);
        text("После рывка змея ненадолго замирает.", 110, 246, 2, Color.LIGHT_GRAY);
        text("Сильная стихия: урон x1,5.", 110, 180, 2, Color.WHITE);
        text("Слабая стихия: урон x0,5.", 110, 148, 2, Color.LIGHT_GRAY);
        text("Стрелки", 665, 510, 3, ElementType.WATER.color);
        text("12 ХП. Базовый урон: 4.", 665, 466, 2, Color.WHITE);
        text("Хрупкие, но больно стреляют.", 665, 434, 2, Color.LIGHT_GRAY);
        text("Целятся молча, потом выпускают болт.", 665, 402, 2, Color.LIGHT_GRAY);
        text("Урон округляется до целого.", 665, 370, 2, Color.LIGHT_GRAY);
        text("Появление врагов", 665, 300, 2, Color.WHITE);
        text("Врагов больше, но появляются частями.", 665, 264, 2, Color.LIGHT_GRAY);
        text("Спавн не ближе двух клеток от мага.", 665, 232, 2, Color.LIGHT_GRAY);
        text("Препятствия не пропускают тела и пули.", 665, 200, 2, Color.LIGHT_GRAY);
        text("Редко выпадает книга или зелье.", 665, 168, 2, Color.LIGHT_GRAY);
        text("Убил врага — приходит следующий.", 665, 136, 2, Color.LIGHT_GRAY);
    }

    private void explainBosses() {
        text("Две стихии. База: 180 ХП", 110, 510, 3, Color.WHITE);
        text("Каждый седьмой этаж — один босс.", 110, 466, 2, Color.LIGHT_GRAY);
        text("Победа: улучшение и полное лечение.", 110, 434, 2, Color.GREEN);
        text("Твой урон по двум стихиям", 110, 378, 2, Color.WHITE);
        text("Сильный + обычный: 20", 110, 344, 2, Color.LIGHT_GRAY);
        text("Два обычных: 10", 110, 316, 2, Color.LIGHT_GRAY);
        text("Сильный + слабый: 10", 110, 288, 2, Color.LIGHT_GRAY);
        text("Обычный + слабый: 5", 110, 260, 2, Color.LIGHT_GRAY);
        text("Базовый урон босса: 5", 110, 208, 2, Color.WHITE);
        text("Касание: 8 / 5 / 3 по двум стихиям.", 110, 176, 2, Color.LIGHT_GRAY);
        text("С этажами босс становится сильнее.", 110, 148, 2, Color.LIGHT_GRAY);
        text("Атаки обеих стихий", 665, 510, 3, Color.WHITE);
        text("Земля: две волны на 4-5 клеток.", 665, 466, 2, ElementType.EARTH.color);
        text("Вода: три залпа, в каждом три струи.", 665, 432, 2, ElementType.WATER.color);
        text("Огонь: широкий конус с разворотом.", 665, 398, 2, ElementType.FIRE.color);
        text("Воздух: 12 быстрых встречных спиралей.", 665, 364, 2, ElementType.AIR.color);
        text("На половине ХП — ярость", 665, 306, 2, Color.YELLOW);
        text("Атаки быстрее. Выходи из зоны удара.", 665, 272, 2, Color.LIGHT_GRAY);
        text("За победу растёт случайный стат мага.", 665, 232, 2, Color.WHITE);
        text("Редко: сильнее абилка или уклонение.", 665, 198, 2, Color.LIGHT_GRAY);
        text("Босс ускоряется, если ты далеко.", 665, 160, 2, Color.LIGHT_GRAY);
    }

    private void explainTower() {
        text("Всё выше", 110, 505, 3, Color.WHITE);
        text("Вход снизу, выход сверху.", 110, 456, 2, Color.LIGHT_GRAY);
        text("Победи всех — верхняя дверь откроется.", 110, 420, 2, Color.LIGHT_GRAY);
        text("Убил одного — приходит следующий.", 110, 384, 2, Color.LIGHT_GRAY);
        text("Запас: +1 враг каждые 3 этажа.", 110, 348, 2, Color.LIGHT_GRAY);
        text("На экране: +1 каждые 10 этажей.", 110, 312, 2, Color.LIGHT_GRAY);
        text("ХП, урон и темп врагов растут.", 110, 276, 2, Color.LIGHT_GRAY);
        text("Каждый 7-й этаж — босс без укрытий.", 110, 240, 2, Color.LIGHT_GRAY);
        text("После зачистки скорость мага x1,8.", 110, 204, 2, Color.LIGHT_GRAY);
        text("Весь оставшийся лут летит к магу.", 110, 168, 2, Color.LIGHT_GRAY);
        text("Находки и усиления", 665, 505, 3, Color.WHITE);
        text("Монеты: 50% — 1, 25% — 3, 25% — 0.", 665, 456, 2, Color.LIGHT_GRAY);
        text("С босса всегда падает 10-20 монет.", 665, 420, 2, Color.LIGHT_GRAY);
        text("Книга даёт случайное улучшение.", 665, 384, 2, Color.LIGHT_GRAY);
        text("Зелье лечит; при полных ХП исчезает.", 665, 348, 2, Color.LIGHT_GRAY);
        text("Босс даёт ап и полное лечение.", 665, 312, 2, Color.LIGHT_GRAY);
        text("Растут скорость, урон, ХП или атака.", 665, 276, 2, Color.LIGHT_GRAY);
        text("Редко: способность или уклонение.", 665, 240, 2, Color.LIGHT_GRAY);
        text("Красный урон сильный, серый слабый.", 665, 204, 2, Color.LIGHT_GRAY);
        text("Белый обычный; зелёный — лечение.", 665, 168, 2, Color.LIGHT_GRAY);
    }

    private void explainMerchant() {
        text("Передышка в башне", 110, 505, 3, Color.WHITE);
        text("Появляется только после 1-го босса.", 110, 456, 2, Color.LIGHT_GRAY);
        text("Один случайный этаж между боссами.", 110, 420, 2, Color.LIGHT_GRAY);
        text("В 5% промежутков — два визита.", 110, 384, 2, Color.LIGHT_GRAY);
        text("Два торговца никогда не идут подряд.", 110, 348, 2, Color.LIGHT_GRAY);
        text("Здесь нет врагов, выход уже открыт.", 110, 312, 2, Color.LIGHT_GRAY);
        text("Можно уйти без покупок.", 110, 276, 2, Color.LIGHT_GRAY);
        text("Подойди к торговцу и нажми E.", 110, 240, 2, Color.LIGHT_GRAY);
        text("Он поделится сомнительным советом.", 110, 204, 2, Color.LIGHT_GRAY);
        text("Три товара", 665, 505, 3, Color.WHITE);
        text("Подойди к пьедесталу и нажми E.", 665, 456, 2, Color.LIGHT_GRAY);
        text("Каждый товар покупается один раз.", 665, 420, 2, Color.LIGHT_GRAY);
        text("Обычно: два улучшения и зелье.", 665, 384, 2, Color.LIGHT_GRAY);
        text("Иногда вместо зелья — третий ап.", 665, 348, 2, Color.LIGHT_GRAY);
        text("Редко: ап способности или щит.", 665, 312, 2, Color.LIGHT_GRAY);
        text("Щит повышает шанс уклониться.", 665, 276, 2, Color.LIGHT_GRAY);
        text("Чем выше стат, тем дороже его ап.", 665, 240, 2, Color.LIGHT_GRAY);
        text("Цена зелья зависит от ХП и сложности.", 665, 204, 2, Color.LIGHT_GRAY);
    }
}
