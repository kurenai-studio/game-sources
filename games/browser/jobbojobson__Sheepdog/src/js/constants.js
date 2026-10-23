/*
	Constants for the game and the playing area
*/
//Drawing constants...
var SHEEP_SIZE = 10; //size of sheep 'squares'
var DOG_SIZE = 10; //as above
var MAX_X = 600; //playing area width
var MAX_Y = 400; //playing area height
var PEN_WIDTH = 120;
var PEN_HEIGHT = 80;
//2 element array, the x and y of the top left of the arena
var PEN_ORIGIN = [ ( (MAX_X / 2) - (PEN_WIDTH / 2) ), ( (MAX_Y / 2) - (PEN_HEIGHT / 2) )];

//Gameplay constants...
var ROUND_TIME = 90; //seconds
var PEN_TIME = 5; //seconds
var DOG_SPEED = 1.3;