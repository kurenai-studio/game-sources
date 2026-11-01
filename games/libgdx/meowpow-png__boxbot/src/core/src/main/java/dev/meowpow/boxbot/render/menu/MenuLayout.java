package dev.meowpow.boxbot.render.menu;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.utils.Array;

import java.util.Objects;

/**
 * Geometry for a centered menu overlay.
 */
public final class MenuLayout {

    private final float panelWidth;
    private final float panelHeight;
    private final float padding;
    private final float verticalOffset;

    private final MenuComponent[] components;
    private final float[] componentY;
    private final @Nullable ButtonListComponent buttons;

    private MenuLayout(Builder builder) {
        this.panelWidth = builder.panelWidth * builder.scale;
        this.padding = builder.padding * builder.scale;
        this.verticalOffset = builder.verticalOffset * builder.scale;
        this.buttons = builder.buttons;

        int decorationCount = builder.components.size;
        this.components = new MenuComponent[decorationCount + 1];
        for (int i = 0; i < decorationCount; i++) {
            components[i] = builder.components.get(i);
        }
        if (buttons != null) {
            components[decorationCount] = buttons;
        }
        float stackHeight = 0f;
        for (MenuComponent component : components) {
            stackHeight += component.height();
        }
        var componentGap = builder.componentGap * builder.scale;
        if (components.length > 1) {
            stackHeight += componentGap * (components.length - 1);
        }
        this.panelHeight = padding * 2f + stackHeight;

        this.componentY = new float[components.length];
        float cursor = panelHeight - padding;
        for (int i = 0; i < components.length; i++) {
            cursor -= components[i].height();
            componentY[i] = cursor;
            cursor -= componentGap;
        }
    }

    /**
     * The panel's full width.
     */
    public float panelWidth() {
        return panelWidth;
    }

    /**
     * The panel's full height: padding
     * above and below the stacked components.
     */
    public float panelHeight() {
        return panelHeight;
    }

    /**
     * The width available to each component, after side padding.
     */
    public float contentWidth() {
        return panelWidth - 2f * padding;
    }

    /**
     * Space kept clear on every edge of the panel.
     */
    public float padding() {
        return padding;
    }

    /**
     * The panel's upward offset from the screen's vertical center.
     */
    public float verticalOffset() {
        return verticalOffset;
    }

    /**
     * The stacked components, top to bottom.
     * <p>
     * Buttons are always the last element in the array.
     */
    public MenuComponent[] components() {
        return components;
    }

    /**
     * The given component's bottom edge,
     * relative to the panel's own bottom edge.
     *
     * @param index the component's index, in stacking order
     */
    public float componentY(int index) {
        return componentY[index];
    }

    /**
     * This layout's button stack.
     */
    public @Nullable ButtonListComponent buttons() {
        return buttons;
    }

    /**
     * The button stack's bottom edge,
     * relative to the panel's own bottom edge.
     */
    public float buttonsY() {
        return componentY[components.length - 1];
    }

    /**
     * Builds a {@link MenuLayout} from an ordered stack of components.
     */
    public static final class Builder {

        private final Array<MenuComponent> components = new Array<>();

        private float panelWidth = -1f;
        private float padding = 40f;
        private float componentGap = 12f;
        private float verticalOffset = 10f;
        private int scale = 1;
        private @Nullable ButtonListComponent buttons;

        /**
         * Sets the panel's width, before scaling.
         */
        public Builder panelWidth(float panelWidth) {
            this.panelWidth = panelWidth;
            return this;
        }

        /**
         * Sets the space kept clear on
         * every edge of the panel before scaling.
         */
        public Builder padding(float padding) {
            this.padding = padding;
            return this;
        }

        /**
         * Sets the vertical gap between
         * stacked components before scaling.
         */
        public Builder componentGap(float componentGap) {
            this.componentGap = componentGap;
            return this;
        }

        /**
         * Sets the panel's upward offset from
         * the screen's vertical center before scaling.
         */
        public Builder verticalOffset(float verticalOffset) {
            this.verticalOffset = verticalOffset;
            return this;
        }

        /**
         * Sets the integer pixel scale every dimension is multiplied by.
         */
        public Builder scale(int scale) {
            this.scale = scale;
            return this;
        }

        /**
         * Appends a decorative component above the button stack.
         *
         * @throws NullPointerException if {@code component} is null
         */
        public Builder addComponent(MenuComponent component) {
            components.add(Objects.requireNonNull(component, "component must not be null"));
            return this;
        }

        /**
         * Sets this layout's button stack, always drawn last.
         *
         * @throws NullPointerException if {@code buttons} is null
         */
        public Builder buttons(ButtonListComponent buttons) {
            this.buttons = Objects.requireNonNull(buttons, "buttons must not be null");
            return this;
        }

        /**
         * @throws IllegalStateException if {@code panelWidth} or {@code buttons} was never set
         * @throws IllegalArgumentException if {@code scale} is not positive
         */
        public MenuLayout build() {
            if (panelWidth <= 0f) {
                throw new IllegalStateException("panelWidth must be set to a positive value");
            }
            if (buttons == null) {
                throw new IllegalStateException("buttons must be set");
            }
            if (scale <= 0) {
                throw new IllegalArgumentException("scale must be positive: " + scale);
            }
            return new MenuLayout(this);
        }
    }
}
