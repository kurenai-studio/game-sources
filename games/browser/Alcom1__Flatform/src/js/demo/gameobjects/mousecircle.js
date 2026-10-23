//Mouse Cursor Circle
var MouseCircle = function(args) {

    GameObject.call(this, args);
    
    this.radius = args.radius;
    this.color = "#FB0"
    this.collider = new ColliderCircle(
        this,
        this.gTrans,
        1,
        this.radius);
}

MouseCircle.prototype = Object.create(GameObject.prototype);

//Game object update
MouseCircle.prototype.update = function(dt, gTrans) {

    this.lTrans.pos = ff.managerMouse.getPos();
    
    this.color = "#FB0";
    
    GameObject.prototype.update.call(this, dt, gTrans);
}

//Game object draw
MouseCircle.prototype.draw = function(ctx) {

    ctx.save();
        ctx.setTransformG(this.gTrans);
        
        ctx.fillStyle = this.color;
        ctx.beginPath();
        ctx.arc(
            0,
            0,
            this.radius,
            0,
            2 * Math.PI, true);
        ctx.fill();
    ctx.restore();
    
    GameObject.prototype.draw.call(this, ctx);
}

//Game object collision
MouseCircle.prototype.collide = function(other, pos) {
    
    this.color = "#F00";
}