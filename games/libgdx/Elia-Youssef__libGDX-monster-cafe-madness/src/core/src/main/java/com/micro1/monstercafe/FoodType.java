package com.micro1.monstercafe;

/**
 * The three food items available in the game - the only orderable foods. Each maps to its supplied asset
 * path (used exactly as provided, never renamed). {@code values()} drives the uniform random food request.
 */
public enum FoodType {
    BURGER("food/burger.png", "Burger"),
    CUPCAKE("food/cupcake.png", "Cupcake"),
    POTION("food/potion_drink.png", "Potion Drink");

    public final String assetPath;
    public final String displayName;

    FoodType(String assetPath, String displayName) {
        this.assetPath = assetPath;
        this.displayName = displayName;
    }
}
