package com.github.br.libgdx.jam38.game.model.action.vertex;

import com.github.br.libgdx.jam38.game.model.action.GameVertexAction;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;

public class FreezeVertexAction extends GameVertexAction {

    public FreezeVertexAction(String target) {
        super(target);
    }

    @Override
    public void execute(GameVertex gameVertex) {
        gameVertex.setFreeze(true);
    }

    @Override
    public int getTimeCost() {
        return 0;
    }

}
