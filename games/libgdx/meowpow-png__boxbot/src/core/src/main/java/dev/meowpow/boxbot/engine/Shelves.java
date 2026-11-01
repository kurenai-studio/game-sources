package dev.meowpow.boxbot.engine;

import dev.meowpow.boxbot.engine.entity.Package;
import dev.meowpow.boxbot.engine.entity.Shelf;
import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.gdx.ArrayView;
import dev.meowpow.boxbot.gdx.GdxCollections;

import org.jspecify.annotations.Nullable;

import com.badlogic.gdx.utils.Array;

/**
 * Owns shelves and tracks occupancy
 * changes for derived shelf views.
 */
final class Shelves {

    private final Array<Shelf> values = new Array<>();
    private final ArrayView<Shelf> view = GdxCollections.viewOf(values);

    private boolean occupancyDirty;

    Shelves(ArrayView<Shelf> shelves) {
        for (int i = 0; i < shelves.size(); i++) {
            values.add(shelves.get(i));
        }
    }

    ArrayView<Shelf> view() {
        return view;
    }

    void setOccupyingPackage(ShelfId shelfId, @Nullable Package pkg) {
        byId(shelfId).setOccupyingPackage(pkg);
        occupancyDirty = true;
    }

    Shelf byId(ShelfId shelfId) {
        for (int i = 0; i < values.size; i++) {
            var shelf = values.get(i);
            if (shelf.id().equals(shelfId)) {
                return shelf;
            }
        }
        throw new IllegalStateException("No shelf with id " + shelfId);
    }

    boolean consumeOccupancyChanges() {
        boolean wasDirty = occupancyDirty;
        occupancyDirty = false;
        return wasDirty;
    }
}
