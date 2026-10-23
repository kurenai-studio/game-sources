//Set canvas transform based on a transformation
CanvasRenderingContext2D.prototype.setTransformG = function(trans) {

    this.setTransform(
        trans.mat2.a,
        trans.mat2.c,
        trans.mat2.b,
        trans.mat2.d,
        trans.pos.x,
        trans.pos.y);    
}

//Canvas point
CanvasRenderingContext2D.prototype.point = function (x, y) {

    this.save();
    this.fillStyle = this.strokeStyle;
    this.beginPath();
    this.arc(
        x,
        y,
        this.lineWidth / 2,
        0,
        2 * Math.PI, true);
    this.fill();
    this.restore();
}

//Modified mod for negative numbers.
Number.prototype.mod = function(n) {

	return ((this % n) + n) % n;
}