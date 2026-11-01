package com.github.br.libgdx.jam38.game.model;

import com.github.br.libgdx.jam38.game.model.vertex.CalculateVertexProxy;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertexData;

public class GameVertexProxyFactoryImpl implements GameVertexProxyFactory {

    @Override
    public GameVertex createProxy(GameVertexData gameVertex) {
        return new CalculateVertexProxy(gameVertex);
    }

}
