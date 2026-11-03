import {ctx} from './Canvas';

export default function Bullet(bullet) {
    
    bullet.w = 10;
    bullet.h = 10;
    bullet.color = "white";
    bullet.yVelocity = -bullet.speed;
    bullet.active = true;
    
    bullet.draw = function() {
        ctx.fillStyle = bullet.color;
        ctx.beginPath();
        ctx.arc(bullet.x, bullet.y, bullet.w / 2, 0, Math.PI * 2);
        ctx.fill();
    };
    
    bullet.inBounds = function() {
        return bullet.y >= 0;
    };

    bullet.update = function() {
        bullet.y += bullet.yVelocity;
        bullet.active = bullet.active && bullet.inBounds();
    };

    return bullet;
}