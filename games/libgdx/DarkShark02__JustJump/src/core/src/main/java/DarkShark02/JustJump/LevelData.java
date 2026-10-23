package DarkShark02.JustJump;

import java.util.ArrayList;

// Questa classe serve a mappare la struttura dei tuoi file JSON.
// I nomi dei campi devono corrispondere esattamente alle chia chiavi nel JSON.
public class LevelData {
    public int backgroundType;
    public float playerStartX, playerStartY;
    public ArrayList<SpikeData> spikes = new ArrayList<>();
    public ArrayList<HeartData> hearts = new ArrayList<>();
    public ArrayList<StarData> stars = new ArrayList<>();
    public ArrayList<BeeData> bees = new ArrayList<>();
    public ArrayList<SnowPatchData> snowPatches = new ArrayList<>();
    public ArrayList<SpringData> springs = new ArrayList<>();
    public float exitX; // Coordinata X che il player deve raggiungere per finire il livello
    public float levelWidth;

    // Classi interne statiche per i dati degli oggetti specifici
    public static class SpikeData {
        public float x, y;
        // Nessun costruttore vuoto esplicito necessario per JsonValue, ma averlo non fa male
        public SpikeData() {}
        public SpikeData(float x, float y) { this.x = x; this.y = y; }
    }

    public static class HeartData {
        public float x, y;
        public HeartData() {}
        public HeartData(float x, float y) { this.x = x; this.y = y; }
    }

    public static class StarData {
        public float x, y;
        public StarData() {}
        public StarData(float x, float y) { this.x = x; this.y = y; }
    }

    public static class BeeData {
        public float x, y, initialVelocityX;
        public BeeData() {}
        public BeeData(float x, float y, float initialVelocityX) {
            this.x = x; this.y = y; this.initialVelocityX = initialVelocityX;
        }
    }

    public static class SnowPatchData {
        public float x, y, width, height;
        public SnowPatchData() {}
        public SnowPatchData(float x, float y, float width, float height) {
            this.x = x; this.y = y; this.width = width; this.height = height;
        }
    }

    public static class SpringData {
        public float x, y;
        public SpringData() {}
        public SpringData(float x, float y) { this.x = x; this.y = y; }
    }
}