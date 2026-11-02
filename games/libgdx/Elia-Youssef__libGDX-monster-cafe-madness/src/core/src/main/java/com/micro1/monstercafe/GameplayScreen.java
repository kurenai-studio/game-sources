package com.micro1.monstercafe;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer.ShapeType;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.ScreenUtils;

/**
 * The Gameplay screen and the core service loop. Draws the café ({@code cafe_background.png}), the chef near
 * the bottom behind the counter, the single active monster in the customer area, the requested-food order
 * bubble above the monster, the three serving-area food buttons, the score panel with live score, and the
 * happiness bar. Clicking a food button calls {@link CafeSession#serve(FoodType)}; a win or loss transitions
 * to the Victory or Game Over screen. All rules live in {@link CafeSession}; this screen is view + input.
 */
public class GameplayScreen extends BaseScreen {

    private static final Color CREAM = new Color(0.98f, 0.93f, 0.78f, 1f);
    private static final Color DARK = new Color(0.15f, 0.09f, 0.18f, 1f);
    private static final Color TRACK = new Color(0.26f, 0.20f, 0.30f, 1f);
    private static final Color HAPPY_GREEN = new Color(0.35f, 0.75f, 0.25f, 1f);
    private static final Color HAPPY_YELLOW = new Color(0.98f, 0.78f, 0.20f, 1f);
    private static final Color HAPPY_RED = new Color(0.86f, 0.24f, 0.16f, 1f);

    // Layout (world coordinates, y-up, 1280x720).
    private static final float CHEF_CX = 205f, CHEF_CY = 165f, CHEF_W = 300f;
    private static final float MONSTER_CX = 640f, MONSTER_CY = 382f, MONSTER_W = 300f;
    private static final float BUBBLE_CX = 640f, BUBBLE_CY = 566f, BUBBLE_W = 164f, BUBBLE_H = 168f;
    private static final float FOOD_H = 150f, FOOD_CY = 132f;
    private static final float[] FOOD_CX = {490f, 690f, 890f};
    private static final float PANEL_CX = 152f, PANEL_CY = 636f, PANEL_W = 250f;
    private static final float HP_X = 985f, HP_Y = 655f, HP_W = 260f, HP_H = 26f, HP_LABEL_CX = 1115f;

    private final CafeSession session = new CafeSession();
    private final FoodType[] foodOrder = {FoodType.BURGER, FoodType.CUPCAKE, FoodType.POTION};
    private final SpriteButton[] foodButtons = new SpriteButton[3];
    private final Vector2 touch = new Vector2();

    public GameplayScreen(MonsterCafeGame game) {
        super(game);
        for (int i = 0; i < 3; i++) {
            foodButtons[i] = new SpriteButton(game.assets.food(foodOrder[i]))
                    .setCenteredByHeight(FOOD_CX[i], FOOD_CY, FOOD_H);
        }
    }

    @Override
    public void render(float delta) {
        // Input: a click on a food button serves it; a win/loss transitions immediately.
        if (session.isPlaying() && Gdx.input.justTouched()) {
            worldTouch(touch);
            for (int i = 0; i < foodButtons.length; i++) {
                if (foodButtons[i].contains(touch.x, touch.y)) {
                    CafeSession.ServeResult r = session.serve(foodOrder[i]);
                    if (r == CafeSession.ServeResult.WIN) {
                        game.setScreen(new VictoryScreen(game, session.getScore()));
                        return;
                    }
                    if (r == CafeSession.ServeResult.LOSE) {
                        game.setScreen(new GameOverScreen(game, session.getScore()));
                        return;
                    }
                    break; // one food per click
                }
            }
        }

        ScreenUtils.clear(0f, 0f, 0f, 1f);
        game.viewport.apply();
        game.batch.setProjectionMatrix(game.viewport.getCamera().combined);
        game.shapes.setProjectionMatrix(game.viewport.getCamera().combined);

        // Batch phase A: background + sprites drawn behind the UI shapes.
        game.batch.begin();
        game.batch.draw(game.assets.cafeBackground, 0f, 0f,
                MonsterCafeGame.WORLD_WIDTH, MonsterCafeGame.WORLD_HEIGHT);
        drawRegionByWidth(game.assets.chef, CHEF_CX, CHEF_CY, CHEF_W);
        drawRegionByWidth(game.assets.monster(session.getCurrentMonster()), MONSTER_CX, MONSTER_CY, MONSTER_W);
        for (SpriteButton b : foodButtons) {
            b.draw(game.batch);
        }
        drawRegionByWidth(game.assets.scorePanel, PANEL_CX, PANEL_CY, PANEL_W);
        game.batch.end();

        // Shapes phase: the order bubble panel and the happiness bar (drawn under their labels).
        game.shapes.begin(ShapeType.Filled);
        // Order bubble: a speech-bubble tail pointing down at the monster, then the panel over it.
        float bubbleBottom = BUBBLE_CY - BUBBLE_H / 2f;
        game.shapes.setColor(DARK);
        game.shapes.triangle(BUBBLE_CX - 22f, bubbleBottom + 6f, BUBBLE_CX + 22f, bubbleBottom + 6f, BUBBLE_CX, bubbleBottom - 30f);
        game.shapes.setColor(CREAM);
        game.shapes.triangle(BUBBLE_CX - 15f, bubbleBottom + 6f, BUBBLE_CX + 15f, bubbleBottom + 6f, BUBBLE_CX, bubbleBottom - 22f);
        borderedRect(BUBBLE_CX - BUBBLE_W / 2f, BUBBLE_CY - BUBBLE_H / 2f, BUBBLE_W, BUBBLE_H, DARK, CREAM, 4f);
        // happiness track + fill
        game.shapes.setColor(DARK);
        game.shapes.rect(HP_X - 3f, HP_Y - 3f, HP_W + 6f, HP_H + 6f);
        game.shapes.setColor(TRACK);
        game.shapes.rect(HP_X, HP_Y, HP_W, HP_H);
        game.shapes.setColor(happinessColor(session.getHappiness()));
        game.shapes.rect(HP_X, HP_Y, HP_W * session.getHappiness() / 100f, HP_H);
        game.shapes.end();

        // Batch phase B: text + the order-food icon on top of their shapes.
        game.batch.begin();
        drawRegionByWidth(game.assets.food(session.getRequestedFood()), BUBBLE_CX, BUBBLE_CY - 14f, 88f);
        drawCentered(game.hudFont, "ORDER", BUBBLE_CX, BUBBLE_CY + BUBBLE_H / 2f - 12f, DARK);
        drawCenteredBoth(game.hudFont, String.valueOf(session.getScore()), PANEL_CX, PANEL_CY - 6f, DARK);
        drawCentered(game.hudFont, "HAPPINESS", HP_LABEL_CX, HP_Y + HP_H + 22f, Color.WHITE);
        drawCenteredBoth(game.hudFont, session.getHappiness() + "%", HP_LABEL_CX, HP_Y + HP_H / 2f, Color.WHITE);
        game.batch.end();
    }

    private void borderedRect(float x, float y, float w, float h, Color border, Color fill, float b) {
        game.shapes.setColor(border);
        game.shapes.rect(x, y, w, h);
        game.shapes.setColor(fill);
        game.shapes.rect(x + b, y + b, w - 2f * b, h - 2f * b);
    }

    private static Color happinessColor(int happiness) {
        if (happiness >= 60) {
            return HAPPY_GREEN;
        }
        if (happiness >= 40) {
            return HAPPY_YELLOW;
        }
        return HAPPY_RED;
    }
}
