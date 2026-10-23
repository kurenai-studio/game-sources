//Key handler

//OL with key arrays and methods.
var keys = {

	//Array of key states
	//0 == up
	//1 == pressed
	//2 == down
	//3 == released
	states : [],
	
	//Keys refered to by name
	KEYBOARD : Object.freeze ({
		"BACKSPACE" : 8,
		"TAB" : 9,
		"ENTER" : 13,
		"SHIFT" : 16,
		"CTRL" : 17,
		"ALT" : 18,
		"PAUSE" : 19,
		"CAPS" : 20,
		"ESC" : 27,
		"SPACE" : 32,
		
		"PAGEUP" : 33,
		"PAGEDOWN" : 34,
		"END" : 35,
		"HOME" : 36,
		"INSERT" : 45,
		"DELETE" : 46,
		
		"LEFT" : 37, 
		"UP" : 38, 
		"RIGHT" : 39, 
		"DOWN" : 40,
		
		"0" : 48,
		"1" : 49,
		"2" : 50,
		"3" : 51,
		"4" : 52,
		"5" : 53,
		"6" : 54,
		"7" : 55,
		"8" : 56,
		"9" : 57,
		
		"A" : 65,
		"B" : 66,
		"C" : 67,
		"D" : 68,
		"E" : 69,
		"F" : 70,
		"G" : 71,
		"H" : 72,
		"I" : 73,
		"J" : 74,
		"K" : 75,
		"L" : 76,
		"M" : 77,
		"N" : 78,
		"O" : 79,
		"P" : 80,
		"Q" : 81,
		"R" : 82,
		"S" : 83,
		"T" : 84,
		"U" : 85,
		"V" : 86,
		"W" : 87,
		"X" : 88,
		"Y" : 89,
		"Z" : 90,
		
		"NUM0" : 96,
		"NUM1" : 97,
		"NUM2" : 98,
		"NUM3" : 99,
		"NUM4" : 100,
		"NUM5" : 101,
		"NUM6" : 102,
		"NUM7" : 103,
		"NUM8" : 104,
		"NUM9" : 105,
		
		"ADD" : 107,
		"SUB" : 109,
		"MULT" : 106,
		"DIV" : 111,
		"DEC" : 110,
		
		"F1" : 112,
		"F2" : 113,
		"F3" : 114,
		"F4" : 115,
		"F5" : 116,
		"F6" : 117,
		"F7" : 118,
		"F8" : 119,
		"F9" : 120,
		"F10" : 121,
		"F11" : 122,
		"F12" : 123,
		
		"NUMLOCK" : 144,
		"SCROLLLOCK" : 145,
		"SEMICOLON" : 186,
		"EQUAL" : 187,
		"COMMA" : 188,
		"DASH" : 189,
		"PERIOD" : 190,
		"FORWARDSLASH" : 191,
		"BACKSLASH" : 220,
		"TILDE" : 192,
		"OPENBRACKET" : 219,
		"CLOSEBRACKET" : 221,
		"QUOTE" : 222
	}),
	
	//Key states
	STATE : Object.freeze ({

		"UP" : 0,
		"PRESSED" : 1,
		"DOWN" : 2,
		"RELEASED" : 3 
	}),
	
	//Refreshes pressed and released states to down and up
	refresh : function() {

		for(var i = 0; i < this.states.length; i++) {

			if(this.states[i] == this.STATE.PRESSED)   //Pressed to down
				this.states[i] = this.STATE.DOWN;
			if(this.states[i] == this.STATE.RELEASED)   //Released to up
				this.states[i] = this.STATE.UP;
		}
	},
	
	//key state queries
	isUp : function(key) {

		key = this.setCompatible(key);
		return !keys.states[key];
	},
	
	isPressed : function(key) {
		
		key = this.setCompatible(key);
		return keys.states[key] == this.STATE.PRESSED;
	},
	
	isDown : function(key) {

		key = this.setCompatible(key);
		return keys.states[key] == this.STATE.DOWN;
	},
	
	isReleased : function(key) {

		key = this.setCompatible(key);
		return keys.states[key] == this.STATE.RELEASED;
	},
	
	//Performs compatibility fix between browsers for key values.
	setCompatible(key) {

		if(key == 59)   //FF Semicolon
			key = 186;
		
		if(key == 61)   //FF Dash
			key = 187;
			
		if(key == 173)  //FF Minus
			key = 189;
		
		return key;
	}
};

//Set that key is down to keys
window.addEventListener(
	"keydown",
	function(e) {

		if(!keys.states[e.keyCode])
			keys.states[e.keyCode] = 1;
	});

//Set that key is up to keys
window.addEventListener(
	"keyup",
	function(e) {
		
		keys.states[e.keyCode] = 3;
	});