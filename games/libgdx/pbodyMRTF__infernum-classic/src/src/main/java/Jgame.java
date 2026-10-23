import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Camera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.freetype.FreeTypeFontGenerator;
import java.util.Random;


public class Jgame extends Game {
    public Camera camera;
    public BitmapFont font;
    Random rnd = new Random();
    float renk1;
    float renk2;
    float renk3;
    public static String Version;

    @Override // com.badlogic.gdx.ApplicationListener
    public void create() {
        this.renk1 = this.rnd.nextFloat();
        this.renk2 = this.rnd.nextFloat() * 0.5f;
        this.renk3 = this.rnd.nextFloat();
        createFont();
        setScreen(new LoadingScreen(this));
        Version = "Classic 1.0(infernum beta1.2.1)";
    }

    private void createFont() {
        FreeTypeFontGenerator generator = new FreeTypeFontGenerator(Gdx.files.internal("fonts/font.otf"));
        FreeTypeFontGenerator.FreeTypeFontParameter param = new FreeTypeFontGenerator.FreeTypeFontParameter();
        param.size = 32;
        param.minFilter = Texture.TextureFilter.Linear;
        param.magFilter = Texture.TextureFilter.Linear;
        param.characters = "abcçdefgğhıijklmnoöprsştuüvwxyzABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVWXYZ0123456789.,:;!?()[]{}+-*/'|\" #<>";
        this.font = generator.generateFont(param);
        this.font.getData().setScale(1.0f);
        generator.dispose();
    }

    @Override // com.badlogic.gdx.Game, com.badlogic.gdx.ApplicationListener
    public void render() {
        super.render();
    }

    @Override // com.badlogic.gdx.Game, com.badlogic.gdx.ApplicationListener
    public void dispose() {
        if (this.font != null) {
            this.font.dispose();
        }
        Assets.dispose();
        super.dispose();
    }
}
