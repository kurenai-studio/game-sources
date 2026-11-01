package dev.luchoc.littlespaceship.game.ui;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.List;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.scenes.scene2d.ui.Slider;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.Drawable;
import com.badlogic.gdx.scenes.scene2d.utils.NinePatchDrawable;
import com.badlogic.gdx.graphics.g2d.NinePatch;

/**
 * The one {@link Skin} every screen shares, built in code instead of loaded from a {@code .json} +
 * atlas pair — {@code CLAUDE.md} asks for a Skin over a hand-rolled UI framework, not for a
 * particular loading mechanism, and there is nothing else to load: the panels and controls below are
 * flat colour and nine-patches, not art.
 *
 * <p><b>The real fonts.</b> {@code font-mini}/{@code font-title} are loaded from
 * {@code assets/fonts/*.fnt}, plain AngelCode text format, via the ordinary
 * {@code new BitmapFont(FileHandle)} constructor — no {@code FreeTypeFontGenerator}, no reflection,
 * per {@code docs/design/03-typography.md}. The {@code .fnt}/{@code .png} pair is generated, not
 * hand-authored, by {@code docs/design/fonts/build-fnt.js} from the hand-drawn sheets that document
 * describes; see that script's javadoc for why the {@code .fnt}'s metrics line is not optional.
 *
 * <p><b>The scale is 1, always.</b> Both sheets are already authored at the target size — 6x10 and
 * 8x13 cells, exactly {@code 03-typography.md}'s advance and line height — so any scale other than 1
 * would mean the sheets and the layout built around them have drifted apart. There is no whole-number
 * rounding step here the way there was for the placeholder default font: a mismatch should fail loud,
 * not get silently absorbed into a "close enough" integer multiple.
 */
public final class GameSkin {

    private GameSkin() {
    }

    public static Skin build() {
        Skin skin = new Skin();

        Texture pixel = solidTexture(0xFFFFFFFF);
        skin.add("white", new TextureRegion(pixel));

        BitmapFont fontMini = loadFont("font-mini");
        BitmapFont fontTitle = loadFont("font-title");

        skin.add("font-mini", fontMini, BitmapFont.class);
        skin.add("font-title", fontTitle, BitmapFont.class);

        // Stored explicitly under Drawable.class: Skin.add(name, resource) files a resource under
        // its own runtime class (NinePatchDrawable.class here), but Skin.getDrawable(name) looks it
        // up under the Drawable interface, so an implicit add is invisible to every getDrawable()
        // call and to every style field a .json skin would populate through it.
        // 60x12 minimum per 04-hud-layout.md's "Button plate" row — the nine-patch texture itself is
        // only 3x3, so without this every short label (BACK, QUIT) sized the button down to its own
        // text width instead of the document's floor.
        NinePatchDrawable n2Panel = ninePatch(Palette.N2, Palette.N3);
        n2Panel.setMinWidth(60f);
        n2Panel.setMinHeight(12f);
        skin.add("n2-panel", n2Panel, Drawable.class);
        skin.add("n1-panel", ninePatch(Palette.N1, Palette.N0), Drawable.class);

        Label.LabelStyle title = new Label.LabelStyle(fontTitle, Palette.N7);
        skin.add("title", title);

        Label.LabelStyle hudLabel = new Label.LabelStyle(fontMini, Palette.N4);
        skin.add("hud-label", hudLabel);

        Label.LabelStyle body = new Label.LabelStyle(fontMini, Palette.N4);
        skin.add("body", body);

        // N7, not N4: this is a value, the same convention HudRenderer uses for score and the
        // attachment label. N4 is for the surrounding label text, which is what "body" is for.
        Label.LabelStyle statValue = new Label.LabelStyle(fontMini, Palette.N7);
        skin.add("stat-value", statValue);

        TextButton.TextButtonStyle button = new TextButton.TextButtonStyle();
        button.font = fontMini;
        button.fontColor = Palette.N7;
        button.overFontColor = Palette.W4;
        button.downFontColor = Palette.W4;
        button.checkedFontColor = Palette.W4;
        button.disabledFontColor = Palette.N3;
        button.up = skin.getDrawable("n2-panel");
        button.down = skin.getDrawable("n2-panel");
        skin.add("default", button);

        Slider.SliderStyle slider = new Slider.SliderStyle();
        slider.background = new NinePatchDrawable(
            new NinePatch(new TextureRegion(pixel), 0, 0, 0, 0));
        slider.background.setMinHeight(3f);
        slider.knob = skin.newDrawable("white", Palette.N6);
        slider.knob.setMinWidth(5f);
        slider.knob.setMinHeight(9f);
        slider.knobBefore = skin.newDrawable("white", Palette.W4);
        skin.add("default-horizontal", slider);

        com.badlogic.gdx.scenes.scene2d.ui.CheckBox.CheckBoxStyle checkBox =
            new com.badlogic.gdx.scenes.scene2d.ui.CheckBox.CheckBoxStyle();
        checkBox.font = fontMini;
        checkBox.fontColor = Palette.N7;
        checkBox.checkboxOff = skin.newDrawable("white", Palette.N2);
        checkBox.checkboxOff.setMinWidth(9f);
        checkBox.checkboxOff.setMinHeight(9f);
        checkBox.checkboxOn = skin.newDrawable("white", Palette.W4);
        checkBox.checkboxOn.setMinWidth(9f);
        checkBox.checkboxOn.setMinHeight(9f);
        skin.add("default", checkBox);

        List.ListStyle list = new List.ListStyle();
        list.font = fontMini;
        list.fontColorUnselected = Palette.N4;
        list.fontColorSelected = Palette.W4;
        list.selection = skin.newDrawable("white", Palette.N2);
        skin.add("default", list);

        return skin;
    }

    private static BitmapFont loadFont(String name) {
        FileHandle fontFile = Gdx.files.internal("fonts/" + name + ".fnt");
        BitmapFont font = new BitmapFont(fontFile);
        font.getRegion().getTexture().setFilter(
            Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
        font.setUseIntegerPositions(true);
        return font;
    }

    private static NinePatchDrawable ninePatch(Color fill, Color border) {
        Pixmap pm = new Pixmap(3, 3, Pixmap.Format.RGBA8888);
        pm.setColor(border);
        pm.fill();
        pm.setColor(fill);
        pm.fillRectangle(1, 1, 1, 1);
        Texture texture = new Texture(pm);
        texture.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
        pm.dispose();
        return new NinePatchDrawable(new NinePatch(texture, 1, 1, 1, 1));
    }

    private static Texture solidTexture(int rgba8888) {
        Pixmap pixmap = new Pixmap(1, 1, Pixmap.Format.RGBA8888);
        pixmap.setColor(new Color((int) ((rgba8888 >>> 24) & 0xFF) / 255f,
            ((rgba8888 >>> 16) & 0xFF) / 255f, ((rgba8888 >>> 8) & 0xFF) / 255f,
            (rgba8888 & 0xFF) / 255f));
        pixmap.fill();
        Texture texture = new Texture(pixmap);
        texture.setFilter(Texture.TextureFilter.Nearest, Texture.TextureFilter.Nearest);
        pixmap.dispose();
        return texture;
    }

}
