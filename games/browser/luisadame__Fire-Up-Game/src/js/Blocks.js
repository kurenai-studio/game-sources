import { CANVAS_WIDTH } from './Canvas';
import Block from './Block';
import { rand } from './utils';

let Blocks = {
    data: [],
    init: () => {
        Blocks.data = [];
        let width = 100;
        let n = Math.floor(CANVAS_WIDTH / width);
        let remainder = (CANVAS_WIDTH % width) / n;
        for (let i = 0; i < n; i++) {
            Blocks.data.push(new Block({
                color: `rgb(${rand(0, 255)}, ${rand(0, 255)}, ${rand(0, 255)})`,
                w: width,
                x: (width + remainder) * i,
                y: 50
            }));
        }
    },
    update: function () {
        this.draw();
        Blocks.data.forEach(block => block.update());
        Blocks.data = Blocks.data.filter(block => block.active);
        if (Blocks.data.length == 0) this.init();
    },
    draw: () => {
        Blocks.data.forEach(block => block.draw());
    }
}

export default Blocks;
