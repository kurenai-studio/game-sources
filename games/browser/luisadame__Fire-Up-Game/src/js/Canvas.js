const CANVAS_WIDTH = innerWidth, CANVAS_HEIGHT = innerHeight;

function resize() {
    let canvas = document.getElementById('canvas');
    canvas.width = CANVAS_WIDTH;
    canvas.height = CANVAS_HEIGHT;
}
resize();
const ctx = canvas.getContext('2d');

export { resize, CANVAS_WIDTH, CANVAS_HEIGHT, ctx };
