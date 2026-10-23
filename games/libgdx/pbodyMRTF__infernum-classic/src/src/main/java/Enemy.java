

public class Enemy {
    float x;
    float y;
    float speed = 80.0f + (((float) Math.random()) * 120.0f);
    boolean dead = false;

    Enemy(float x, float y) {
        this.x = x;
        this.y = y;
    }

    void update(float dt, float px, float py) {
        float dx = px - this.x;
        float dy = py - this.y;
        float len = (float) Math.sqrt((dx * dx) + (dy * dy));
        this.x += (dx / len) * this.speed * dt;
        this.y += (dy / len) * this.speed * dt;
    }

    public boolean isDead() {
        return this.dead;
    }
}
