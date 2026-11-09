using UnityEngine;

public class Timer {
    private int targetMs;
    private int counterMs;

    public Timer() {
        targetMs = -1;
        counterMs = 0;
    }

    public void Set(int timeMs) {
        counterMs = 0;
        targetMs = timeMs;
    }

    public void Update() {
        int elapsedMillis = (int) (Time.deltaTime * 1000);
        counterMs += elapsedMillis;
    }

    public bool Check() {
        return (counterMs >= targetMs);
    }
    
    public float GetProgress() {
        if (targetMs == -1) return 0f;

        var progress = (float) counterMs / (float) targetMs;
        return progress > 1f ? 1f : progress;
    }
}