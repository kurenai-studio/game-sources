package com.github.br.libgdx.jam38.structure.ui;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.scenes.scene2d.ui.*;
import com.badlogic.gdx.scenes.scene2d.utils.Drawable;
import com.badlogic.gdx.utils.Align;
import com.badlogic.gdx.utils.Null;
import com.badlogic.gdx.utils.ObjectMap;
import com.badlogic.gdx.utils.Scaling;
import com.github.tommyettinger.textra.Font;
import com.github.tommyettinger.textra.Styles;
import com.github.tommyettinger.textra.TypingLabel;

public class TypingImageButton extends Button {

    static public class TypingImageTextButtonStyle extends TextButton.TextButtonStyle {
        public @Null Drawable imageUp, imageDown, imageOver, imageDisabled;
        public @Null Drawable imageChecked, imageCheckedDown, imageCheckedOver;

        public TypingImageTextButtonStyle() {
        }

        public TypingImageTextButtonStyle(@Null Drawable up, @Null Drawable down, @Null Drawable checked, BitmapFont font) {
            super(up, down, checked, font);
        }

        public TypingImageTextButtonStyle(TypingImageTextButtonStyle style) {
            super(style);
            imageUp = style.imageUp;
            imageDown = style.imageDown;
            imageOver = style.imageOver;
            imageDisabled = style.imageDisabled;

            imageChecked = style.imageChecked;
            imageCheckedDown = style.imageCheckedDown;
            imageCheckedOver = style.imageCheckedOver;
        }

        public TypingImageTextButtonStyle(TextButton.TextButtonStyle style) {
            super(style);
        }
    }

    // Кэшируем Font, привязывая его к конкретному экземпляру BitmapFont
    private static final ObjectMap<BitmapFont, Font> fontCache = new ObjectMap<>();

    private static Font getFont(BitmapFont bitmapFont) {
        if (bitmapFont == null) return null;

        Font textraFont = fontCache.get(bitmapFont);
        if (textraFont == null) {
            textraFont = new Font(bitmapFont);
            fontCache.put(bitmapFont, textraFont);
        }
        return textraFont;
    }

    private final Image image;
    private TypingLabel label;
    private TypingImageTextButtonStyle style;

    public TypingImageButton(@Null String text, Skin skin) {
        this(text, skin.get(TypingImageTextButtonStyle.class));
        setSkin(skin);
    }

    public TypingImageButton(@Null String text, Skin skin, String styleName) {
        this(text, skin.get(styleName, TypingImageTextButtonStyle.class));
        setSkin(skin);
    }

    public TypingImageButton(@Null String text, TypingImageTextButtonStyle style) {
        super(style);
        this.style = style;

        defaults().space(3);

        image = newImage();

        label = new TypingLabel(text, new Styles.LabelStyle(getFont(style.font), style.fontColor));
        label.setAlignment(Align.center);

        add(image);
        add(label);

        setStyle(style);

        setSize(getPrefWidth(), getPrefHeight());
    }

    protected Image newImage() {
        return new Image((Drawable) null, Scaling.fit);
    }

    protected Label newLabel(String text, Label.LabelStyle style) {
        return new Label(text, style);
    }

    public void setStyle(ButtonStyle style) {
        if (!(style instanceof TypingImageTextButtonStyle))
            throw new IllegalArgumentException("style must be a ImageTextButtonStyle.");
        this.style = (TypingImageTextButtonStyle) style;
        super.setStyle(style);

        if (image != null) updateImage();

        if (label != null) {
            TypingImageTextButtonStyle textButtonStyle = (TypingImageTextButtonStyle) style;
            Styles.LabelStyle labelStyle = label.style;
            labelStyle.font = getFont(textButtonStyle.font);
            labelStyle.fontColor = getFontColor();
            label.style = labelStyle;
        }
    }

    public TypingImageTextButtonStyle getStyle() {
        return style;
    }

    /**
     * Returns the appropriate image drawable from the style based on the current button state.
     */
    protected @Null Drawable getImageDrawable() {
        if (isDisabled() && style.imageDisabled != null) return style.imageDisabled;
        if (isPressed()) {
            if (isChecked() && style.imageCheckedDown != null) return style.imageCheckedDown;
            if (style.imageDown != null) return style.imageDown;
        }
        if (isOver()) {
            if (isChecked()) {
                if (style.imageCheckedOver != null) return style.imageCheckedOver;
            } else {
                if (style.imageOver != null) return style.imageOver;
            }
        }
        if (isChecked()) {
            if (style.imageChecked != null) return style.imageChecked;
            if (isOver() && style.imageOver != null) return style.imageOver;
        }
        return style.imageUp;
    }

    /**
     * Sets the image drawable based on the current button state. The default implementation sets the image drawable using
     * {@link #getImageDrawable()}.
     */
    protected void updateImage() {
        image.setDrawable(getImageDrawable());
    }

    /**
     * Returns the appropriate label font color from the style based on the current button state.
     */
    protected @Null Color getFontColor() {
        if (isDisabled() && style.disabledFontColor != null) return style.disabledFontColor;
        if (isPressed()) {
            if (isChecked() && style.checkedDownFontColor != null) return style.checkedDownFontColor;
            if (style.downFontColor != null) return style.downFontColor;
        }
        if (isOver()) {
            if (isChecked()) {
                if (style.checkedOverFontColor != null) return style.checkedOverFontColor;
            } else {
                if (style.overFontColor != null) return style.overFontColor;
            }
        }
        boolean focused = hasKeyboardFocus();
        if (isChecked()) {
            if (focused && style.checkedFocusedFontColor != null) return style.checkedFocusedFontColor;
            if (style.checkedFontColor != null) return style.checkedFontColor;
            if (isOver() && style.overFontColor != null) return style.overFontColor;
        }
        if (focused && style.focusedFontColor != null) return style.focusedFontColor;
        return style.fontColor;
    }

    public void draw(Batch batch, float parentAlpha) {
        updateImage();
        label.style.fontColor = getFontColor();
        super.draw(batch, parentAlpha);
    }

    public Image getImage() {
        return image;
    }

    public Cell getImageCell() {
        return getCell(image);
    }

    public void setLabel(TypingLabel label) {
        getLabelCell().setActor(label);
        this.label = label;
    }

    public TypingLabel getLabel() {
        return label;
    }

    public Cell getLabelCell() {
        return getCell(label);
    }

    public void setText(String text) {
        label.setText(text);
        label.restart(); // Принудительно запускаем эффект печати сначала
    }

    public String getText() {
        return label.getOriginalText().toString();
    }

    public String toString() {
        String name = getName();
        if (name != null) return name;
        String className = getClass().getName();
        int dotIndex = className.lastIndexOf('.');
        if (dotIndex != -1) className = className.substring(dotIndex + 1);
        return (className.indexOf('$') != -1 ? "ImageTextButton " : "") + className + ": " + image.getDrawable() + " "
            + label.getOriginalText().toString();
    }

}
