

import com.badlogic.gdx.Gdx;



class Bullet {
    float x;
    float y;
    float vx;
    float vy;
    float speed = 500.0f;
    boolean dead = false;
    int bounceCount = 0;
    int maxBounces = 5;

    Bullet(float x, float y, float angleDeg) {
        this.x = x - 4.0f;
        this.y = y - 4.0f;
        float rad = (float) Math.toRadians(angleDeg);
        this.vx = ((float) Math.cos(rad)) * this.speed;
        this.vy = ((float) Math.sin(rad)) * this.speed;
    }

    void update(float dt) {
        this.x += this.vx * dt;
        this.y += this.vy * dt;
        float w = Gdx.graphics.getWidth();
        float h = Gdx.graphics.getHeight();
        boolean bounced = false;
        if (this.x <= 0.0f || this.x >= w - 8.0f) {
            this.vx = -this.vx;
            bounced = true;
        }
        if (this.y <= 0.0f || this.y >= h - 8.0f) {
            this.vy = -this.vy;
            bounced = true;
        }
        if (bounced) {
            this.bounceCount++;
            if (this.bounceCount >= this.maxBounces) {
                this.dead = true;
            }
        }
    }

    public boolean isDead() {
        return this.dead;
    }
}
