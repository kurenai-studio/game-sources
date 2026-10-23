package net.zachwalker.eggsort.entities;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Interpolation;
import com.badlogic.gdx.utils.Align;
import com.badlogic.gdx.utils.TimeUtils;

import net.zachwalker.eggsort.util.Constants;
import net.zachwalker.eggsort.util.DrawingHelpers;

public class ScoreText {
    private BitmapFont font;
    private long comboVisibleTime;
    private int previousCombo;

    public ScoreText() {
        font = new BitmapFont(Gdx.files.internal(Constants.LABEL_FONT + ".fnt"),
                Gdx.files.internal(Constants.LABEL_FONT + ".png"), false);

        font.getRegion().getTexture().setFilter(Texture.TextureFilter.Linear, Texture.TextureFilter.Linear);
    }

    public void render(SpriteBatch batch, long currentScore, long highScore, int level, int combo) {

        if (currentScore > highScore) highScore = currentScore;

        font.setColor(Constants.LABEL_COLOR);

        //always draw the high score
        font.draw(
                batch,
                Long.toString(highScore),
                Constants.WORLD_WIDTH - Constants.LABEL_MARGIN,
                Constants.WORLD_HEIGHT - Constants.LABEL_MARGIN,
                0,
                Align.right,
                false
        );

        //always draw the current score
        font.draw(
                batch,
                Long.toString(currentScore),
                Constants.LABEL_SCORE_X,
                Constants.WORLD_HEIGHT - Constants.LABEL_MARGIN,
                0,
                Align.right,
                false
        );

        //always draw the level identifier
        String levelText = Constants.LEVEL_LABEL + level;
        font.draw(
                batch,
                levelText,
                Constants.LABEL_MARGIN,
                Constants.WORLD_HEIGHT - Constants.LABEL_MARGIN
        );

        //if the player has 2x or more combos, show the combo text with the current multiplier
        if (combo != previousCombo) {
            previousCombo = combo;
            comboVisibleTime = TimeUtils.nanoTime();
        }
        if (combo >= 2) {
            float alpha = 2.0f - Interpolation.pow2In.apply(DrawingHelpers.secondsSince(comboVisibleTime));
            font.setColor(Constants.LABEL_COLOR.r, Constants.LABEL_COLOR.g, Constants.LABEL_COLOR.b, alpha);
            font.draw(
                    batch,
                    combo + Constants.LABEL_COMBO,
                    Constants.WORLD_WIDTH / 2.0f,
                    Constants.WORLD_HEIGHT - Constants.LABEL_MARGIN,
                    0,
                    Align.center,
                    false
            );
        }
    }

    public void dispose() {
        font.dispose();
    }

}