/*
	Class to represent a timer that counts either up or down in seconds
*/
function Timer(){
	var id = null;
	var _this = this;
	
	_this.time = 0;
	_this.isReversed = false;
	_this.isRunning = false;
	
	var tick = function(){
		if(_this.isReversed){
			_this.time--;
			if(_this.time <= 0){
				_this.stop();
			} else {
				id = setTimeout(tick, 1000);	
			}
		} else {
			_this.time++;
			id = setTimeout(tick, 1000);
		}
	}
	
	_this.start = function(){
		if(! _this.isRunning){
			_this.isRunning = true;
			id = setTimeout(tick, 1000);
		}
 	}
	
	_this.stop = function(){
		clearTimeout(id);
		_this.isRunning = false;
	}
	
}