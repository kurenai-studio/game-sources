package dev.meowpow.boxbot.engine.demand;

import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.gdx.HotPath;

import java.util.Random;

/**
 * A random distribution over package colors.
 * <p>
 * A single instance is shared across the putaway and
 * retrieval demand processes, so both draw from the same
 * underlying color demand. Distribution is weighted per
 * color and fixed for the lifetime of the instance.
 */
@HotPath
public final class ColorDemand {

    private final Random random;
    private final PackageColor[] colors;
    private final double[] cumulativeWeights;
    private final double totalWeight;

    /**
     * Creates a demand distribution with per-color
     * weights randomly assigned from {@code seed}.
     *
     * @param seed seed for both the weight assignment and subsequent sampling
     */
    public ColorDemand(long seed) {
        this.random = new Random(seed);
        var values = PackageColor.values();
        this.colors = new PackageColor[values.length - 1];
        this.cumulativeWeights = new double[colors.length];

        double total = 0;
        int index = 0;
        for (var color : values) {
            if (color == PackageColor.NONE) {
                continue;
            }
            colors[index] = color;
            total += 1 + random.nextDouble();
            cumulativeWeights[index] = total;
            index++;
        }
        this.totalWeight = total;
    }

    /**
     * Draws a random color according to the configured weights.
     *
     * @return the sampled color, never {@link PackageColor#NONE}
     */
    public PackageColor sample() {
        var roll = random.nextDouble() * totalWeight;

        for (int i = 0; i < colors.length; i++) {
            if (roll < cumulativeWeights[i]) {
                return colors[i];
            }
        }
        return colors[colors.length - 1];
    }

    /**
     * Returns the fraction of total demand weight
     * assigned to {@code color}, between 0 and 1.
     * <p>
     * Shares across every sampled color sum to 1.
     *
     * @throws IllegalArgumentException if {@code color} has no demand weight
     */
    public double share(PackageColor color) {
        for (int i = 0; i < colors.length; i++) {
            if (colors[i] == color) {
                var previous = i == 0 ? 0 : cumulativeWeights[i - 1];
                return (cumulativeWeights[i] - previous) / totalWeight;
            }
        }
        throw new IllegalArgumentException("No demand weight for color " + color);
    }
}
