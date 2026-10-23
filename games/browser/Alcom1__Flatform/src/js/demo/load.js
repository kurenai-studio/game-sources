//Load
window.onload = function() {

    //Modules.
	ff.managerSound.init(document.querySelector("#audio"), 0.4);
	ff.managerCollision.init();
	ff.managerMouse.init();
	
	//Main
	ff.main.init(document.querySelector('canvas'), "js/demo/assets/scene_sample_0.json");
}