

import com.badlogic.gdx.graphics.Texture;


public class BloodParticle {
    float x;
    float y;
    float vx;
    float vy;
    Texture tex;
    float life = 0.5f;
    boolean dead = false;
    float lifetime = 0.0f;

    public BloodParticle(float x, float y, Texture tex) {
        this.x = x;
        this.y = y;
        this.tex = tex;
        float angle = (float) (Math.random() * 2.0d * 3.141592653589793d);
        float speed = 50.0f + ((float) (Math.random() * 100.0d));
        this.vx = ((float) Math.cos(angle)) * speed;
        this.vy = ((float) Math.sin(angle)) * speed;
    }

    public void update(float dt) {
        this.x += this.vx * dt;
        this.y += this.vy * dt;
        this.lifetime += dt;
        if (this.lifetime > 1.5f) {
            this.dead = true;
        }
    }

    public boolean isDead() {
        return this.life <= 0.0f;
    }
}
