package net.zachwalker.ballsort.overlays;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.utils.Align;
import net.zachwalker.ballsort.util.Constants;


public class Score {
    private BitmapFont font;

    public Score() {
        //font = new BitmapFont();
        font = new BitmapFont(Gdx.files.internal("consolas.fnt"), Gdx.files.internal("consolas.png"), false);
        font.getRegion().getTexture().setFilter(Texture.TextureFilter.Linear, Texture.TextureFilter.Linear);
    }

    public void render(SpriteBatch batch, long currentScore, long highScore, int level, int combo) {

        if (currentScore > highScore) highScore = currentScore;

        //always show the high score and current score
        String scoreText = Constants.SCORE_LABEL + currentScore + "\n"
                + Constants.HIGH_SCORE_LABEL + highScore;

        font.draw(
                batch,
                scoreText,
                Constants.WORLD_WIDTH - Constants.LABEL_MARGIN,
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
        if (combo >= 2) {
            String comboText = combo + Constants.COMBO_LABEL;
            font.draw(
                    batch,
                    comboText,
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
