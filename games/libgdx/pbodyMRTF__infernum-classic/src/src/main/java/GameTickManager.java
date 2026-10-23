

import com.badlogic.gdx.utils.Array;


public class GameTickManager {
    private static final float TICK_RATE = 0.05f;
    private float tickTimer = 0.0f;
    private int currentTick = 0;
    private Array<TickListener> listeners = new Array<>();

    
    public interface TickListener {
        void onTick(int r1);
    }

    public void update(float delta) {
        this.tickTimer += delta;
        while (this.tickTimer >= 0.05f) {
            tick();
            this.tickTimer -= 0.05f;
            this.currentTick++;
        }
    }

    private void tick() {
        Array.ArrayIterator<TickListener> it = this.listeners.iterator();
        while (it.hasNext()) {
            TickListener listener = it.next();
            listener.onTick(this.currentTick);
        }
    }

    public void addListener(TickListener listener) {
        this.listeners.add(listener);
    }

    public void removeListener(TickListener listener) {
        this.listeners.removeValue(listener, true);
    }

    public int getCurrentTick() {
        return this.currentTick;
    }

    public boolean isTickMultiple(int multiple) {
        return this.currentTick % multiple == 0;
    }

    public boolean hasTicksPassed(int lastTick, int ticksToWait) {
        return this.currentTick - lastTick >= ticksToWait;
    }

    public void reset() {
        this.tickTimer = 0.0f;
        this.currentTick = 0;
    }

    
    public static class TickTimer {
        private int startTick;
        private int duration;
        private boolean running = false;

        public TickTimer(int durationInTicks) {
            this.duration = durationInTicks;
        }

        public void start(int currentTick) {
            this.startTick = currentTick;
            this.running = true;
        }

        public boolean isFinished(int currentTick) {
            return this.running && currentTick - this.startTick >= this.duration;
        }

        public void stop() {
            this.running = false;
        }

        public boolean isRunning() {
            return this.running;
        }

        public int getRemainingTicks(int currentTick) {
            if (!this.running) {
                return 0;
            }
            int elapsed = currentTick - this.startTick;
            return Math.max(0, this.duration - elapsed);
        }

        public float getRemainingSeconds(int currentTick) {
            return getRemainingTicks(currentTick) * 0.05f;
        }
    }
}
