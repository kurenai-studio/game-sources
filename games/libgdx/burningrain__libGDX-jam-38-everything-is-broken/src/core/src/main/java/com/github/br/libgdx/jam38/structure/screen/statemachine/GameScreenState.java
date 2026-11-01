package com.github.br.libgdx.jam38.structure.screen.statemachine;


import com.github.br.libgdx.jam38.structure.screen.AbstractGameScreen;
import com.github.br.libgdx.jam38.structure.screen.loading.AssetsLoader;

public class GameScreenState {

    public final AbstractGameScreen screen;
    public final AssetsLoader assetsLoader;

    public GameScreenState(AbstractGameScreen screen, AssetsLoader assetsLoader) {
        this.screen = screen;
        this.assetsLoader = assetsLoader;
    }

}
