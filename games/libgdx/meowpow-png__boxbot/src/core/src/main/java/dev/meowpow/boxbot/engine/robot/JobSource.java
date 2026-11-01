package dev.meowpow.boxbot.engine.robot;

import dev.meowpow.boxbot.engine.entity.PackageId;
import dev.meowpow.boxbot.engine.entity.ShelfId;

import java.util.Objects;

/**
 * Where a package to relocate currently comes from.
 */
public sealed interface JobSource {

    record Shelf(ShelfId shelfId) implements JobSource {

        public Shelf {
            Objects.requireNonNull(shelfId, "shelfId must not be null");
        }
    }

    record Bay(PackageId packageId) implements JobSource {

        public Bay {
            Objects.requireNonNull(packageId, "packageId must not be null");
        }
    }
}
