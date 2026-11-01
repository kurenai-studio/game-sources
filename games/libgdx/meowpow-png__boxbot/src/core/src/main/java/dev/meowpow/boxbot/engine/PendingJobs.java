package dev.meowpow.boxbot.engine;

import dev.meowpow.boxbot.engine.robot.RobotJob;
import dev.meowpow.boxbot.gdx.ArrayView;
import dev.meowpow.boxbot.gdx.GdxCollections;

import com.badlogic.gdx.utils.Array;

/**
 * Owns pending robot jobs and tracks whether their view must be rebuilt.
 */
final class PendingJobs {

    private final Array<RobotJob> values = new Array<>();
    private final ArrayView<RobotJob> view = GdxCollections.viewOf(values);
    private boolean dirty;

    ArrayView<RobotJob> view() {
        return view;
    }

    void add(RobotJob job) {
        values.add(job);
        dirty = true;
    }

    void remove(RobotJob job) {
        if (values.removeValue(job, false)) {
            dirty = true;
        }
    }

    boolean consumeDirty() {
        boolean wasDirty = dirty;
        dirty = false;
        return wasDirty;
    }
}
