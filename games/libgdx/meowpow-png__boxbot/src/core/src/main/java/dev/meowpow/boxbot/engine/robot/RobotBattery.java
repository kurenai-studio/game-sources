package dev.meowpow.boxbot.engine.robot;

/**
 * Represents a robot's battery.
 */
public final class RobotBattery {

    private int level;
    private final int capacity;

    /**
     * @throws IllegalArgumentException if {@code level} or
     * {@code capacity} is negative, or {@code level} exceeds {@code capacity}
     */
    public RobotBattery(int level, int capacity) {
        if (capacity < 0) {
            throw new IllegalArgumentException("capacity must be >= 0, got " + capacity);
        }
        if (level < 0) {
            throw new IllegalArgumentException("level must be >= 0, got " + level);
        }
        if (level > capacity) {
            var message = "level must be <= capacity (" + capacity + "), got ";
            throw new IllegalArgumentException(message + level);
        }
        this.level = level;
        this.capacity = capacity;
    }

    /**
     * A battery at full charge.
     *
     * @param capacity charge held when fully charged
     */
    public static RobotBattery full(int capacity) {
        return new RobotBattery(capacity, capacity);
    }

    /**
     * Drains the battery by the given amount.
     * <p>
     * The value is clamped at zero.
     *
     * @param amount charge to remove
     */
    public void drain(int amount) {
        level = Math.max(0, level - amount);
    }

    /**
     * Charges the battery by the given amount.
     * <p>
     * The value is clamped at capacity.
     *
     * @param amount charge to add
     */
    public void charge(int amount) {
        level = Math.min(capacity, level + amount);
    }

    /**
     * Returns the current charge level.
     */
    public int level() {
        return level;
    }

    /**
     * Returns the charge held when fully charged.
     */
    public int capacity() {
        return capacity;
    }

    /**
     * Returns the charge level as a
     * percentage of capacity, rounded down.
     */
    public int percentage() {
        return capacity == 0 ? 0 : level * 100 / capacity;
    }

    /**
     * Returns whether the robot battery is low.
     *
     * @param threshold the level to compare against
     */
    public boolean isLow(int threshold) {
        return level <= threshold;
    }

    /**
     * Returns whether the battery is fully charged
     */
    public boolean isFull() {
        return level >= capacity;
    }

    /**
     * Returns whether the battery is fully depleted
     */
    public boolean isDepleted() {
        return level <= 0;
    }
}
