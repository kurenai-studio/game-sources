package com.github.br.libgdx.jam38.game.screens.ui;

import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.scenes.scene2d.ui.WidgetGroup;
import com.github.br.libgdx.jam38.game.model.GameVertexState;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;
import com.github.br.libgdx.jam38.structure.ui.AnimatedImage;

public class UiEdge extends WidgetGroup {

    // модель
    private final UiNode from;
    private final UiNode to;

    private final AnimatedImage emitEdge;
    private final AnimatedImage emptyEdge;
    private final AnimatedImage freezeEdge;
    private final AnimatedImage targetEdge;

    // Временный вектор для избежания аллокаций памяти
    private final Vector2 direction = new Vector2();

    private AnimatedImage prevEdge;

    private float fromToEnergy;
    private float toFromEnergy;

    public UiEdge(
        UiNode from,
        UiNode to,
        AnimatedImage emitEdge,
        AnimatedImage emptyEdge,
        AnimatedImage freezeEdge,
        AnimatedImage targetEdge
    ) {
        this.from = from;
        this.to = to;

        this.from.getModel().addGameVertexListener(new EdgeGameVertexListener() {
            @Override
            public void addEnergy(GameVertex from, GameVertex to, float addedEnergy) {
                if (from == UiEdge.this.from.getModel() && to == UiEdge.this.to.getModel()) {
                    fromToEnergy = addedEnergy;
                }
            }
        });
        this.to.getModel().addGameVertexListener(new EdgeGameVertexListener() {
            @Override
            public void addEnergy(GameVertex from, GameVertex to, float addedEnergy) {
                if (from == UiEdge.this.to.getModel() && to == UiEdge.this.from.getModel()) {
                    toFromEnergy = addedEnergy;
                }
            }
        });

        this.emitEdge = emitEdge;
        this.emptyEdge = emptyEdge;
        this.freezeEdge = freezeEdge;
        this.targetEdge = targetEdge;

        emitEdge.setFrameAndPause(0);
        emptyEdge.setFrameAndPause(0);
        freezeEdge.setFrameAndPause(0);
        targetEdge.setFrameAndPause(0);

        AnimatedImage edge = getEdgeType(from, to);
        edge.play();
        prevEdge = edge;

        // Добавляем текущее ребро как дочерний элемент группы
        this.addActor(edge);
    }

    @Override
    public void act(float delta) {
        super.act(delta);

        // 1. Проверяем смену типа ребра и анимации
        AnimatedImage edge = getEdgeType(from, to);
        if (edge != prevEdge) {
            this.clearChildren();
            this.addActor(edge);
            edge.play();
            prevEdge = edge;
        }

        // 2. Расчет геометрии ребра на основе позиций узлов
        float toX = to.getX() + to.getOriginX();
        float toY = to.getY() + to.getOriginY();
        float fromX = from.getX() + from.getOriginX();
        float fromY = from.getY() + from.getOriginY();

        direction.set(toX, toY).sub(fromX, fromY);
        float distance = direction.len();
        float angle = direction.angleDeg(); // Угол наклона в градусах

        // Вычисляем высоту ребра
        float edgeHeight = emptyEdge.getHeight() > 0 ? emptyEdge.getHeight() : 10f;

        // 3. Устанавливаем точку опоры (Origin) ТОЧНО ПО ЦЕНТРУ ребра
        float originX = distance / 2f;
        float originY = edgeHeight / 2f;
        this.setOrigin(originX, originY);
        this.setSize(distance, edgeHeight);

        // 4. Расчет позиции левого нижнего угла (лежит на векторе from, но смещен к центру)
        // Находим центральную точку между узлами: (fromX + toX) / 2
        // И вычитаем из нее половину размеров ребра, чтобы скомпенсировать setPosition в Scene2D
        float centerX = (fromX + toX) / 2f;
        float centerY = (fromY + toY) / 2f;

        this.setPosition(centerX - originX, centerY - originY);

        // 5. Логика разворота в зависимости от состояний
        GameVertex toModel = to.getModel();
        GameVertex fromModel = from.getModel();
        if (emitEdge == edge) {
            if (GameVertexState.EMITTER == fromModel.getState() && GameVertexState.EMITTER == toModel.getState()) {
                // оба эмиттеры
                if ((fromToEnergy - toFromEnergy) < 0) {
                    angle += 180;
                }
            } else if (GameVertexState.EMITTER == fromModel.getState()) {
                // поворот не нужен, по дефолту из from в to течет энергия
            } else if (GameVertexState.EMITTER == toModel.getState()) {
                angle += 180; // энергия из to во from
            }
        }
        this.setRotation(angle);

        // 6. Синхронизируем размеры вложенной анимации с размерами группы
        edge.setPosition(0, 0);
        edge.setSize(this.getWidth(), this.getHeight());
    }

    @Override
    public void draw(Batch batch, float parentAlpha) {
        // Благодаря наследованию от WidgetGroup, метод super.draw() автоматически:
        // 1. Применит позицию (position), поворот (rotation) и точку опоры (origin) текущего UiEdge к батчу.
        // 2. Сместит систему координат дочернего AnimatedImage в (0,0) относительно начала ребра.
        // 3. Корректно применит parentAlpha ко всем вложенным элементам.
        super.draw(batch, parentAlpha);
    }

    private AnimatedImage getEdgeType(UiNode uiFrom, UiNode uiTo) {
        GameVertex from = uiFrom.getModel();
        GameVertex to = uiTo.getModel();
        if (from.isFreeze() || to.isFreeze()) {
            return freezeEdge;
        }
        if (GameVertexState.EMITTER == from.getState() || GameVertexState.EMITTER == to.getState()) {
            return emitEdge;
        }
        if (GameVertexState.TARGET == to.getState() && GameVertexState.EMITTER != from.getState()) {
            return targetEdge;
        } else {
            return emptyEdge;
        }
    }

}
