//Test rect object
var BasicRect = function(args) {

    GameObject.call(this, args);
    
    this.lTrans.pos = new Vect(args.position.x, args.position.y);
    this.size = size;
    this.color = "#0BF"
    this.collider = new ColliderRect(
        this,
        this.lTrans,
        1);
}

BasicRect.prototype = Object.create(GameObject.prototype);

//Game object update
BasicRect.prototype.update = function(dt, gTrans) {

    GameObject.prototype.update.call(this, dt, gTrans);
}

//Game object draw
BasicRect.prototype.draw = function(ctx) {
    
    ctx.save();
        ctx.setTransformG(this.gTrans);
        
        ctx.fillStyle = this.color;
        ctx.fillRect(
            -this.size.x,
            -this.size.y,
            this.size.x * 2,
            this.size.y * 2);
    ctx.restore();
    
    GameObject.prototype.draw.call(this, ctx);
}