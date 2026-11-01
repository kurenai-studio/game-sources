package com.devcariri.submax;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.BitmapFontCache;
import com.badlogic.gdx.graphics.g2d.GlyphLayout;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Align;
import com.devcariri.submax.phases.Fase;

import java.util.ArrayList;

import static com.badlogic.gdx.net.HttpRequestBuilder.json;

/**
 * Created by RoNigga on 31/01/2017.
 */

public class Assets {

    public static Texture BACKGROUND;
    public static Texture BLANK;
    public static Texture HIVE_LOGO;
    public static Texture LIBGDX_LOGO;
    public static BitmapFont GGFont;

    public static Texture SQUARE_RELEASE;
    public static Texture SQUARE_PRESSED;

    public static ArrayList<Fase> FASES = json.fromJson(ArrayList.class, Fase.class,
            Gdx.files.internal("fases/fases.json"));;

    public static TextureRegion fixBleeding(TextureRegion region) {
        float x = region.getRegionX();
        float y = region.getRegionY();
        float width = region.getRegionWidth();
        float height = region.getRegionHeight();
        float invTexWidth = 1f / region.getTexture().getWidth();
        float invTexHeight = 1f / region.getTexture().getHeight();
        region.setRegion((x + .5f) * invTexWidth,
                (y + .5f) * invTexHeight,
                (x + width - .5f) * invTexWidth,
                (y + height - .5f) * invTexHeight);
        return region;
    }

    public static void drawCenteredString(SpriteBatch b, BitmapFont f,
                                          String text, Vector2 p)
    {
        GlyphLayout glyphLayout = new GlyphLayout();

        // Set text and font each time you want to calculate bounds.
        glyphLayout.setText(f, text);
        f.draw(b, glyphLayout, p.x + glyphLayout.width / 3, p.y + glyphLayout.height / 3);

    }

    public static void drawCenteredString(SpriteBatch b, BitmapFont f,
                                          String text, Vector2 p, float scale, boolean border)
    {
        Color bcol = Assets.GGFont.getColor();

        if(border) {
            int thick = 2; // espessura
            Assets.GGFont.setColor(bcol.cpy().sub(new Color(1,1,1,0)));
            f.draw(b, text, p.x, p.y);
            f.draw(b, text, p.x, p.y);
            f.draw(b, text, p.x, p.y);
            f.draw(b, text, p.x, p.y);

            f.draw(b, text, p.x, p.y);
            f.draw(b, text, p.x, p.y);
            f.draw(b, text, p.x, p.y);
            f.draw(b, text, p.x, p.y);
        }

        /****/

        Assets.GGFont.getData().setScale(2);
        Assets.GGFont.setFixedWidthGlyphs(text);
        Assets.GGFont.setColor(bcol);

        Assets.GGFont.getData().setScale(scale);

        BitmapFontCache fontCache;
        fontCache = new BitmapFontCache(Assets.GGFont);
        GlyphLayout layout = fontCache.setText(text, p.x, p.y, 0, Align.center, false);
        fontCache.draw(b);
    }

    public static void loadAssets() {

        SQUARE_RELEASE = new Texture(Gdx.files.internal("objects/sqb.png") );
        SQUARE_PRESSED = new Texture(Gdx.files.internal("objects/sqr.png"));
        //SQUARE_RELEASE = new Texture(Gdx.files.internal("objects/square_release.png") );
        //SQUARE_PRESSED = new Texture(Gdx.files.internal("objects/square_pressed.png"));
        //objects/square_pressed - objects/square_release
        HIVE_LOGO = new Texture( Gdx.files.internal("data/logo_hive.png") );
        LIBGDX_LOGO = new Texture( Gdx.files.internal("data/logo_libgdx.png") );

        //BACKGROUND = new Texture( Gdx.files.internal("data/background.png") );
        BACKGROUND = new Texture( Gdx.files.internal("data/background.jpg") );
        BLANK = new Texture( Gdx.files.internal("data/blank.png") );
        GGFont = new BitmapFont( Gdx.files.internal("fonts/ft04b.fnt"), Gdx.files.internal("fonts/ft04b_0.png"), false );

    }
}
