//Test rect object that rotates and resizes to match the mouse position.
var StretchRect = function(args) {

    GameObject.call(this, args);
    
    this.lTrans.pos = new Vect(args.position.x, args.position.y);
    this.size = new Vect(0.8, 1);
    this.color = "#AAA"
    this.collider = new ColliderPoint(
        this,
        this.lTrans,
        4);
}

StretchRect.prototype = Object.create(GameObject.prototype);

//Game object update
StretchRect.prototype.update = function(dt, gTrans) {

    var mouseDiff = ff.managerMouse.getPos().getSub(this.lTrans.pos);
    this.lTrans = new Transform(1, 0, 0, 1, 0, 0);
    this.lTrans.mat2.rotateToFace(mouseDiff);
    this.lTrans.scale(mouseDiff.getMagnitude(), mouseDiff.getMagnitude());
    this.lTrans.translate(320, 240);

    GameObject.prototype.update.call(this, dt, gTrans);
}

//Game object draw
StretchRect.prototype.draw = function(ctx) {
    
    ctx.save();
        ctx.setTransformG(this.gTrans);
        
        //Draw rect
        ctx.fillStyle = this.color;
        ctx.fillRect(
            -this.size.x,
            -this.size.y,
             this.size.x * 2,
             this.size.y * 2);
    ctx.restore();
    
    GameObject.prototype.draw.call(this, ctx);
}