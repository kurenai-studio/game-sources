//Test point object
var TextDrawer = function(args) {

    GameObject.call(this, args);
    
    this.lTrans.pos = new Vect(args.position.x, args.position.y);
    this.text = args.text;
    this.font = args.font || "16pt Consolas";
    this.color = args.color || "white";
    this.centered = !!args.centered;
}

TextDrawer.prototype = Object.create(GameObject.prototype);

//Game object draw
TextDrawer.prototype.draw = function(ctx) {
    
    ctx.save();
        ctx.setTransformG(this.gTrans);

        if(this.centered)
        {
            ctx.textAlign = "center";
            ctx.textBaseline = "middle"; 
        }
        ctx.font = this.font;
        ctx.fillStyle = this.color; 
        ctx.fillText(this.text, 0, 0);
    ctx.restore();
    
    GameObject.prototype.draw.call(this, ctx);
}