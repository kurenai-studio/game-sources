//ff
var ff = ff || {};

//Module that plays and manages sounds.
ff.managerCollision = (function() {

    var colliders;	//Array of colliders
    
	//Init
	function init() {

		colliders = [];
	}
	
	//Update
	function update() {

		for(var j = 0; j < colliders.length; j++) {

			colliders[j].update();
			
			for(i = 0; i < j; i++) {

				if(colliders[i].mask & colliders[j].mask)
					colliders[j].checkCollision(colliders[i]);
			}
		}
	}
	
	//Draw
	function draw(ctx) {

		for(i = 0; i < colliders.length; i++) {

			colliders[i].draw(ctx);
		}
	}
	
	//
	function add(collider) {

		colliders.push(collider);
	}
	
	//
	function remove(target) {

		for(i = 0; i < colliders.length; i++) {

			if(colliders[i] == target) {

				colliders.splice(i, 1);
				break;
			}
		}
	}
    
	//
	function clear() {

		colliders = [];
	}
	
	//Return
	return {
		init : init,
		update : update,
		draw : draw,
		add : add,
		remove : remove,
		clear : clear
	}
	
}());