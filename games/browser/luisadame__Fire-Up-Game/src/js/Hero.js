import { CANVAS_WIDTH, CANVAS_HEIGHT, ctx } from './Canvas';
import Bullet from './Bullet';

let Hero = {
    color: "red",
    w: 100,
    h: 100,
    x: CANVAS_WIDTH / 2,
    y: CANVAS_HEIGHT - 110,
    speed: 5,
    bullets: [],
    shot: 0,
    level: 1,
    shootingSpeed: function () {
        let v = 705 - (this.level * 10);
        return v;
    },
    draw: function () {
        ctx.fillStyle = this.color;
        ctx.fillRect(this.x, this.y, this.w, this.h);
    },
    update: function () {
        this.draw();
        this.shoot();
        this.bullets.forEach(bullet => bullet.draw());
        this.bullets.forEach(bullet => bullet.update());
        this.bullets = this.bullets.filter(bullet => bullet.active);
    },
    shoot: function () {
        if (performance.now() - this.shot >= this.shootingSpeed()) {
            this.bullets.push(new Bullet({
                speed: 5 + Hero.level,
                x: this.x + this.w / 2,
                y: this.y
            }));
            this.shot = performance.now();
        }
    },
    moveLeft: function () {
        if (this.x > 0) {
            this.x -= this.speed;
        }
    },
    moveRight: function () {
        if (this.x < CANVAS_WIDTH - this.w) {
            this.x += this.speed;
        }
    },
    inBounds: function () {
        return this.x > 0 && this.x < CANVAS_WIDTH - this.w;
    },
    reset: function () {
        this.level = 1;
        this.shot = 0;
    }
};

export default Hero;
