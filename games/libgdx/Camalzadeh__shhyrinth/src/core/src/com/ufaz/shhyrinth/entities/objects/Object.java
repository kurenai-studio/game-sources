package com.ufaz.shhyrinth.entities.objects;

import com.badlogic.gdx.math.Rectangle;
import com.github.tommyettinger.textra.TypingLabel;

public abstract class Object {

    protected TypingLabel label;
    protected TypingLabel emptyLabel;
    protected Rectangle rectangle;

    public Rectangle getRectangle() {
        return rectangle;
    }

    public void setRectangle(Rectangle rectangle) {
        this.rectangle = rectangle;
    }

    public TypingLabel getLabel() {
        return label;
    }

    public void setLabel(TypingLabel label) {
        this.label = label;
    }

    public TypingLabel getEmptyLabel() {
        return emptyLabel;
    }

    public void setEmptyLabel(TypingLabel emptyLabel) {
        this.emptyLabel = emptyLabel;
    }
}
