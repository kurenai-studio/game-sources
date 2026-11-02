package com.micro1.territory;

/** A round: its shape asset, the four territories, and the derived largest-territory answer. */
public class Round {

    public final int number;             // 1-4
    public final String assetName;       // e.g. "shape1.png"
    public final Territory[] territories; // length 4
    public final int largestIndex;       // index of the largest-area territory (the correct answer)
    public final float largestPct;       // largest area as a percentage of the whole rectangle

    public Round(int number, String assetName, Territory[] territories) {
        this.number = number;
        this.assetName = assetName;
        this.territories = territories;

        float total = 0f, max = -1f;
        int maxIdx = 0;
        for (int i = 0; i < territories.length; i++) {
            total += territories[i].area;
        }
        for (int i = 0; i < territories.length; i++) {
            if (territories[i].area > max) {
                max = territories[i].area;
                maxIdx = i;
            }
        }
        this.largestIndex = maxIdx;
        this.largestPct = total > 0f ? (max / total) * 100f : 0f;
    }

    public Territory largest() {
        return territories[largestIndex];
    }
}
