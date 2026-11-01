package com.github.br.libgdx.jam38.game.model.action.vertex;

import com.github.br.libgdx.jam38.game.model.action.GameVertexAction;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;
import com.github.br.libgdx.jam38.game.model.GameVertexState;

public class SwitchEmitterVertexAction extends GameVertexAction {

    public SwitchEmitterVertexAction(String target) {
        super(target);
    }

    @Override
    public void execute(GameVertex gameVertex) {
        GameVertexState state = gameVertex.getState();
        if (GameVertexState.EMITTER == state) {
            gameVertex.setState(GameVertexState.NONE);
        } else if (GameVertexState.NONE == state) {
            gameVertex.setState(GameVertexState.EMITTER);
        }
    }

    @Override
    public int getTimeCost() {
        return 0;
    }

}
