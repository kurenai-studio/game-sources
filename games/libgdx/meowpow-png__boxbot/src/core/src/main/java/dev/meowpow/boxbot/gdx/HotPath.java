package dev.meowpow.boxbot.gdx;

import java.lang.annotation.*;

/**
 * Marks a type that participates in the runtime hot
 * path indicating that it should be optimized for performance.
 */
@Documented
@Retention(RetentionPolicy.CLASS)
@Target(ElementType.TYPE)
public @interface HotPath {}
