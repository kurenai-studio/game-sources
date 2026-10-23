//Animation constructor
var Animation = function(anim) {

    this.length = anim.length;          //Duration of animation in milliseconds
    this.rotate = anim.rotate;          //Rotation transformation keyframes array.
    this.scale = anim.scale;            //Scaling transformation keyframes array.
    this.translate = anim.translate;    //Translation transformation keyframes array.
    this.time = 0;                      //Current time of the animation.
}

//Update
Animation.prototype.update = function(dt) {

    this.time += dt;    //Increment time.
}

//Draw
Animation.prototype.transform = function() {

    var step = (this.time * 1000) % this.length;    //Time in the current loop
    
    var transform = new Transform(1, 0, 0, 1, 0, 0);
    
    this.transformPartial(transform, step, this.rotate, TYPE_ANIM.ROTATE);
    this.transformPartial(transform, step, this.scale, TYPE_ANIM.SCALE);
    this.transformPartial(transform, step, this.translate, TYPE_ANIM.TRANSLATE);
    
    return transform;
}

//Perform a partial transformation based on its type
Animation.prototype.transformPartial = function(
    trans,
    step,   //Time in the current loop
    form,   //Which transform to use
    type) { //Type of transform

    //For each timestamp in the animation
    for(var i = 0; i < form.length - 1; i++) {
        
        //If the animation is currently between that timestamp and the next, transform
        if(step > form[i].time && step < form[i + 1].time) {
            //Translation, scale, or rotation
            switch(type) {

                case TYPE_ANIM.TRANSLATE:
                    trans.translate(
                        map(
                            step, 
                            form[i].time, 
                            form[i + 1].time, 
                            form[i].move[0], 
                            form[i + 1].move[0]),
                        map(
                            step, 
                            form[i].time, 
                            form[i + 1].time, 
                            form[i].move[1], 
                            form[i + 1].move[1]));
                    break;
                    
                case TYPE_ANIM.SCALE:
                    trans.scale(
                        map(
                            step, 
                            form[i].time, 
                            form[i + 1].time, 
                            form[i].move[0], 
                            form[i + 1].move[0]),
                        map(
                            step, 
                            form[i].time, 
                            form[i + 1].time, 
                            form[i].move[1], 
                            form[i + 1].move[1]));
                    break;
                    
                case TYPE_ANIM.ROTATE:
                    trans.rotate(
                        map(
                            step, 
                            form[i].time, 
                            form[i + 1].time, 
                            form[i].move * Math.PI / 180, 
                            form[i + 1].move * Math.PI / 180));
                    break;
            }
            
            break;
        }
    }    
}

//Enums
TYPE_ANIM = Object.freeze({
    TRANSLATE: 0,
    SCALE: 1,
    ROTATE: 2});