//Animated rectangle
var AnimatedRect = function(args) {
    
    GameObject.call(this, args);
    
    this.animation = new Animation(loadJson(args.anim));
    this.size = args.size;
    this.color = args.color;
    this.collider = new ColliderRect(
        this,
        this.gTrans,
        2,
        this.size);
    this.colliding = false;
}

AnimatedRect.prototype = Object.create(GameObject.prototype);

//Game object update
AnimatedRect.prototype.update = function(dt, gTrans)
{
    this.colliding = false;

    this.lTrans = this.animation.transform();
    this.animation.update(dt);
    
    GameObject.prototype.update.call(this, dt, gTrans);
}

//Game object draw
AnimatedRect.prototype.draw = function(ctx)
{
    
    //Rect
    ctx.save();
        ctx.setTransformG(this.gTrans);
        
        //Draw rect
        ctx.fillStyle = this.colliding ? "#F00" : this.color;
        ctx.fillRect(
            -this.size.x,
            -this.size.y,
             this.size.x * 2,
             this.size.y * 2);
    ctx.restore();
    
    GameObject.prototype.draw.call(this, ctx);
}

//Game object collision
AnimatedRect.prototype.collide = function(other, pos)
{
    this.colliding = true;
}