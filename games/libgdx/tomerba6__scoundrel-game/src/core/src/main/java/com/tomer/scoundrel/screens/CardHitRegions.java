package com.tomer.scoundrel.screens;

import com.tomer.scoundrel.model.Card;

import java.util.List;

/**
 * Pure geometry for "which card is under this point". Used by skip-and-act:
 * the click that dismisses an animation must also resolve the card it landed
 * on. Free of LibGDX so it can be unit tested headlessly.
 */
final class CardHitRegions {

    /**
     * A card's on-screen rectangle; {@code (x, y)} is the bottom-left corner.
     *
     * @param card   the card drawn there
     * @param x      the left edge, in world space
     * @param y      the bottom edge, in world space (y points up)
     * @param width  the width, in world units
     * @param height the height, in world units
     */
    record CardRect(Card card, float x, float y, float width, float height) {

        /**
         * Whether a point is on the card, edges included.
         *
         * @param pointX the point's x, in world space
         * @param pointY the point's y, in world space
         * @return true if the point is inside or on the rectangle
         */
        boolean contains(float pointX, float pointY) {
            return pointX >= x && pointX <= x + width
                    && pointY >= y && pointY <= y + height;
        }
    }

    private CardHitRegions() {
    }

    /**
     * The topmost card containing the point; null when it lands in a gap.
     *
     * @param rects  the cards in draw order, so a later one is on top
     * @param pointX the point's x, in world space
     * @param pointY the point's y, in world space
     * @return the card under the point, or null
     */
    static Card cardAt(List<CardRect> rects, float pointX, float pointY) {
        for (int i = rects.size() - 1; i >= 0; i--) {
            CardRect rect = rects.get(i);
            if (rect.contains(pointX, pointY)) {
                return rect.card();
            }
        }
        return null;
    }
}
