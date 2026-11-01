package dev.meowpow.boxbot.engine.entity;

import dev.meowpow.boxbot.engine.PackageColor;

public final class PackageFixtures {

    private PackageFixtures() {}

    public static Package packageWithId(int id) {
        return packageWithId(id, PackageColor.RED);
    }

    public static Package packageWithId(int id, PackageColor color) {
        return new Package(new PackageId(id), color);
    }
}
