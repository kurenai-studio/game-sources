package com.github.br.libgdx.jam38.game.screens.ui;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Animation;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.scenes.scene2d.ui.Image;
import com.badlogic.gdx.scenes.scene2d.utils.Drawable;
import com.badlogic.gdx.scenes.scene2d.utils.TransformDrawable;
import com.github.br.libgdx.jam38.game.model.GameVertexState;
import com.github.br.libgdx.jam38.game.model.vertex.GameVertex;
import com.github.br.libgdx.jam38.structure.ui.AnimatedImage;

public class UiNode extends Image {

    // Настройки ободка
    // https://htmlcolorcodes.com/hex-to-rgb/ - конвертер
    private static final Color freezeColor = new Color(180 / 255f, 226 / 255f, 255 / 255f, 1f); // rgb(180 226 255)
    private static final Color emitterColor = new Color(159 / 255f, 207 / 255f, 143 / 255f, 1f); // rgb(159 207 143)
    private static final Color targetColor = new Color(155 / 255f, 155 / 255f, 155 / 255f, 1f); // rgb(155 155 155)
    private static final Color emptyColor = new Color(135 / 255f, 60 / 255f, 148 / 255f, 1f); // rgb(135 60 148)
    public static final float MAX_ENERGY = 100f;

    // константы
    private final GameVertex gameVertex; // модель

    private final AnimatedImage emitFrom;
    private final AnimatedImage emitToFromTime;
    private final AnimatedImage emitTo;
    private final AnimatedImage selectedNode;
    private final AnimatedImage freezeNode;
    private final AnimatedImage emitterNode;
    private final AnimatedImage emptyNode;
    private final AnimatedImage targetNode;
    private final TextureAtlas.AtlasRegion icon;

    // переменные
    private float ringRadius = 45f;      // Внешний радиус ободка
    private float ringThickness = 6f;    // Толщина линии ободка

    private boolean isSelected = false;

    public UiNode(
        GameVertex gameVertex,
        TextureAtlas.AtlasRegion icon,
        AnimatedImage emitFrom,
        AnimatedImage emitToFromTime,
        AnimatedImage emitTo,
        AnimatedImage selectedNode,
        AnimatedImage freezeNode,
        AnimatedImage emitterNode,
        AnimatedImage emptyNode,
        AnimatedImage targetNode
    ) {
        super(emptyNode.getDrawable());
        this.setSize(this.getWidth(), this.getHeight());
        this.setOrigin(this.getWidth() / 2f, this.getHeight() / 2f);

        this.gameVertex = gameVertex;
        this.icon = icon;
        this.emitFrom = emitFrom;
        this.emitToFromTime = emitToFromTime;
        this.emitTo = emitTo;
        this.selectedNode = selectedNode;
        this.freezeNode = freezeNode;
        this.emitterNode = emitterNode;
        this.emptyNode = emptyNode;
        this.targetNode = targetNode;

        emitFrom.setFrameAndPause(0);
        emitToFromTime.setFrameAndPause(0);
        emitTo.setFrameAndPause(0);
        selectedNode.setFrameAndPause(0);
        freezeNode.setFrameAndPause(0);

        emitterNode.setFrameAndPause(0);
        emptyNode.setFrameAndPause(0);
        targetNode.setFrameAndPause(0);

        AnimatedImage nodeImage = getNodeImage(gameVertex.getState());
        nodeImage.play();

        if (gameVertex.isFreeze()) {
            freeze();
        }
    }

    public GameVertex getModel() {
        return gameVertex;
    }

    // здесь должен быть https://libgdx.com/news/2021/05/shape-drawer
    public void drawEnergy(ShapeRenderer shapeRenderer, float parentAlpha) {
        ringRadius = getWidth() * (1 / 2f + 1 / 16f);

        float energy = gameVertex.getEnergy();
        if (energy <= 0) {
            return;
        }

        shapeRenderer.setColor(getEnergyColor(getModel()));

        float centerX = getX() + getOriginX();
        float centerY = getY() + getOriginY();

        float rOut = ringRadius * getScaleX();
        float rIn = (ringRadius - ringThickness) * getScaleX();

        // Переводим проценты в радианы и учитываем стартовую точку на 12 часов (90 градусов)
        float startAngleRad = (90f + getRotation()) * MathUtils.degreesToRadians;
        float energyPercentage = energy / MAX_ENERGY;

        // Количество сегментов круга для плавности
        int segments = 60;

        float lastXOut = centerX + rOut * MathUtils.cos(startAngleRad);
        float lastYOut = centerY + rOut * MathUtils.sin(startAngleRad);
        float lastXIn = centerX + rIn * MathUtils.cos(startAngleRad);
        float lastYIn = centerY + rIn * MathUtils.sin(startAngleRad);

        for (int i = 1; i <= segments; i++) {
            float percentOfArc = (float) i / segments;
            // Минус перед углом дает движение ПО часовой стрелке
            float currentAngleRad = startAngleRad - (energyPercentage * 360f * percentOfArc) * MathUtils.degreesToRadians;

            float nextXOut = centerX + rOut * MathUtils.cos(currentAngleRad);
            float nextYOut = centerY + rOut * MathUtils.sin(currentAngleRad);
            float nextXIn = centerX + rIn * MathUtils.cos(currentAngleRad);
            float nextYIn = centerY + rIn * MathUtils.sin(currentAngleRad);

            // Рисуем один кусочек (квадрат из двух треугольников) нашего ободка
            shapeRenderer.triangle(lastXOut, lastYOut, nextXOut, nextYOut, nextXIn, nextYIn);
            shapeRenderer.triangle(lastXIn, lastYIn, nextXIn, nextYIn, lastXOut, lastYOut);

            lastXOut = nextXOut;
            lastYOut = nextYOut;
            lastXIn = nextXIn;
            lastYIn = nextYIn;
        }
    }

    private Color getEnergyColor(GameVertex model) {
        if (model.isFreeze()) {
            return freezeColor;
        }
        return switch (model.getState()) {
            case EMITTER -> emitterColor;
            case TARGET -> targetColor;
            case NONE -> emptyColor;
        };
    }

    public void freeze() {
        // заморозка ноды
        freezeNode.resetAndPause();
        freezeNode.setLooping(false);
        freezeNode.setPlayMode(Animation.PlayMode.REVERSED);
        freezeNode.play();
    }

    public void unfreeze() {
        // разморозка ноды
        freezeNode.resetAndPause();
        freezeNode.setLooping(false);
        freezeNode.setPlayMode(Animation.PlayMode.NORMAL);
        freezeNode.play();
    }

//    public void emitFrom() {
//
//    }
//
//    public void emitTo() {
//
//    }

    public void emitFromTime() {
        emitToFromTime.resetAndPause();
        emitToFromTime.setLooping(false);
        emitToFromTime.setPlayMode(Animation.PlayMode.NORMAL);
        emitToFromTime.play();
    }

    @Override
    public void draw(Batch batch, float parentAlpha) {
        float diffEnergy = gameVertex.getDiffEnergy();
        GameVertexState newState = gameVertex.getState();

        if (diffEnergy < 0) { // многократное переключение
            // была отдача энергии
            if (emitFrom.isPaused()) { // иначе будет перетираться уже играющая анимация?
                emitFrom.setFrameAndPause(0);
                emitFrom.play();
            }
        } else if (diffEnergy > 0) { // многократное переключение
            // было получение энергии
            if (emitTo.isPaused()) {
                emitTo.resetAndPause();
                emitTo.play();
            }
        }

        // текущая нода: целевая, дефолтовая, эмиттер
        AnimatedImage nodeImage = getNodeImage(newState);
        setScaleByEnergy(gameVertex.getEnergy());
        // ОТРИСОВКА
        // Получаем актуальные параметры текущей ноды UiNode
        float x = getX();
        float y = getY();
        float width = getWidth();
        float height = getHeight();
        float scaleX = getScaleX();
        float scaleY = getScaleY();
        float rotation = getRotation();
        float originX = getOriginX();
        float originY = getOriginY();

        // Настраиваем цвет и альфу родителя для батча
        Color color = getColor();
        batch.setColor(color.r, color.g, color.b, color.a * parentAlpha);

        drawChild(batch, nodeImage, x, y, originX, originY, width, height, scaleX, scaleY, rotation);

        // приход или уход энергии в/из ноды
        // уход из ноды
        if (!emitFrom.isPaused()) {
            drawChild(batch, emitFrom, x, y, originX, originY, width, height, scaleX, scaleY, rotation);
            if (emitFrom.isAnimationEnd()) {
                emitFrom.resetAndPause();
                if (GameVertexState.EMITTER == newState) {
                    emitFrom.play();
                }
            }
        }
        // приход энергии в ноду из другой ноды
        if (!emitTo.isPaused()) {
            drawChild(batch, emitTo, x, y, originX, originY, width, height, scaleX, scaleY, rotation);
            if (emitTo.isAnimationEnd()) {
                emitTo.resetAndPause();
                if (diffEnergy > 0) {
                    emitTo.play();
                }
            }
        }

        // заморозка вкл/выкл в процессе анимации?
        if (!freezeNode.isAnimationEnd() && !freezeNode.isPaused()) {
            // тогда рисуем
            drawChild(batch, freezeNode, x, y, originX, originY, width, height, scaleX, scaleY, rotation);
            if (freezeNode.isAnimationEnd()) {
                freezeNode.pause();
            }
        } else if (getModel().isFreeze()) {
            drawChild(batch, freezeNode, x, y, originX, originY, width, height, scaleX, scaleY, rotation);
        }

        // приход энергии из камня времени при заморозке
        if (!emitToFromTime.isPaused()) {
            drawChild(batch, emitToFromTime, x, y, originX, originY, width, height, scaleX, scaleY, rotation);
            if (emitToFromTime.isAnimationEnd()) {
                emitToFromTime.resetAndPause();
            }
        }

        // нода выбрана игроком или не выбрана?
        if (isSelected) {
            float selWidth = selectedNode.getWidth();
            float selHeight = selectedNode.getHeight();

            // 1. Сдвигаем точку старта (x, y) назад, чтобы центрировать более крупную текстуру
            float selX = x + (width - selWidth) / 2f;
            float selY = y + (height - selHeight) / 2f;

            // 2. Рассчитываем НОВЫЙ ориджин ровно по центру selectedNode
            float selOriginX = selWidth / 2f;
            float selOriginY = selHeight / 2f;

            drawChild(
                batch,
                selectedNode,
                selX,
                selY,
                selOriginX,
                selOriginY,
                selWidth,
                selHeight,
                scaleX,
                scaleY,
                rotation
            );
        }

        float iconX = (width - icon.getRegionWidth()) / 2f;
        float iconY = (height - icon.getRegionHeight()) / 2f;
        batch.draw(
            icon,
            x + iconX, y + iconY,
            originX - iconX, originY - iconY,
            icon.getRegionWidth(), icon.getRegionHeight(),
            scaleX, scaleY,
            rotation
        );
    }

    private void setScaleByEnergy(float energy) {
        setScale(energy / MAX_ENERGY * 0.7f + 0.3f);
    }

    private AnimatedImage getNodeImage(GameVertexState newState) {
        return switch (newState) {
            case TARGET -> targetNode;
            case NONE -> emptyNode;
            case EMITTER -> emitterNode;
        };
    }

    // Помощник для отрисовки вложенных изображений с учетом трансформации родителя
    private void drawChild(
        Batch batch,
        AnimatedImage child,
        float x,
        float y,
        float originX,
        float originY,
        float w,
        float h,
        float scaleX,
        float scaleY,
        float rotation
    ) {
        Drawable drawable = child.getDrawable();
        if (drawable == null) return;

        if (scaleX != 1 || scaleY != 1 || rotation != 0) {
            if (drawable instanceof TransformDrawable) {
                ((TransformDrawable) drawable).draw(
                    batch, x, y, originX, originY, w, h, scaleX, scaleY, rotation
                );
                return;
            }
        }
        drawable.draw(batch, x, y, w * scaleX, h * scaleY);
    }

    public void select() {
        if (isSelected) {
            return;
        }

        selectedNode.setLooping(true);
        selectedNode.setPlayMode(Animation.PlayMode.LOOP_PINGPONG);
        selectedNode.setFrameAndPause(0);
        selectedNode.play();

        this.isSelected = true;

    }

    public void deselect() {
        selectedNode.resetAndPause();
        this.isSelected = false;
    }

    public boolean isSelected() {
        return isSelected;
    }

}
