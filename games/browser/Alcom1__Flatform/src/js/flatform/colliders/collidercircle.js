var ColliderCircle = function(parent, transform, mask, radius) {

    Collider.call(this, parent, transform, TYPE_COLL.CIRCLE, mask);
    this.radius = radius;
}

ColliderCircle.prototype = Object.create(Collider.prototype);

ColliderCircle.prototype.draw = function(ctx) {

    ctx.save();
        ctx.translate(this.transform.pos.x, this.transform.pos.y);
        
        ctx.strokeStyle="#FFFF00";
        ctx.lineWidth = 5;
        ctx.beginPath();
        ctx.arc(
            0,
            0,
            this.radius,
            0,
            2 * Math.PI, true);
        ctx.stroke();
    ctx.restore();
}

//Collision check
ColliderCircle.prototype.checkCollision = function(other) {

    switch(other.type) {

        case TYPE_COLL.POINT:
            if(collisionPointCircle(this, other)) {

                this.parent.collide(other, new Vect(0, 0));
                other.parent.collide(this, new Vect(0, 0));
            }
            break;

        case TYPE_COLL.RECT:
            if(collisionRectCircle(this, other)) {

                this.parent.collide(other, new Vect(0, 0));
                other.parent.collide(this, new Vect(0, 0));
            }
            break;

        case TYPE_COLL.CIRCLE:
            if(collisionCircleCircle(this, other)) {

                this.parent.collide(other, new Vect(0, 0));
                other.parent.collide(this, new Vect(0, 0));
            }
            break;

        case TYPE_COLL.TRI:
            if(collisionCircleTri(this, other)) {
                
                this.parent.collide(other, new Vect(0, 0));
                other.parent.collide(this, new Vect(0, 0));
            }
            break;
    }   
}