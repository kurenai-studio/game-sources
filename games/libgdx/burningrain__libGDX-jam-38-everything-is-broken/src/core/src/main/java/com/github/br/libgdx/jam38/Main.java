package com.github.br.libgdx.jam38;

import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.assets.loaders.*;
import com.badlogic.gdx.assets.loaders.resolvers.InternalFileHandleResolver;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.ParticleEffect;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.graphics.g2d.freetype.FreetypeFontLoader;
import com.badlogic.gdx.maps.tiled.AtlasTmxMapLoader;
import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.maps.tiled.TmxMapLoader;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.github.br.libgdx.jam38.game.Constants;
import com.github.br.libgdx.jam38.game.UserFactoryImpl;
import com.github.br.libgdx.jam38.game.screens.Screens;
import com.github.br.libgdx.jam38.structure.AbstractSimpleGame;
import com.github.br.libgdx.jam38.structure.GameSettings;
import com.github.br.libgdx.jam38.structure.screen.statemachine.GameScreenState;
import com.github.tommyettinger.textra.FWSkinLoader;
import dev.lyze.gdxtinyvg.TinyVG;
import dev.lyze.gdxtinyvg.TinyVGAssetLoader;

/**
 * {@link com.badlogic.gdx.ApplicationListener} implementation shared by all platforms.
 */
public class Main extends AbstractSimpleGame<UserFactoryImpl> {

    @Override
    protected UserFactoryImpl createUserFactory() {
        return new UserFactoryImpl();
    }

    @Override
    protected GameScreenState createStartState() {
        return Screens.LEVEL_1;
    }

    @Override
    protected void initLoaders(AssetManager assetManager, InternalFileHandleResolver fileHandleResolver) {
        // ГРАФИКА
        assetManager.setLoader(Texture.class, new TextureLoader(fileHandleResolver));
        assetManager.setLoader(TextureAtlas.class, new TextureAtlasLoader(fileHandleResolver));
        // Регистрируем лоадер для FWSkin
        assetManager.setLoader(Skin.class, new FWSkinLoader(assetManager.getFileHandleResolver()));

        // вектор tvg - см. https://github.com/lyze237/gdx-TinyVG !!! лучше не использовать, тормоза!
        assetManager.setLoader(TinyVG.class, new TinyVGAssetLoader(assetManager.getFileHandleResolver()));

        // эффекты частиц
        assetManager.setLoader(ParticleEffect.class, ".p", new ParticleEffectLoader(fileHandleResolver));

        // ЗВУК
        assetManager.setLoader(Sound.class, new SoundLoader(fileHandleResolver));
        assetManager.setLoader(Music.class, new MusicLoader(fileHandleResolver));

        // карты редакторов уровней
        assetManager.setLoader(TiledMap.class, new TmxMapLoader(fileHandleResolver));
        assetManager.setLoader(TiledMap.class, new AtlasTmxMapLoader(fileHandleResolver));

        // шрифты
        assetManager.setLoader(BitmapFont.class, new FreetypeFontLoader(fileHandleResolver));
    }

    @Override
    protected void fillGameSettings(GameSettings.Builder builder) {
        // Безопасная зона (Центральный квадрат 1440 × 1080)
        // Это зона, которая гарантированно будет видна на абсолютно любом устройстве
        // (и на вытянутом телефоне, и на квадратном iPad).

//        В коде пишите: new ExtendViewport(1920, 1080).
//            Фоновые арты заказывайте у художника в размере 2400 × 1080 (или центрируйте 1920, оставляя размытые края).
//        Сюжетно важные элементы мини-игры удерживайте в пределах центральных 1440 пикселей по ширине.
        builder.setVirtualScreenWidth(Constants.VIRTUAL_WORLD_WIDTH);
        builder.setVirtualScreenHeight(Constants.VIRTUAL_WORLD_HEIGHT);
    }

}
