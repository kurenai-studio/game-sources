package com.github.br.libgdx.jam38.game.screens;

import com.github.br.libgdx.jam38.game.Resources;
import com.github.br.libgdx.jam38.structure.screen.statemachine.GameScreenState;

public interface Screens {

    GameScreenState MENU = new GameScreenState(new MenuScreen(
        Resources.SKIN, Resources.Tiled.MENU, true
    ), new MenuAssetLoader());
    GameScreenState GAME = new GameScreenState(new GameScreen(
        Resources.SKIN, Resources.Tiled.GAME, true
    ), new GameAssetLoader());

    GameScreenState END = new GameScreenState(
        new EndScreen(),
        new EndScreenGameAssetLoader()
    );

    GameScreenState LEVEL_3 = new GameScreenState(
        new GraphGameScreen("graphs/graph_3.json", END),
        new GraphGameAssetLoader()
    );

    GameScreenState LEVEL_2 = new GameScreenState(
        new GraphGameScreen("graphs/graph_2.json", LEVEL_3),
        new GraphGameAssetLoader()
    );

    GameScreenState LEVEL_1 = new GameScreenState(
        new GraphGameScreen("graphs/graph_1.json", LEVEL_2),
        new GraphGameAssetLoader()
    );

}
