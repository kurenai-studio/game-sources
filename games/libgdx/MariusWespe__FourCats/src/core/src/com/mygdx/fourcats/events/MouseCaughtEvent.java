package com.mygdx.fourcats.events;

import com.badlogic.gdx.scenes.scene2d.Actor;

public class MouseCaughtEvent
{

    public MouseCaughtEvent(int mouseIndex, int posX, int posY) {
        this.mouseIndex = mouseIndex;
        this.posX = posX;
        this.posY = posY;
    }

    public int mouseIndex;

    public int posX;

    public int posY;
}
