import Hero from './Hero';
import Blocks from './Blocks';
import player from './Player';
import { collides } from './utils';

export default class Collisions {
    static handle() {
        Hero.bullets.forEach(bullet => {
            Blocks.data.forEach(block => {
                if (collides(bullet, block)) {
                    bullet.active = false;
                    block.points -= 1;
                    player.score += 1;
                }
            });
        });
        Blocks.data.forEach(block => {
            if (collides(Hero, block)) {
                player.lost = true;
            }
        });
    }
}
