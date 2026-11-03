import { CANVAS_WIDTH, CANVAS_HEIGHT, ctx } from './Canvas';
import player from './Player';
import Hero from './Hero';

export default class Draw {

    static background() {
        ctx.fillStyle = "#111";
        ctx.fillRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
    }

    static score() {
        ctx.textAlign = "start";
        ctx.fillStyle = "white";
        ctx.font = "Arial 20px";
        ctx.fillText(`Score: ${player.score}`, 20, 50);
    }

    static level() {
        ctx.textAlign = "start";
        ctx.fillStyle = "white";
        ctx.font = "Arial 20px";
        ctx.fillText(`Level: ${Math.floor(Hero.level)}`, 20, 75);
    }

}
