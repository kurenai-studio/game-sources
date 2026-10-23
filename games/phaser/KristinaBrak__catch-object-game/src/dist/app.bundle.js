/******/ (function(modules) { // webpackBootstrap
/******/ 	// install a JSONP callback for chunk loading
/******/ 	function webpackJsonpCallback(data) {
/******/ 		var chunkIds = data[0];
/******/ 		var moreModules = data[1];
/******/ 		var executeModules = data[2];
/******/
/******/ 		// add "moreModules" to the modules object,
/******/ 		// then flag all "chunkIds" as loaded and fire callback
/******/ 		var moduleId, chunkId, i = 0, resolves = [];
/******/ 		for(;i < chunkIds.length; i++) {
/******/ 			chunkId = chunkIds[i];
/******/ 			if(Object.prototype.hasOwnProperty.call(installedChunks, chunkId) && installedChunks[chunkId]) {
/******/ 				resolves.push(installedChunks[chunkId][0]);
/******/ 			}
/******/ 			installedChunks[chunkId] = 0;
/******/ 		}
/******/ 		for(moduleId in moreModules) {
/******/ 			if(Object.prototype.hasOwnProperty.call(moreModules, moduleId)) {
/******/ 				modules[moduleId] = moreModules[moduleId];
/******/ 			}
/******/ 		}
/******/ 		if(parentJsonpFunction) parentJsonpFunction(data);
/******/
/******/ 		while(resolves.length) {
/******/ 			resolves.shift()();
/******/ 		}
/******/
/******/ 		// add entry modules from loaded chunk to deferred list
/******/ 		deferredModules.push.apply(deferredModules, executeModules || []);
/******/
/******/ 		// run deferred modules when all chunks ready
/******/ 		return checkDeferredModules();
/******/ 	};
/******/ 	function checkDeferredModules() {
/******/ 		var result;
/******/ 		for(var i = 0; i < deferredModules.length; i++) {
/******/ 			var deferredModule = deferredModules[i];
/******/ 			var fulfilled = true;
/******/ 			for(var j = 1; j < deferredModule.length; j++) {
/******/ 				var depId = deferredModule[j];
/******/ 				if(installedChunks[depId] !== 0) fulfilled = false;
/******/ 			}
/******/ 			if(fulfilled) {
/******/ 				deferredModules.splice(i--, 1);
/******/ 				result = __webpack_require__(__webpack_require__.s = deferredModule[0]);
/******/ 			}
/******/ 		}
/******/
/******/ 		return result;
/******/ 	}
/******/
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// object to store loaded and loading chunks
/******/ 	// undefined = chunk not loaded, null = chunk preloaded/prefetched
/******/ 	// Promise = chunk loading, 0 = chunk loaded
/******/ 	var installedChunks = {
/******/ 		"app": 0
/******/ 	};
/******/
/******/ 	var deferredModules = [];
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, { enumerable: true, get: getter });
/******/ 		}
/******/ 	};
/******/
/******/ 	// define __esModule on exports
/******/ 	__webpack_require__.r = function(exports) {
/******/ 		if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 			Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 		}
/******/ 		Object.defineProperty(exports, '__esModule', { value: true });
/******/ 	};
/******/
/******/ 	// create a fake namespace object
/******/ 	// mode & 1: value is a module id, require it
/******/ 	// mode & 2: merge all properties of value into the ns
/******/ 	// mode & 4: return value when already ns object
/******/ 	// mode & 8|1: behave like require
/******/ 	__webpack_require__.t = function(value, mode) {
/******/ 		if(mode & 1) value = __webpack_require__(value);
/******/ 		if(mode & 8) return value;
/******/ 		if((mode & 4) && typeof value === 'object' && value && value.__esModule) return value;
/******/ 		var ns = Object.create(null);
/******/ 		__webpack_require__.r(ns);
/******/ 		Object.defineProperty(ns, 'default', { enumerable: true, value: value });
/******/ 		if(mode & 2 && typeof value != 'string') for(var key in value) __webpack_require__.d(ns, key, function(key) { return value[key]; }.bind(null, key));
/******/ 		return ns;
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	var jsonpArray = window["webpackJsonp"] = window["webpackJsonp"] || [];
/******/ 	var oldJsonpFunction = jsonpArray.push.bind(jsonpArray);
/******/ 	jsonpArray.push = webpackJsonpCallback;
/******/ 	jsonpArray = jsonpArray.slice();
/******/ 	for(var i = 0; i < jsonpArray.length; i++) webpackJsonpCallback(jsonpArray[i]);
/******/ 	var parentJsonpFunction = oldJsonpFunction;
/******/
/******/
/******/ 	// add entry module to deferred list
/******/ 	deferredModules.push([0,"vendors"]);
/******/ 	// run deferred modules when ready
/******/ 	return checkDeferredModules();
/******/ })
/************************************************************************/
/******/ ({

/***/ "./node_modules/webpack/hot sync ^\\.\\/log$":
/*!*************************************************!*\
  !*** (webpack)/hot sync nonrecursive ^\.\/log$ ***!
  \*************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

var map = {
	"./log": "./node_modules/webpack/hot/log.js"
};


function webpackContext(req) {
	var id = webpackContextResolve(req);
	return __webpack_require__(id);
}
function webpackContextResolve(req) {
	if(!__webpack_require__.o(map, req)) {
		var e = new Error("Cannot find module '" + req + "'");
		e.code = 'MODULE_NOT_FOUND';
		throw e;
	}
	return map[req];
}
webpackContext.keys = function webpackContextKeys() {
	return Object.keys(map);
};
webpackContext.resolve = webpackContextResolve;
module.exports = webpackContext;
webpackContext.id = "./node_modules/webpack/hot sync ^\\.\\/log$";

/***/ }),

/***/ "./src/bar.ts":
/*!********************!*\
  !*** ./src/bar.ts ***!
  \********************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var Bar = /** @class */ (function () {
    function Bar(_a) {
        var scene = _a.scene, x = _a.x, y = _a.y, status = _a.status;
        this.bar_size = {
            width: 200,
            height: 25,
        };
        this.bar_frame_size = this.bar_size.width * 0.02;
        this.scene = scene;
        this.bar_display = new Phaser.GameObjects.Graphics(scene);
        this.bar_display.setX(x);
        this.bar_display.setY(y);
        this.bar_display.setDepth(0.99);
        this._status = status;
        this.draw();
        scene.add.existing(this.bar_display);
    }
    Bar.prototype.draw = function () {
        this.bar_display.clear();
        this.createEmptyStatusBar();
        this.displayStatusChange();
        this.displayName();
    };
    Bar.prototype.displayName = function () {
        var name = this._status.name;
        text: Phaser.GameObjects.Text;
        var _a = this.calculateTextPosition(), x = _a.x, y = _a.y;
        var text = this.scene.add.text(x, y, name, { color: "000" });
        text.depth = 1;
    };
    Bar.prototype.calculateTextPosition = function () {
        return {
            x: this.bar_display.x * 2 + this.bar_frame_size + 5,
            y: this.bar_display.y * 2 + this.bar_frame_size,
        };
    };
    Bar.prototype.createEmptyStatusBar = function () {
        //  Creating black fream and white background
        this.bar_display.fillStyle(0x000000);
        this.bar_display.fillRect(this.bar_display.x, this.bar_display.y, this.bar_size.width, this.bar_size.height);
        this.bar_display.fillStyle(0xffffff);
        this.bar_display.fillRect(this.bar_display.x + this.bar_frame_size, this.bar_display.y + this.bar_frame_size, this.bar_size.width - this.bar_frame_size * 2, this.bar_size.height - this.bar_frame_size * 2);
    };
    Bar.prototype.displayStatusChange = function () {
        if (this._status.current_value !== 0) {
            this.changeStatusColor();
            var distance = Math.floor((this._status.current_value / this._status.max_value) *
                this.bar_size.width -
                this.bar_frame_size * 2);
            this.bar_display.fillRect(this.bar_display.x + this.bar_frame_size, this.bar_display.y + this.bar_frame_size, distance, this.bar_size.height - this.bar_frame_size * 2);
        }
    };
    Bar.prototype.changeStatusColor = function () {
        if (this._status.current_value <= 30) {
            this.bar_display.fillStyle(0xff0000);
        }
        else if (this._status.current_value <= 60) {
            this.bar_display.fillStyle(0xff9933);
        }
        else if (this._status.current_value <= 90) {
            this.bar_display.fillStyle(0xfff000);
        }
        else {
            this.bar_display.fillStyle(0x00ff00);
        }
    };
    Object.defineProperty(Bar.prototype, "status", {
        set: function (status) {
            this._status = status;
            this.draw();
        },
        enumerable: true,
        configurable: true
    });
    return Bar;
}());
exports.Bar = Bar;


/***/ }),

/***/ "./src/bed.ts":
/*!********************!*\
  !*** ./src/bed.ts ***!
  \********************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var Bed = /** @class */ (function () {
    function Bed(scene, name) {
        this.scene = scene;
        this.sprite = this.scene.physics.add.sprite(this.scene.scale.width, this.scene.scale.height, name);
        this.sprite.setScale(2, 2);
        this.sprite.setOrigin(1, 1); //rightbottom corner
        this.sprite.setDepth(0);
        this.used = false;
        this.createShade();
    }
    Bed.prototype.sleep = function () {
        console.log("sleepu sleepu");
        // this.scene.cameras.main.backgroundColor = Phaser.Display.Color.HexStringToColor("#3498db");
        this.shade.setAlpha(0.98);
    };
    Bed.prototype.createShade = function () {
        console.log("create shade");
        this.shade = new Phaser.GameObjects.Graphics(this.scene);
        this.shade.fillStyle(0x000000);
        this.shade.fillRect(0, 0, this.scene.scale.width, this.scene.scale.height);
        this.shade.setDepth(0.98);
        this.shade.setAlpha(0);
    };
    return Bed;
}());
exports.default = Bed;


/***/ }),

/***/ "./src/chased-object.ts":
/*!******************************!*\
  !*** ./src/chased-object.ts ***!
  \******************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var ChasedObject = /** @class */ (function () {
    function ChasedObject(scene, player, key) {
        this.exist = 0;
        this.scene = scene;
        this.player = player;
        var x = Math.random() * this.scene.cameras.main.centerX * 2;
        var y = Math.random() * this.scene.cameras.main.centerY * 2;
        this.exist += 1;
        this.sprite = scene.physics.add.sprite(x, y, 'heart');
    }
    ChasedObject.prototype.move = function () {
        while (Phaser.Math.Distance.Between(this.sprite.x, this.sprite.y, this.player.sprite.x, this.player.sprite.y) < 100) {
            var x = Math.random() * this.scene.cameras.main.centerX * 2;
            var y = Math.random() * this.scene.cameras.main.centerY * 2;
            this.sprite.x = x;
            this.sprite.y = y;
        }
    };
    return ChasedObject;
}());
exports.default = ChasedObject;


/***/ }),

/***/ "./src/data-handler/data-handler.ts":
/*!******************************************!*\
  !*** ./src/data-handler/data-handler.ts ***!
  \******************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var status_1 = __webpack_require__(/*! ../status */ "./src/status.ts");
var DataHandler = /** @class */ (function () {
    function DataHandler(player) {
        this.actions = ["statuses"];
        this.player = player;
    }
    DataHandler.prototype.getMessage = function (message) {
        var json = JSON.parse(message);
        // console.log("got", json);
        var found = this.actions.find(function (action) { return action === json.name; });
        switch (found) {
            case "statuses":
                var statusesData = json;
                // console.log("statusesData",statusesData);
                this.player.statuses = statusesData.statuses.map(function (_a) {
                    // console.log(name, value);
                    var name = _a.name, value = _a.value;
                    return new status_1.default(name, value);
                });
        }
    };
    return DataHandler;
}());
exports.default = DataHandler;


/***/ }),

/***/ "./src/game-scene.ts":
/*!***************************!*\
  !*** ./src/game-scene.ts ***!
  \***************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
var player_1 = __webpack_require__(/*! ./player */ "./src/player.ts");
var chased_object_1 = __webpack_require__(/*! ./chased-object */ "./src/chased-object.ts");
var data_handler_1 = __webpack_require__(/*! ./data-handler/data-handler */ "./src/data-handler/data-handler.ts");
var bed_1 = __webpack_require__(/*! ./bed */ "./src/bed.ts");
var sceneConfig = {
    active: false,
    visible: false,
    key: "Game",
};
var GameScene = /** @class */ (function (_super) {
    __extends(GameScene, _super);
    function GameScene() {
        var _this = _super.call(this, sceneConfig) || this;
        _this.velocity = 500;
        _this.destinationToMouse = { x: 0, y: 0 };
        _this.destinationToHeart = { x: 0, y: 0 };
        return _this;
    }
    GameScene.prototype.preload = function () {
        this.load.image("heart", "assets/heart/heart_full.png");
        this.load.atlas("player", "assets/player/player.png", "assets/player/player.json");
        this.load.image("bed", "assets/carpet.png");
    };
    GameScene.prototype.create = function (ws) {
        var _this = this;
        this.player = new player_1.default(this, 400, 400, "player");
        this.heart = new chased_object_1.default(this, this.player, "heart");
        this.bed = new bed_1.default(this, "bed");
        this.ws = ws;
        var dataHandler = new data_handler_1.default(this.player);
        this.ws.onmessage = function (event) {
            dataHandler.getMessage(event.data);
        };
        this.dataHandler = new data_handler_1.default(this.player);
        function onClick(pointer, scene) {
            scene.destinationToMouse.x = pointer.x;
            scene.destinationToMouse.y = pointer.y;
            if (scene.destinationToMouse.x - scene.player.sprite.body.x < 0) {
                scene.player.sprite.play("move").setFlipX(false);
            }
            else {
                scene.player.sprite.play("move").setFlipX(true);
            }
            scene.physics.moveTo(scene.player.sprite, pointer.x, pointer.y, scene.velocity);
            // console.log("initial: ", scene.destination);
        }
        this.input.on("pointerdown", function (pointer) {
            return onClick(pointer, _this);
        });
        this.player.createAnimations();
        this.physics.add.overlap(this.player.sprite, this.heart.sprite, function () { return _this.heart.move(); }, null, this);
        this.physics.add.overlap(this.player.sprite, this.bed.sprite, function () { return _this.bed.sleep(); }, null, this);
    };
    GameScene.prototype.changeMoveAnimation = function (player, destinationX) {
        if (destinationX - this.player.sprite.body.x < 0) {
            this.player.sprite.play("move").setFlipX(false);
        }
        else {
            this.player.sprite.play("move").setFlipX(true);
        }
    };
    GameScene.prototype.makeAnim = function (key, frameName, numberOfFrames) {
        var myArray = [];
        for (var i = 1; i <= numberOfFrames; i++) {
            var fn = frameName + i + ".png";
            myArray.push({
                key: key,
                frame: fn,
            });
        }
        return myArray;
    };
    GameScene.prototype.update = function () {
        var distMouse = Phaser.Math.Distance.Between(this.player.sprite.x, this.player.sprite.y, this.destinationToMouse.x, this.destinationToMouse.y);
        if (distMouse <= 10) {
            this.player.sprite.body.velocity.setTo(0, 0);
            this.player.sprite.play("idle");
            this.destinationToMouse.x = 0;
            this.destinationToMouse.y = 0;
        }
        // const distBed = Phaser.Math.Distance.Between(
        //   this.player.sprite.x,
        //   this.player.sprite.y,
        //   this.bed.sprite.x,
        //   this.bed.sprite.y
        // );
        // if (distBed <= this.bed.sprite.height) {
        //   this.player.sprite.body.velocity.setTo(0, 0);
        //   this.player.sprite.play("idle");
        //   this.bed.used = true;
        // }
        // this.bed.used = false;
    };
    return GameScene;
}(Phaser.Scene));
exports.GameScene = GameScene;


/***/ }),

/***/ "./src/main.ts":
/*!*********************!*\
  !*** ./src/main.ts ***!
  \*********************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
__webpack_require__(/*! phaser */ "./node_modules/phaser/src/phaser.js");
var game_scene_1 = __webpack_require__(/*! ./game-scene */ "./src/game-scene.ts");
var config = {
    type: Phaser.AUTO,
    scale: {
        width: 800,
        height: 600,
    },
    physics: {
        default: "arcade",
        arcade: {
            debug: true,
        },
    },
    render: {
        pixelArt: true,
    },
    parent: "game",
    backgroundColor: "#765478",
    scene: game_scene_1.GameScene,
};
var ws = new WebSocket("ws://localhost:32100");
ws.onopen = function () {
    ws.send("getStats");
    var game = new Phaser.Game(config);
    game.scene.start("Game", ws);
};
// game.scene.start("Game");


/***/ }),

/***/ "./src/player.ts":
/*!***********************!*\
  !*** ./src/player.ts ***!
  \***********************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var bar_1 = __webpack_require__(/*! ./bar */ "./src/bar.ts");
var Player = /** @class */ (function () {
    function Player(scene, x, y, key) {
        this.scene = scene;
        this.sprite = scene.physics.add.sprite(x, y, "player");
        this.sprite.setScale(4, 4);
        this.sprite.setDepth(0.5);
    }
    Player.prototype.createAnimations = function () {
        this.scene.anims.create({
            key: "idle",
            frames: this.makeAnimation("player", "player_idle_00", 4),
            frameRate: 8,
            repeat: -1,
        });
        this.scene.anims.create({
            key: "move",
            frames: this.makeAnimation("player", "player_walk_left_00", 6),
            frameRate: 8,
            repeat: -1,
        });
    };
    Player.prototype.makeAnimation = function (key, frameName, numberOfFrames) {
        var myArray = [];
        for (var i = 1; i <= numberOfFrames; i++) {
            var fn = frameName + i + ".png";
            myArray.push({
                key: key,
                frame: fn,
            });
        }
        return myArray;
    };
    Object.defineProperty(Player.prototype, "statuses", {
        set: function (statuses) {
            var _this = this;
            if (!this._statuses) {
                var y_1 = 10;
                this._statuses = statuses.map(function (status) {
                    var bar = new bar_1.Bar({ scene: _this.scene, x: 10, y: y_1, status: status });
                    y_1 += 20;
                    return bar;
                });
            }
            else {
                statuses.forEach(function (status, index) {
                    _this._statuses[index].status = status;
                });
            }
        },
        enumerable: true,
        configurable: true
    });
    return Player;
}());
exports.default = Player;


/***/ }),

/***/ "./src/status.ts":
/*!***********************!*\
  !*** ./src/status.ts ***!
  \***********************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var Status = /** @class */ (function () {
    function Status(name, current_value) {
        this._max_value = 100;
        this._min_value = 0;
        this._name = name;
        this._current_value = current_value;
    }
    Object.defineProperty(Status.prototype, "name", {
        get: function () {
            return this._name;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(Status.prototype, "current_value", {
        get: function () {
            return this._current_value;
        },
        set: function (value) {
            this._current_value = value;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(Status.prototype, "max_value", {
        get: function () {
            return this._max_value;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(Status.prototype, "min_value", {
        get: function () {
            return this._min_value;
        },
        enumerable: true,
        configurable: true
    });
    return Status;
}());
exports.default = Status;


/***/ }),

/***/ 0:
/*!*****************************************************************************!*\
  !*** multi (webpack)-dev-server/client?http://localhost:8080 ./src/main.ts ***!
  \*****************************************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

__webpack_require__(/*! /home/kristina/MyProjects/catch-object/node_modules/webpack-dev-server/client/index.js?http://localhost:8080 */"./node_modules/webpack-dev-server/client/index.js?http://localhost:8080");
module.exports = __webpack_require__(/*! ./src/main.ts */"./src/main.ts");


/***/ })

/******/ });
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly8vd2VicGFjay9ib290c3RyYXAiLCJ3ZWJwYWNrOi8vLyh3ZWJwYWNrKS9ob3Qgc3luYyBub25yZWN1cnNpdmUgXlxcLlxcL2xvZyQiLCJ3ZWJwYWNrOi8vLy4vc3JjL2Jhci50cyIsIndlYnBhY2s6Ly8vLi9zcmMvYmVkLnRzIiwid2VicGFjazovLy8uL3NyYy9jaGFzZWQtb2JqZWN0LnRzIiwid2VicGFjazovLy8uL3NyYy9kYXRhLWhhbmRsZXIvZGF0YS1oYW5kbGVyLnRzIiwid2VicGFjazovLy8uL3NyYy9nYW1lLXNjZW5lLnRzIiwid2VicGFjazovLy8uL3NyYy9tYWluLnRzIiwid2VicGFjazovLy8uL3NyYy9wbGF5ZXIudHMiLCJ3ZWJwYWNrOi8vLy4vc3JjL3N0YXR1cy50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiO1FBQUE7UUFDQTtRQUNBO1FBQ0E7UUFDQTs7UUFFQTtRQUNBO1FBQ0E7UUFDQSxRQUFRLG9CQUFvQjtRQUM1QjtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0E7O1FBRUE7UUFDQTtRQUNBOztRQUVBO1FBQ0E7O1FBRUE7UUFDQTtRQUNBO1FBQ0E7UUFDQTtRQUNBLGlCQUFpQiw0QkFBNEI7UUFDN0M7UUFDQTtRQUNBLGtCQUFrQiwyQkFBMkI7UUFDN0M7UUFDQTtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0E7UUFDQTs7UUFFQTtRQUNBOztRQUVBO1FBQ0E7O1FBRUE7UUFDQTtRQUNBO1FBQ0E7UUFDQTtRQUNBOztRQUVBOztRQUVBO1FBQ0E7O1FBRUE7UUFDQTtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0E7UUFDQTtRQUNBO1FBQ0E7O1FBRUE7UUFDQTs7UUFFQTtRQUNBOztRQUVBO1FBQ0E7UUFDQTs7O1FBR0E7UUFDQTs7UUFFQTtRQUNBOztRQUVBO1FBQ0E7UUFDQTtRQUNBLDBDQUEwQyxnQ0FBZ0M7UUFDMUU7UUFDQTs7UUFFQTtRQUNBO1FBQ0E7UUFD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LENBQUMsVUFBVSxDQUFDO1FBQ3pCLENBQUM7OztPQUFBO0lBRUQsc0JBQVcsNkJBQVM7YUFBcEI7WUFDRSxPQUFPLElBQUksQ0FBQyxVQUFVLENBQUM7UUFDekIsQ0FBQzs7O09BQUE7SUFDSCxhQUFDO0FBQUQsQ0FBQyIsImZpbGUiOiJhcHAuYnVuZGxlLmpzIiwic291cmNlc0NvbnRlbnQiOlsiIFx0Ly8gaW5zdGFsbCBhIEpTT05QIGNhbGxiYWNrIGZvciBjaHVuayBsb2FkaW5nXG4gXHRmdW5jdGlvbiB3ZWJwYWNrSnNvbnBDYWxsYmFjayhkYXRhKSB7XG4gXHRcdHZhciBjaHVua0lkcyA9IGRhdGFbMF07XG4gXHRcdHZhciBtb3JlTW9kdWxlcyA9IGRhdGFbMV07XG4gXHRcdHZhciBleGVjdXRlTW9kdWxlcyA9IGRhdGFbMl07XG5cbiBcdFx0Ly8gYWRkIFwibW9yZU1vZHVsZXNcIiB0byB0aGUgbW9kdWxlcyBvYmplY3QsXG4gXHRcdC8vIHRoZW4gZmxhZyBhbGwgXCJjaHVua0lkc1wiIGFzIGxvYWRlZCBhbmQgZmlyZSBjYWxsYmFja1xuIFx0XHR2YXIgbW9kdWxlSWQsIGNodW5rSWQsIGkgPSAwLCByZXNvbHZlcyA9IFtdO1xuIFx0XHRmb3IoO2kgPCBjaHVua0lkcy5sZW5ndGg7IGkrKykge1xuIFx0XHRcdGNodW5rSWQgPSBjaHVua0lkc1tpXTtcbiBcdFx0XHRpZihPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGwoaW5zdGFsbGVkQ2h1bmtzLCBjaHVua0lkKSAmJiBpbnN0YWxsZWRDaHVua3NbY2h1bmtJZF0pIHtcbiBcdFx0XHRcdHJlc29sdmVzLnB1c2goaW5zdGFsbGVkQ2h1bmtzW2NodW5rSWRdWzBdKTtcbiBcdFx0XHR9XG4gXHRcdFx0aW5zdGFsbGVkQ2h1bmtzW2NodW5rSWRdID0gMDtcbiBcdFx0fVxuIFx0XHRmb3IobW9kdWxlSWQgaW4gbW9yZU1vZHVsZXMpIHtcbiBcdFx0XHRpZihPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGwobW9yZU1vZHVsZXMsIG1vZHVsZUlkKSkge1xuIFx0XHRcdFx0bW9kdWxlc1ttb2R1bGVJZF0gPSBtb3JlTW9kdWxlc1ttb2R1bGVJZF07XG4gXHRcdFx0fVxuIFx0XHR9XG4gXHRcdGlmKHBhcmVudEpzb25wRnVuY3Rpb24pIHBhcmVudEpzb25wRnVuY3Rpb24oZGF0YSk7XG5cbiBcdFx0d2hpbGUocmVzb2x2ZXMubGVuZ3RoKSB7XG4gXHRcdFx0cmVzb2x2ZXMuc2hpZnQoKSgpO1xuIFx0XHR9XG5cbiBcdFx0Ly8gYWRkIGVudHJ5IG1vZHVsZXMgZnJvbSBsb2FkZWQgY2h1bmsgdG8gZGVmZXJyZWQgbGlzdFxuIFx0XHRkZWZlcnJlZE1vZHVsZXMucHVzaC5hcHBseShkZWZlcnJlZE1vZHVsZXMsIGV4ZWN1dGVNb2R1bGVzIHx8IFtdKTtcblxuIFx0XHQvLyBydW4gZGVmZXJyZWQgbW9kdWxlcyB3aGVuIGFsbCBjaHVua3MgcmVhZHlcbiBcdFx0cmV0dXJuIGNoZWNrRGVmZXJyZWRNb2R1bGVzKCk7XG4gXHR9O1xuIFx0ZnVuY3Rpb24gY2hlY2tEZWZlcnJlZE1vZHVsZXMoKSB7XG4gXHRcdHZhciByZXN1bHQ7XG4gXHRcdGZvcih2YXIgaSA9IDA7IGkgPCBkZWZlcnJlZE1vZHVsZXMubGVuZ3RoOyBpKyspIHtcbiBcdFx0XHR2YXIgZGVmZXJyZWRNb2R1bGUgPSBkZWZlcnJlZE1vZHVsZXNbaV07XG4gXHRcdFx0dmFyIGZ1bGZpbGxlZCA9IHRydWU7XG4gXHRcdFx0Zm9yKHZhciBqID0gMTsgaiA8IGRlZmVycmVkTW9kdWxlLmxlbmd0aDsgaisrKSB7XG4gXHRcdFx0XHR2YXIgZGVwSWQgPSBkZWZlcnJlZE1vZHVsZVtqXTtcbiBcdFx0XHRcdGlmKGluc3RhbGxlZENodW5rc1tkZXBJZF0gIT09IDApIGZ1bGZpbGxlZCA9IGZhbHNlO1xuIFx0XHRcdH1cbiBcdFx0XHRpZihmdWxmaWxsZWQpIHtcbiBcdFx0XHRcdGRlZmVycmVkTW9kdWxlcy5zcGxpY2UoaS0tLCAxKTtcbiBcdFx0XHRcdHJlc3VsdCA9IF9fd2VicGFja19yZXF1aXJlX18oX193ZWJwYWNrX3JlcXVpcmVfXy5zID0gZGVmZXJyZWRNb2R1bGVbMF0pO1xuIFx0XHRcdH1cbiBcdFx0fVxuXG4gXHRcdHJldHVybiByZXN1bHQ7XG4gXHR9XG5cbiBcdC8vIFRoZSBtb2R1bGUgY2FjaGVcbiBcdHZhciBpbnN0YWxsZWRNb2R1bGVzID0ge307XG5cbiBcdC8vIG9iamVjdCB0byBzdG9yZSBsb2FkZWQgYW5kIGxvYWRpbmcgY2h1bmtzXG4gXHQvLyB1bmRlZmluZWQgPSBjaHVuayBub3QgbG9hZGVkLCBudWxsID0gY2h1bmsgcHJlbG9hZGVkL3ByZWZldGNoZWRcbiBcdC8vIFByb21pc2UgPSBjaHVuayBsb2FkaW5nLCAwID0gY2h1bmsgbG9hZGVkXG4gXHR2YXIgaW5zdGFsbGVkQ2h1bmtzID0ge1xuIFx0XHRcImFwcFwiOiAwXG4gXHR9O1xuXG4gXHR2YXIgZGVmZXJyZWRNb2R1bGVzID0gW107XG5cbiBcdC8vIFRoZSByZXF1aXJlIGZ1bmN0aW9uXG4gXHRmdW5jdGlvbiBfX3dlYnBhY2tfcmVxdWlyZV9fKG1vZHVsZUlkKSB7XG5cbiBcdFx0Ly8gQ2hlY2sgaWYgbW9kdWxlIGlzIGluIGNhY2hlXG4gXHRcdGlmKGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdKSB7XG4gXHRcdFx0cmV0dXJuIGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdLmV4cG9ydHM7XG4gXHRcdH1cbiBcdFx0Ly8gQ3JlYXRlIGEgbmV3IG1vZHVsZSAoYW5kIHB1dCBpdCBpbnRvIHRoZSBjYWNoZSlcbiBcdFx0dmFyIG1vZHVsZSA9IGluc3RhbGxlZE1vZHVsZXNbbW9kdWxlSWRdID0ge1xuIFx0XHRcdGk6IG1vZHVsZUlkLFxuIFx0XHRcdGw6IGZhbHNlLFxuIFx0XHRcdGV4cG9ydHM6IHt9XG4gXHRcdH07XG5cbiBcdFx0Ly8gRXhlY3V0ZSB0aGUgbW9kdWxlIGZ1bmN0aW9uXG4gXHRcdG1vZHVsZXNbbW9kdWxlSWRdLmNhbGwobW9kdWxlLmV4cG9ydHMsIG1vZHVsZSwgbW9kdWxlLmV4cG9ydHMsIF9fd2VicGFja19yZXF1aXJlX18pO1xuXG4gXHRcdC8vIEZsYWcgdGhlIG1vZHVsZSBhcyBsb2FkZWRcbiBcdFx0bW9kdWxlLmwgPSB0cnVlO1xuXG4gXHRcdC8vIFJldHVybiB0aGUgZXhwb3J0cyBvZiB0aGUgbW9kdWxlXG4gXHRcdHJldHVybiBtb2R1bGUuZXhwb3J0cztcbiBcdH1cblxuXG4gXHQvLyBleHBvc2UgdGhlIG1vZHVsZXMgb2JqZWN0IChfX3dlYnBhY2tfbW9kdWxlc19fKVxuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5tID0gbW9kdWxlcztcblxuIFx0Ly8gZXhwb3NlIHRoZSBtb2R1bGUgY2FjaGVcbiBcdF9fd2VicGFja19yZXF1aXJlX18uYyA9IGluc3RhbGxlZE1vZHVsZXM7XG5cbiBcdC8vIGRlZmluZSBnZXR0ZXIgZnVuY3Rpb24gZm9yIGhhcm1vbnkgZXhwb3J0c1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5kID0gZnVuY3Rpb24oZXhwb3J0cywgbmFtZSwgZ2V0dGVyKSB7XG4gXHRcdGlmKCFfX3dlYnBhY2tfcmVxdWlyZV9fLm8oZXhwb3J0cywgbmFtZSkpIHtcbiBcdFx0XHRPYmplY3QuZGVmaW5lUHJvcGVydHkoZXhwb3J0cywgbmFtZSwgeyBlbnVtZXJhYmxlOiB0cnVlLCBnZXQ6IGdldHRlciB9KTtcbiBcdFx0fVxuIFx0fTtcblxuIFx0Ly8gZGVmaW5lIF9fZXNNb2R1bGUgb24gZXhwb3J0c1xuIFx0X193ZWJwYWNrX3JlcXVpcmVfXy5yID0gZnVuY3Rpb24oZXhwb3J0cykge1xuIFx0XHRpZih0eXBlb2YgU3ltYm9sICE9PSAndW5kZWZpbmVkJyAmJiBTeW1ib2wudG9TdHJpbmdUYWcpIHtcbiBcdFx0XHRPYmplY3QuZGVmaW5lUHJvcGVydHkoZXhwb3J0cywgU3ltYm9sLnRvU3RyaW5nVGFnLCB7IHZhbHVlOiAnTW9kdWxlJyB9KTtcbiBcdFx0fVxuIFx0XHRPYmplY3QuZGVmaW5lUHJvcGVydHkoZXhwb3J0cywgJ19fZXNNb2R1bGUnLCB7IHZhbHVlOiB0cnVlIH0pO1xuIFx0fTtcblxuIFx0Ly8gY3JlYXRlIGEgZmFrZSBuYW1lc3BhY2Ugb2JqZWN0XG4gXHQvLyBtb2RlICYgMTogdmFsdWUgaXMgYSBtb2R1bGUgaWQsIHJlcXVpcmUgaXRcbiBcdC8vIG1vZGUgJiAyOiBtZXJnZSBhbGwgcHJvcGVydGllcyBvZiB2YWx1ZSBpbnRvIHRoZSBuc1xuIFx0Ly8gbW9kZSAmIDQ6IHJldHVybiB2YWx1ZSB3aGVuIGFscmVhZHkgbnMgb2JqZWN0XG4gXHQvLyBtb2RlICYgOHwxOiBiZWhhdmUgbGlrZSByZXF1aXJlXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLnQgPSBmdW5jdGlvbih2YWx1ZSwgbW9kZSkge1xuIFx0XHRpZihtb2RlICYgMSkgdmFsdWUgPSBfX3dlYnBhY2tfcmVxdWlyZV9fKHZhbHVlKTtcbiBcdFx0aWYobW9kZSAmIDgpIHJldHVybiB2YWx1ZTtcbiBcdFx0aWYoKG1vZGUgJiA0KSAmJiB0eXBlb2YgdmFsdWUgPT09ICdvYmplY3QnICYmIHZhbHVlICYmIHZhbHVlLl9fZXNNb2R1bGUpIHJldHVybiB2YWx1ZTtcbiBcdFx0dmFyIG5zID0gT2JqZWN0LmNyZWF0ZShudWxsKTtcbiBcdFx0X193ZWJwYWNrX3JlcXVpcmVfXy5yKG5zKTtcbiBcdFx0T2JqZWN0LmRlZmluZVByb3BlcnR5KG5zLCAnZGVmYXVsdCcsIHsgZW51bWVyYWJsZTogdHJ1ZSwgdmFsdWU6IHZhbHVlIH0pO1xuIFx0XHRpZihtb2RlICYgMiAmJiB0eXBlb2YgdmFsdWUgIT0gJ3N0cmluZycpIGZvcih2YXIga2V5IGluIHZhbHVlKSBfX3dlYnBhY2tfcmVxdWlyZV9fLmQobnMsIGtleSwgZnVuY3Rpb24oa2V5KSB7IHJldHVybiB2YWx1ZVtrZXldOyB9LmJpbmQobnVsbCwga2V5KSk7XG4gXHRcdHJldHVybiBucztcbiBcdH07XG5cbiBcdC8vIGdldERlZmF1bHRFeHBvcnQgZnVuY3Rpb24gZm9yIGNvbXBhdGliaWxpdHkgd2l0aCBub24taGFybW9ueSBtb2R1bGVzXG4gXHRfX3dlYnBhY2tfcmVxdWlyZV9fLm4gPSBmdW5jdGlvbihtb2R1bGUpIHtcbiBcdFx0dmFyIGdldHRlciA9IG1vZHVsZSAmJiBtb2R1bGUuX19lc01vZHVsZSA/XG4gXHRcdFx0ZnVuY3Rpb24gZ2V0RGVmYXVsdCgpIHsgcmV0dXJuIG1vZHVsZVsnZGVmYXVsdCddOyB9IDpcbiBcdFx0XHRmdW5jdGlvbiBnZXRNb2R1bGVFeHBvcnRzKCkgeyByZXR1cm4gbW9kdWxlOyB9O1xuIFx0XHRfX3dlYnBhY2tfcmVxdWlyZV9fLmQoZ2V0dGVyLCAnYScsIGdldHRlcik7XG4gXHRcdHJldHVybiBnZXR0ZXI7XG4gXHR9O1xuXG4gXHQvLyBPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGxcbiBcdF9fd2VicGFja19yZXF1aXJlX18ubyA9IGZ1bmN0aW9uKG9iamVjdCwgcHJvcGVydHkpIHsgcmV0dXJuIE9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHkuY2FsbChvYmplY3QsIHByb3BlcnR5KTsgfTtcblxuIFx0Ly8gX193ZWJwYWNrX3B1YmxpY19wYXRoX19cbiBcdF9fd2VicGFja19yZXF1aXJlX18ucCA9IFwiXCI7XG5cbiBcdHZhciBqc29ucEFycmF5ID0gd2luZG93W1wid2VicGFja0pzb25wXCJdID0gd2luZG93W1wid2VicGFja0pzb25wXCJdIHx8IFtdO1xuIFx0dmFyIG9sZEpzb25wRnVuY3Rpb24gPSBqc29ucEFycmF5LnB1c2guYmluZChqc29ucEFycmF5KTtcbiBcdGpzb25wQXJyYXkucHVzaCA9IHdlYnBhY2tKc29ucENhbGxiYWNrO1xuIFx0anNvbnBBcnJheSA9IGpzb25wQXJyYXkuc2xpY2UoKTtcbiBcdGZvcih2YXIgaSA9IDA7IGkgPCBqc29ucEFycmF5Lmxlbmd0aDsgaSsrKSB3ZWJwYWNrSnNvbnBDYWxsYmFjayhqc29ucEFycmF5W2ldKTtcbiBcdHZhciBwYXJlbnRKc29ucEZ1bmN0aW9uID0gb2xkSnNvbnBGdW5jdGlvbjtcblxuXG4gXHQvLyBhZGQgZW50cnkgbW9kdWxlIHRvIGRlZmVycmVkIGxpc3RcbiBcdGRlZmVycmVkTW9kdWxlcy5wdXNoKFswLFwidmVuZG9yc1wiXSk7XG4gXHQvLyBydW4gZGVmZXJyZWQgbW9kdWxlcyB3aGVuIHJlYWR5XG4gXHRyZXR1cm4gY2hlY2tEZWZlcnJlZE1vZHVsZXMoKTtcbiIsInZhciBtYXAgPSB7XG5cdFwiLi9sb2dcIjogXCIuL25vZGVfbW9kdWxlcy93ZWJwYWNrL2hvdC9sb2cuanNcIlxufTtcblxuXG5mdW5jdGlvbiB3ZWJwYWNrQ29udGV4dChyZXEpIHtcblx0dmFyIGlkID0gd2VicGFja0NvbnRleHRSZXNvbHZlKHJlcSk7XG5cdHJldHVybiBfX3dlYnBhY2tfcmVxdWlyZV9fKGlkKTtcbn1cbmZ1bmN0aW9uIHdlYnBhY2tDb250ZXh0UmVzb2x2ZShyZXEpIHtcblx0aWYoIV9fd2VicGFja19yZXF1aXJlX18ubyhtYXAsIHJlcSkpIHtcblx0XHR2YXIgZSA9IG5ldyBFcnJvcihcIkNhbm5vdCBmaW5kIG1vZHVsZSAnXCIgKyByZXEgKyBcIidcIik7XG5cdFx0ZS5jb2RlID0gJ01PRFVMRV9OT1RfRk9VTkQnO1xuXHRcdHRocm93IGU7XG5cdH1cblx0cmV0dXJuIG1hcFtyZXFdO1xufVxud2VicGFja0NvbnRleHQua2V5cyA9IGZ1bmN0aW9uIHdlYnBhY2tDb250ZXh0S2V5cygpIHtcblx0cmV0dXJuIE9iamVjdC5rZXlzKG1hcCk7XG59O1xud2VicGFja0NvbnRleHQucmVzb2x2ZSA9IHdlYnBhY2tDb250ZXh0UmVzb2x2ZTtcbm1vZHVsZS5leHBvcnRzID0gd2VicGFja0NvbnRleHQ7XG53ZWJwYWNrQ29udGV4dC5pZCA9IFwiLi9ub2RlX21vZHVsZXMvd2VicGFjay9ob3Qgc3luYyBeXFxcXC5cXFxcL2xvZyRcIjsiLCJpbXBvcnQgU3RhdHVzIGZyb20gXCIuL3N0YXR1c1wiO1xuXG5pbnRlcmZhY2UgQmFySW50ZXJmYWNlIHtcbiAgc2NlbmU6IFBoYXNlci5TY2VuZTtcbiAgeDogbnVtYmVyO1xuICB5OiBudW1iZXI7XG4gIHN0YXR1czogU3RhdHVzO1xufVxuXG5leHBvcnQgY2xhc3MgQmFyIHtcbiAgc2NlbmU6IFBoYXNlci5TY2VuZTtcbiAgYmFyX2Rpc3BsYXk6IFBoYXNlci5HYW1lT2JqZWN0cy5HcmFwaGljcztcbiAgcHJpdmF0ZSBfc3RhdHVzOiBTdGF0dXM7XG4gIGJhcl9zaXplID0ge1xuICAgIHdpZHRoOiAyMDAsXG4gICAgaGVpZ2h0OiAyNSxcbiAgfTtcbiAgYmFyX2ZyYW1lX3NpemUgPSB0aGlzLmJhcl9zaXplLndpZHRoICogMC4wMjtcblxuICBjb25zdHJ1Y3Rvcih7IHNjZW5lLCB4LCB5LCBzdGF0dXMgfTogQmFySW50ZXJmYWNlKSB7XG4gICAgdGhpcy5zY2VuZSA9IHNjZW5lO1xuICAgIHRoaXMuYmFyX2Rpc3BsYXkgPSBuZXcgUGhhc2VyLkdhbWVPYmplY3RzLkdyYXBoaWNzKHNjZW5lKTtcbiAgICB0aGlzLmJhcl9kaXNwbGF5LnNldFgoeCk7XG4gICAgdGhpcy5iYXJfZGlzcGxheS5zZXRZKHkpO1xuICAgIHRoaXMuYmFyX2Rpc3BsYXkuc2V0RGVwdGgoMC45OSk7XG4gICAgdGhpcy5fc3RhdHVzID0gc3RhdHVzO1xuICAgIHRoaXMuZHJhdygpO1xuXG4gICAgc2NlbmUuYWRkLmV4aXN0aW5nKHRoaXMuYmFyX2Rpc3BsYXkpO1xuICB9XG5cbiAgcHVibGljIGRyYXcoKSB7XG4gICAgdGhpcy5iYXJfZGlzcGxheS5jbGVhcigpO1xuICAgIHRoaXMuY3JlYXRlRW1wdHlTdGF0dXNCYXIoKTtcbiAgICB0aGlzLmRpc3BsYXlTdGF0dXNDaGFuZ2UoKTtcbiAgICB0aGlzLmRpc3BsYXlOYW1lKCk7XG4gIH1cbiAgcHJpdmF0ZSBkaXNwbGF5TmFtZSgpIHtcbiAgICBjb25zdCBuYW1lOiBzdHJpbmcgPSB0aGlzLl9zdGF0dXMubmFtZTtcblxuICAgIHRleHQ6IFBoYXNlci5HYW1lT2JqZWN0cy5UZXh0O1xuICAgIGNvbnN0IHsgeCwgeSB9ID0gdGhpcy5jYWxjdWxhdGVUZXh0UG9zaXRpb24oKTtcbiAgICBjb25zdCB0ZXh0ID0gdGhpcy5zY2VuZS5hZGQudGV4dCh4LCB5LCBuYW1lLCB7IGNvbG9yOiBcIjAwMFwiIH0pO1xuICAgIHRleHQuZGVwdGggPSAxO1xuICB9XG4gIHByaXZhdGUgY2FsY3VsYXRlVGV4dFBvc2l0aW9uKCkge1xuICAgIHJldHVybiB7XG4gICAgICB4OiB0aGlzLmJhcl9kaXNwbGF5LnggKiAyICsgdGhpcy5iYXJfZnJhbWVfc2l6ZSArIDUsXG4gICAgICB5OiB0aGlzLmJhcl9kaXNwbGF5LnkgKiAyICsgdGhpcy5iYXJfZnJhbWVfc2l6ZSxcbiAgICB9O1xuICB9XG5cbiAgcHJpdmF0ZSBjcmVhdGVFbXB0eVN0YXR1c0JhcigpIHtcbiAgICAvLyAgQ3JlYXRpbmcgYmxhY2sgZnJlYW0gYW5kIHdoaXRlIGJhY2tncm91bmRcbiAgICB0aGlzLmJhcl9kaXNwbGF5LmZpbGxTdHlsZSgweDAwMDAwMCk7XG4gICAgdGhpcy5iYXJfZGlzcGxheS5maWxsUmVjdChcbiAgICAgIHRoaXMuYmFyX2Rpc3BsYXkueCxcbiAgICAgIHRoaXMuYmFyX2Rpc3BsYXkueSxcbiAgICAgIHRoaXMuYmFyX3NpemUud2lkdGgsXG4gICAgICB0aGlzLmJhcl9zaXplLmhlaWdodFxuICAgICk7XG5cbiAgICB0aGlzLmJhcl9kaXNwbGF5LmZpbGxTdHlsZSgweGZmZmZmZik7XG4gICAgdGhpcy5iYXJfZGlzcGxheS5maWxsUmVjdChcbiAgICAgIHRoaXMuYmFyX2Rpc3BsYXkueCArIHRoaXMuYmFyX2ZyYW1lX3NpemUsXG4gICAgICB0aGlzLmJhcl9kaXNwbGF5LnkgKyB0aGlzLmJhcl9mcmFtZV9zaXplLFxuICAgICAgdGhpcy5iYXJfc2l6ZS53aWR0aCAtIHRoaXMuYmFyX2ZyYW1lX3NpemUgKiAyLFxuICAgICAgdGhpcy5iYXJfc2l6ZS5oZWlnaHQgLSB0aGlzLmJhcl9mcmFtZV9zaXplICogMlxuICAgICk7XG4gIH1cblxuICBwcml2YXRlIGRpc3BsYXlTdGF0dXNDaGFuZ2UoKSB7XG4gICAgaWYgKHRoaXMuX3N0YXR1cy5jdXJyZW50X3ZhbHVlICE9PSAwKSB7XG4gICAgICB0aGlzLmNoYW5nZVN0YXR1c0NvbG9yKCk7XG4gICAgICBsZXQgZGlzdGFuY2UgPSBNYXRoLmZsb29yKFxuICAgICAgICAodGhpcy5fc3RhdHVzLmN1cnJlbnRfdmFsdWUgLyB0aGlzLl9zdGF0dXMubWF4X3ZhbHVlKSAqXG4gICAgICAgICAgdGhpcy5iYXJfc2l6ZS53aWR0aCAtXG4gICAgICAgICAgdGhpcy5iYXJfZnJhbWVfc2l6ZSAqIDJcbiAgICAgICk7XG4gICAgICB0aGlzLmJhcl9kaXNwbGF5LmZpbGxSZWN0KFxuICAgICAgICB0aGlzLmJhcl9kaXNwbGF5LnggKyB0aGlzLmJhcl9mcmFtZV9zaXplLFxuICAgICAgICB0aGlzLmJhcl9kaXNwbGF5LnkgKyB0aGlzLmJhcl9mcmFtZV9zaXplLFxuICAgICAgICBkaXN0YW5jZSxcbiAgICAgICAgdGhpcy5iYXJfc2l6ZS5oZWlnaHQgLSB0aGlzLmJhcl9mcmFtZV9zaXplICogMlxuICAgICAgKTtcbiAgICB9XG4gIH1cblxuICBwcml2YXRlIGNoYW5nZVN0YXR1c0NvbG9yKCkge1xuICAgIGlmICh0aGlzLl9zdGF0dXMuY3VycmVudF92YWx1ZSA8PSAzMCkge1xuICAgICAgdGhpcy5iYXJfZGlzcGxheS5maWxsU3R5bGUoMHhmZjAwMDApO1xuICAgIH0gZWxzZSBpZiAodGhpcy5fc3RhdHVzLmN1cnJlbnRfdmFsdWUgPD0gNjApIHtcbiAgICAgIHRoaXMuYmFyX2Rpc3BsYXkuZmlsbFN0eWxlKDB4ZmY5OTMzKTtcbiAgICB9IGVsc2UgaWYgKHRoaXMuX3N0YXR1cy5jdXJyZW50X3ZhbHVlIDw9IDkwKSB7XG4gICAgICB0aGlzLmJhcl9kaXNwbGF5LmZpbGxTdHlsZSgweGZmZjAwMCk7XG4gICAgfSBlbHNlIHtcbiAgICAgIHRoaXMuYmFyX2Rpc3BsYXkuZmlsbFN0eWxlKDB4MDBmZjAwKTtcbiAgICB9XG4gIH1cblxuICBwdWJsaWMgc2V0IHN0YXR1cyhzdGF0dXM6IFN0YXR1cykge1xuICAgIHRoaXMuX3N0YXR1cyA9IHN0YXR1cztcbiAgICB0aGlzLmRyYXcoKTtcbiAgfVxufVxuIiwiaW1wb3J0IHsgUGh5c2ljcyB9IGZyb20gXCJwaGFzZXJcIjtcblxuZXhwb3J0IGRlZmF1bHQgY2xhc3MgQmVkIHtcbiAgc3ByaXRlOiBQaHlzaWNzLkFyY2FkZS5TcHJpdGU7XG4gIHNjZW5lOiBQaGFzZXIuU2NlbmU7XG4gIHNoYWRlOiBQaGFzZXIuR2FtZU9iamVjdHMuR3JhcGhpY3M7XG4gIHVzZWQ6IGJvb2xlYW47XG5cbiAgY29uc3RydWN0b3Ioc2NlbmU6IFBoYXNlci5TY2VuZSwgbmFtZTogc3RyaW5nKSB7XG4gICAgdGhpcy5zY2VuZSA9IHNjZW5lO1xuICAgIHRoaXMuc3ByaXRlID0gdGhpcy5zY2VuZS5waHlzaWNzLmFkZC5zcHJpdGUoXG4gICAgICB0aGlzLnNjZW5lLnNjYWxlLndpZHRoLFxuICAgICAgdGhpcy5zY2VuZS5zY2FsZS5oZWlnaHQsXG4gICAgICBuYW1lXG4gICAgKTtcbiAgICB0aGlzLnNwcml0ZS5zZXRTY2FsZSgyLCAyKTtcbiAgICB0aGlzLnNwcml0ZS5zZXRPcmlnaW4oMSwgMSk7IC8vcmlnaHRib3R0b20gY29ybmVyXG4gICAgdGhpcy5zcHJpdGUuc2V0RGVwdGgoMCk7XG4gICAgdGhpcy51c2VkID0gZmFsc2U7XG4gICAgdGhpcy5jcmVhdGVTaGFkZSgpO1xuICB9XG5cbiAgcHVibGljIHNsZWVwKCkge1xuICAgIGNvbnNvbGUubG9nKFwic2xlZXB1IHNsZWVwdVwiKTtcbiAgICAvLyB0aGlzLnNjZW5lLmNhbWVyYXMubWFpbi5iYWNrZ3JvdW5kQ29sb3IgPSBQaGFzZXIuRGlzcGxheS5Db2xvci5IZXhTdHJpbmdUb0NvbG9yKFwiIzM0OThkYlwiKTtcblxuICAgIHRoaXMuc2hhZGUuc2V0QWxwaGEoMC45OCk7XG4gIH1cbiAgcHJpdmF0ZSBjcmVhdGVTaGFkZSgpIHtcbiAgICBjb25zb2xlLmxvZyhcImNyZWF0ZSBzaGFkZVwiKTtcblxuICAgIHRoaXMuc2hhZGUgPSBuZXcgUGhhc2VyLkdhbWVPYmplY3RzLkdyYXBoaWNzKHRoaXMuc2NlbmUpO1xuICAgIHRoaXMuc2hhZGUuZmlsbFN0eWxlKDB4MDAwMDAwKTtcbiAgICB0aGlzLnNoYWRlLmZpbGxSZWN0KDAsIDAsIHRoaXMuc2NlbmUuc2NhbGUud2lkdGgsIHRoaXMuc2NlbmUuc2NhbGUuaGVpZ2h0KTtcbiAgICB0aGlzLnNoYWRlLnNldERlcHRoKDAuOTgpO1xuICAgIHRoaXMuc2hhZGUuc2V0QWxwaGEoMCk7XG4gIH1cbn1cbiIsImltcG9ydCB7IFBoeXNpY3MgfSBmcm9tIFwicGhhc2VyXCI7XG5pbXBvcnQgUGxheWVyIGZyb20gXCIuL3BsYXllclwiO1xuXG5cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIENoYXNlZE9iamVjdCB7XG5cbiAgICBzcHJpdGU6IFBoeXNpY3MuQXJjYWRlLlNwcml0ZTtcbiAgICBzY2VuZTogUGhhc2VyLlNjZW5lO1xuICAgIHBsYXllcjogUGxheWVyO1xuICAgIGV4aXN0ID0gMDtcblxuXG4gICAgY29uc3RydWN0b3Ioc2NlbmU6IFBoYXNlci5TY2VuZSwgcGxheWVyOiBQbGF5ZXIsIGtleTogc3RyaW5nKSB7XG4gICAgICAgIHRoaXMuc2NlbmUgPSBzY2VuZTtcbiAgICAgICAgdGhpcy5wbGF5ZXIgPSBwbGF5ZXI7XG4gICAgICAgIGNvbnN0IHggPSBNYXRoLnJhbmRvbSgpICogdGhpcy5zY2VuZS5jYW1lcmFzLm1haW4uY2VudGVyWCAqIDI7XG4gICAgICAgIGNvbnN0IHkgPSBNYXRoLnJhbmRvbSgpICogdGhpcy5zY2VuZS5jYW1lcmFzLm1haW4uY2VudGVyWSAqIDI7XG4gICAgICAgIHRoaXMuZXhpc3QgKz0gMTtcbiAgICAgICAgdGhpcy5zcHJpdGUgPSBzY2VuZS5waHlzaWNzLmFkZC5zcHJpdGUoeCwgeSwgJ2hlYXJ0Jyk7XG5cbiAgICB9XG5cbiAgICBtb3ZlKCkge1xuICAgICAgICB3aGlsZSAoUGhhc2VyLk1hdGguRGlzdGFuY2UuQmV0d2Vlbih0aGlzLnNwcml0ZS54LCB0aGlzLnNwcml0ZS55LCB0aGlzLnBsYXllci5zcHJpdGUueCwgdGhpcy5wbGF5ZXIuc3ByaXRlLnkpIDwgMTAwKSB7XG4gICAgICAgICAgICBjb25zdCB4ID0gTWF0aC5yYW5kb20oKSAqIHRoaXMuc2NlbmUuY2FtZXJhcy5tYWluLmNlbnRlclggKiAyO1xuICAgICAgICAgICAgY29uc3QgeSA9IE1hdGgucmFuZG9tKCkgKiB0aGlzLnNjZW5lLmNhbWVyYXMubWFpbi5jZW50ZXJZICogMjtcbiAgICAgICAgICAgIHRoaXMuc3ByaXRlLnggPSB4O1xuICAgICAgICAgICAgdGhpcy5zcHJpdGUueSA9IHk7XG4gICAgICAgIH1cbiAgICB9XG59IiwiaW1wb3J0IFBsYXllciBmcm9tIFwiLi4vcGxheWVyXCI7XG5pbXBvcnQgU3RhdHVzIGZyb20gXCIuLi9zdGF0dXNcIjtcbmltcG9ydCB7IFN0YXR1c2VzRm9ybWF0IH0gZnJvbSBcIi4vZGF0YS1oYW5kbGVyLnR5cGVzXCI7XG5cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIERhdGFIYW5kbGVyIHtcbiAgcGxheWVyOiBQbGF5ZXI7XG4gIGFjdGlvbnMgPSBbXCJzdGF0dXNlc1wiXTtcblxuICBjb25zdHJ1Y3RvcihwbGF5ZXI6IFBsYXllcikge1xuICAgIHRoaXMucGxheWVyID0gcGxheWVyO1xuICB9XG5cbiAgcHVibGljIGdldE1lc3NhZ2UobWVzc2FnZTogc3RyaW5nKSB7XG4gICAgY29uc3QganNvbiA9IEpTT04ucGFyc2UobWVzc2FnZSk7XG4gICAgLy8gY29uc29sZS5sb2coXCJnb3RcIiwganNvbik7XG4gICAgY29uc3QgZm91bmQgPSB0aGlzLmFjdGlvbnMuZmluZCgoYWN0aW9uKSA9PiBhY3Rpb24gPT09IGpzb24ubmFtZSk7XG4gICAgc3dpdGNoKGZvdW5kKXtcbiAgICAgIGNhc2UgXCJzdGF0dXNlc1wiOlxuICAgICAgICBjb25zdCBzdGF0dXNlc0RhdGEgOiBTdGF0dXNlc0Zvcm1hdCA9IGpzb247XG4gICAgICAgIC8vIGNvbnNvbGUubG9nKFwic3RhdHVzZXNEYXRhXCIsc3RhdHVzZXNEYXRhKTtcbiAgICAgICAgXG4gICAgICAgIHRoaXMucGxheWVyLnN0YXR1c2VzID0gc3RhdHVzZXNEYXRhLnN0YXR1c2VzLm1hcCgoe25hbWUsdmFsdWV9KSA9PiB7XG4gICAgICAgICAgLy8gY29uc29sZS5sb2cobmFtZSwgdmFsdWUpO1xuICAgICAgICAgIFxuICAgICAgICAgIHJldHVybiBuZXcgU3RhdHVzKG5hbWUsIHZhbHVlKTtcbiAgICAgICAgfSk7XG4gICAgfVxuICB9XG59XG4iLCJpbXBvcnQgeyBCYXIgfSBmcm9tIFwiLi9iYXJcIjtcbmltcG9ydCB7IFBoeXNpY3MsIFNjZW5lIH0gZnJvbSBcInBoYXNlclwiO1xuaW1wb3J0IFBsYXllciBmcm9tIFwiLi9wbGF5ZXJcIjtcbmltcG9ydCBDaGFzZWRPYmplY3QgZnJvbSBcIi4vY2hhc2VkLW9iamVjdFwiO1xuaW1wb3J0IERhdGFIYW5kbGVyIGZyb20gXCIuL2RhdGEtaGFuZGxlci9kYXRhLWhhbmRsZXJcIjtcbmltcG9ydCBCZWQgZnJvbSBcIi4vYmVkXCI7XG5cbmNvbnN0IHNjZW5lQ29uZmlnOiBQaGFzZXIuVHlwZXMuU2NlbmVzLlNldHRpbmdzQ29uZmlnID0ge1xuICBhY3RpdmU6IGZhbHNlLFxuICB2aXNpYmxlOiBmYWxzZSxcbiAga2V5OiBcIkdhbWVcIixcbn07XG5cbmV4cG9ydCBjbGFzcyBHYW1lU2NlbmUgZXh0ZW5kcyBQaGFzZXIuU2NlbmUge1xuICBwbGF5ZXI6IFBsYXllcjtcbiAgaGVhcnQ6IENoYXNlZE9iamVjdDtcbiAgYmVkOiBCZWQ7XG4gIHZlbG9jaXR5ID0gNTAwO1xuICBkYXRhSGFuZGxlcjogRGF0YUhhbmRsZXI7XG4gIHdzOiBXZWJTb2NrZXQ7XG5cbiAgZGVzdGluYXRpb25Ub01vdXNlID0geyB4OiAwLCB5OiAwIH07XG4gIGRlc3RpbmF0aW9uVG9IZWFydCA9IHsgeDogMCwgeTogMCB9O1xuXG4gIGNvbnN0cnVjdG9yKCkge1xuICAgIHN1cGVyKHNjZW5lQ29uZmlnKTtcbiAgfVxuXG4gIHB1YmxpYyBwcmVsb2FkKCkge1xuICAgIHRoaXMubG9hZC5pbWFnZShcImhlYXJ0XCIsIFwiYXNzZXRzL2hlYXJ0L2hlYXJ0X2Z1bGwucG5nXCIpO1xuICAgIHRoaXMubG9hZC5hdGxhcyhcbiAgICAgIFwicGxheWVyXCIsXG4gICAgICBcImFzc2V0cy9wbGF5ZXIvcGxheWVyLnBuZ1wiLFxuICAgICAgXCJhc3NldHMvcGxheWVyL3BsYXllci5qc29uXCJcbiAgICApO1xuICAgIHRoaXMubG9hZC5pbWFnZShcImJlZFwiLCBcImFzc2V0cy9jYXJwZXQucG5nXCIpO1xuICB9XG5cbiAgcHVibGljIGNyZWF0ZSh3czogV2ViU29ja2V0KSB7XG4gICAgdGhpcy5wbGF5ZXIgPSBuZXcgUGxheWVyKHRoaXMsIDQwMCwgNDAwLCBcInBsYXllclwiKTtcbiAgICB0aGlzLmhlYXJ0ID0gbmV3IENoYXNlZE9iamVjdCh0aGlzLCB0aGlzLnBsYXllciwgXCJoZWFydFwiKTtcbiAgICB0aGlzLmJlZCA9IG5ldyBCZWQodGhpcywgXCJiZWRcIik7XG5cbiAgICB0aGlzLndzID0gd3M7XG5cbiAgICBjb25zdCBkYXRhSGFuZGxlciA9IG5ldyBEYXRhSGFuZGxlcih0aGlzLnBsYXllcik7XG5cbiAgICB0aGlzLndzLm9ubWVzc2FnZSA9IChldmVudCkgPT4ge1xuICAgICAgZGF0YUhhbmRsZXIuZ2V0TWVzc2FnZShldmVudC5kYXRhKTtcbiAgICB9O1xuXG4gICAgdGhpcy5kYXRhSGFuZGxlciA9IG5ldyBEYXRhSGFuZGxlcih0aGlzLnBsYXllcik7XG5cbiAgICBmdW5jdGlvbiBvbkNsaWNrKHBvaW50ZXI6IFBoYXNlci5JbnB1dC5Qb2ludGVyLCBzY2VuZTogR2FtZVNjZW5lKSB7XG4gICAgICBzY2VuZS5kZXN0aW5hdGlvblRvTW91c2UueCA9IHBvaW50ZXIueDtcbiAgICAgIHNjZW5lLmRlc3RpbmF0aW9uVG9Nb3VzZS55ID0gcG9pbnRlci55O1xuXG4gICAgICBpZiAoc2NlbmUuZGVzdGluYXRpb25Ub01vdXNlLnggLSBzY2VuZS5wbGF5ZXIuc3ByaXRlLmJvZHkueCA8IDApIHtcbiAgICAgICAgc2NlbmUucGxheWVyLnNwcml0ZS5wbGF5KFwibW92ZVwiKS5zZXRGbGlwWChmYWxzZSk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBzY2VuZS5wbGF5ZXIuc3ByaXRlLnBsYXkoXCJtb3ZlXCIpLnNldEZsaXBYKHRydWUpO1xuICAgICAgfVxuICAgICAgc2NlbmUucGh5c2ljcy5tb3ZlVG8oXG4gICAgICAgIHNjZW5lLnBsYXllci5zcHJpdGUsXG4gICAgICAgIHBvaW50ZXIueCxcbiAgICAgICAgcG9pbnRlci55LFxuICAgICAgICBzY2VuZS52ZWxvY2l0eVxuICAgICAgKTtcbiAgICAgIC8vIGNvbnNvbGUubG9nKFwiaW5pdGlhbDogXCIsIHNjZW5lLmRlc3RpbmF0aW9uKTtcbiAgICB9XG5cbiAgICB0aGlzLmlucHV0Lm9uKFwicG9pbnRlcmRvd25cIiwgKHBvaW50ZXI6IFBoYXNlci5JbnB1dC5Qb2ludGVyKSA9PlxuICAgICAgb25DbGljayhwb2ludGVyLCB0aGlzKVxuICAgICk7XG5cbiAgICB0aGlzLnBsYXllci5jcmVhdGVBbmltYXRpb25zKCk7XG5cbiAgICB0aGlzLnBoeXNpY3MuYWRkLm92ZXJsYXAoXG4gICAgICB0aGlzLnBsYXllci5zcHJpdGUsXG4gICAgICB0aGlzLmhlYXJ0LnNwcml0ZSxcbiAgICAgICgpID0+IHRoaXMuaGVhcnQubW92ZSgpLFxuICAgICAgbnVsbCxcbiAgICAgIHRoaXNcbiAgICApO1xuXG4gICAgdGhpcy5waHlzaWNzLmFkZC5vdmVybGFwKFxuICAgICAgdGhpcy5wbGF5ZXIuc3ByaXRlLFxuICAgICAgdGhpcy5iZWQuc3ByaXRlLFxuICAgICAgKCkgPT4gdGhpcy5iZWQuc2xlZXAoKSxcbiAgICAgIG51bGwsXG4gICAgICB0aGlzXG4gICAgKTtcbiAgfVxuXG4gIGNoYW5nZU1vdmVBbmltYXRpb24ocGxheWVyOiBQaGFzZXIuU2NlbmUsIGRlc3RpbmF0aW9uWDogbnVtYmVyKSB7XG4gICAgaWYgKGRlc3RpbmF0aW9uWCAtIHRoaXMucGxheWVyLnNwcml0ZS5ib2R5LnggPCAwKSB7XG4gICAgICB0aGlzLnBsYXllci5zcHJpdGUucGxheShcIm1vdmVcIikuc2V0RmxpcFgoZmFsc2UpO1xuICAgIH0gZWxzZSB7XG4gICAgICB0aGlzLnBsYXllci5zcHJpdGUucGxheShcIm1vdmVcIikuc2V0RmxpcFgodHJ1ZSk7XG4gICAgfVxuICB9XG5cbiAgbWFrZUFuaW0oa2V5OiBzdHJpbmcsIGZyYW1lTmFtZTogc3RyaW5nLCBudW1iZXJPZkZyYW1lczogbnVtYmVyKSB7XG4gICAgbGV0IG15QXJyYXkgPSBbXTtcbiAgICBmb3IgKGxldCBpID0gMTsgaSA8PSBudW1iZXJPZkZyYW1lczsgaSsrKSB7XG4gICAgICBsZXQgZm4gPSBmcmFtZU5hbWUgKyBpICsgXCIucG5nXCI7XG4gICAgICBteUFycmF5LnB1c2goe1xuICAgICAgICBrZXk6IGtleSxcbiAgICAgICAgZnJhbWU6IGZuLFxuICAgICAgfSk7XG4gICAgfVxuICAgIHJldHVybiBteUFycmF5O1xuICB9XG5cbiAgcHVibGljIHVwZGF0ZSgpIHtcbiAgICBjb25zdCBkaXN0TW91c2UgPSBQaGFzZXIuTWF0aC5EaXN0YW5jZS5CZXR3ZWVuKFxuICAgICAgdGhpcy5wbGF5ZXIuc3ByaXRlLngsXG4gICAgICB0aGlzLnBsYXllci5zcHJpdGUueSxcbiAgICAgIHRoaXMuZGVzdGluYXRpb25Ub01vdXNlLngsXG4gICAgICB0aGlzLmRlc3RpbmF0aW9uVG9Nb3VzZS55XG4gICAgKTtcblxuICAgIGlmIChkaXN0TW91c2UgPD0gMTApIHtcbiAgICAgIHRoaXMucGxheWVyLnNwcml0ZS5ib2R5LnZlbG9jaXR5LnNldFRvKDAsIDApO1xuICAgICAgdGhpcy5wbGF5ZXIuc3ByaXRlLnBsYXkoXCJpZGxlXCIpO1xuICAgICAgdGhpcy5kZXN0aW5hdGlvblRvTW91c2UueCA9IDA7XG4gICAgICB0aGlzLmRlc3RpbmF0aW9uVG9Nb3VzZS55ID0gMDtcbiAgICB9XG5cbiAgICAvLyBjb25zdCBkaXN0QmVkID0gUGhhc2VyLk1hdGguRGlzdGFuY2UuQmV0d2VlbihcbiAgICAvLyAgIHRoaXMucGxheWVyLnNwcml0ZS54LFxuICAgIC8vICAgdGhpcy5wbGF5ZXIuc3ByaXRlLnksXG4gICAgLy8gICB0aGlzLmJlZC5zcHJpdGUueCxcbiAgICAvLyAgIHRoaXMuYmVkLnNwcml0ZS55XG4gICAgLy8gKTtcbiAgICAvLyBpZiAoZGlzdEJlZCA8PSB0aGlzLmJlZC5zcHJpdGUuaGVpZ2h0KSB7XG4gICAgLy8gICB0aGlzLnBsYXllci5zcHJpdGUuYm9keS52ZWxvY2l0eS5zZXRUbygwLCAwKTtcbiAgICAvLyAgIHRoaXMucGxheWVyLnNwcml0ZS5wbGF5KFwiaWRsZVwiKTtcbiAgICAvLyAgIHRoaXMuYmVkLnVzZWQgPSB0cnVlO1xuICAgIC8vIH1cbiAgICAvLyB0aGlzLmJlZC51c2VkID0gZmFsc2U7XG4gIH1cbn1cbiIsImltcG9ydCBcInBoYXNlclwiO1xuaW1wb3J0IHsgR2FtZVNjZW5lIH0gZnJvbSBcIi4vZ2FtZS1zY2VuZVwiO1xuXG5jb25zdCBjb25maWc6IFBoYXNlci5UeXBlcy5Db3JlLkdhbWVDb25maWcgPSB7XG4gIHR5cGU6IFBoYXNlci5BVVRPLFxuICBzY2FsZToge1xuICAgIHdpZHRoOiA4MDAsXG4gICAgaGVpZ2h0OiA2MDAsXG4gIH0sXG4gIHBoeXNpY3M6IHtcbiAgICBkZWZhdWx0OiBcImFyY2FkZVwiLFxuICAgIGFyY2FkZToge1xuICAgICAgZGVidWc6IHRydWUsXG4gICAgfSxcbiAgfSxcbiAgcmVuZGVyOiB7XG4gICAgcGl4ZWxBcnQ6IHRydWUsXG4gIH0sXG4gIHBhcmVudDogXCJnYW1lXCIsXG4gIGJhY2tncm91bmRDb2xvcjogXCIjNzY1NDc4XCIsXG4gIHNjZW5lOiBHYW1lU2NlbmUsXG59O1xuXG5jb25zdCB3cyA9IG5ldyBXZWJTb2NrZXQoXCJ3czovL2xvY2FsaG9zdDozMjEwMFwiKTtcbndzLm9ub3BlbiA9IGZ1bmN0aW9uICgpIHtcbiAgd3Muc2VuZChcImdldFN0YXRzXCIpO1xuICBjb25zdCBnYW1lID0gbmV3IFBoYXNlci5HYW1lKGNvbmZpZyk7XG4gIGdhbWUuc2NlbmUuc3RhcnQoXCJHYW1lXCIsIHdzKTtcbn07XG4vLyBnYW1lLnNjZW5lLnN0YXJ0KFwiR2FtZVwiKTtcbiIsImltcG9ydCB7IEJhciB9IGZyb20gXCIuL2JhclwiO1xuaW1wb3J0IHsgUGh5c2ljcyB9IGZyb20gXCJwaGFzZXJcIjtcbmltcG9ydCBTdGF0dXMgZnJvbSBcIi4vc3RhdHVzXCI7XG5cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIFBsYXllciB7XG4gIHByaXZhdGUgX3N0YXR1c2VzOiBCYXJbXTtcbiAgc3ByaXRlOiBQaHlzaWNzLkFyY2FkZS5TcHJpdGU7XG4gIHNjZW5lOiBQaGFzZXIuU2NlbmU7XG5cbiAgY29uc3RydWN0b3Ioc2NlbmU6IFBoYXNlci5TY2VuZSwgeDogbnVtYmVyLCB5OiBudW1iZXIsIGtleTogc3RyaW5nKSB7XG4gICAgdGhpcy5zY2VuZSA9IHNjZW5lO1xuICAgIHRoaXMuc3ByaXRlID0gc2NlbmUucGh5c2ljcy5hZGQuc3ByaXRlKHgsIHksIFwicGxheWVyXCIpO1xuICAgIHRoaXMuc3ByaXRlLnNldFNjYWxlKDQsIDQpO1xuICAgIHRoaXMuc3ByaXRlLnNldERlcHRoKDAuNSk7XG4gIH1cblxuICBjcmVhdGVBbmltYXRpb25zKCkge1xuICAgIHRoaXMuc2NlbmUuYW5pbXMuY3JlYXRlKHtcbiAgICAgIGtleTogXCJpZGxlXCIsXG4gICAgICBmcmFtZXM6IHRoaXMubWFrZUFuaW1hdGlvbihcInBsYXllclwiLCBcInBsYXllcl9pZGxlXzAwXCIsIDQpLFxuICAgICAgZnJhbWVSYXRlOiA4LFxuICAgICAgcmVwZWF0OiAtMSxcbiAgICB9KTtcbiAgICB0aGlzLnNjZW5lLmFuaW1zLmNyZWF0ZSh7XG4gICAgICBrZXk6IFwibW92ZVwiLFxuICAgICAgZnJhbWVzOiB0aGlzLm1ha2VBbmltYXRpb24oXCJwbGF5ZXJcIiwgXCJwbGF5ZXJfd2Fsa19sZWZ0XzAwXCIsIDYpLFxuICAgICAgZnJhbWVSYXRlOiA4LFxuICAgICAgcmVwZWF0OiAtMSxcbiAgICB9KTtcbiAgfVxuXG4gIG1ha2VBbmltYXRpb24oa2V5OiBzdHJpbmcsIGZyYW1lTmFtZTogc3RyaW5nLCBudW1iZXJPZkZyYW1lczogbnVtYmVyKSB7XG4gICAgY29uc3QgbXlBcnJheSA9IFtdO1xuICAgIGZvciAobGV0IGkgPSAxOyBpIDw9IG51bWJlck9mRnJhbWVzOyBpKyspIHtcbiAgICAgIGNvbnN0IGZuID0gZnJhbWVOYW1lICsgaSArIFwiLnBuZ1wiO1xuICAgICAgbXlBcnJheS5wdXNoKHtcbiAgICAgICAga2V5OiBrZXksXG4gICAgICAgIGZyYW1lOiBmbixcbiAgICAgIH0pO1xuICAgIH1cbiAgICByZXR1cm4gbXlBcnJheTtcbiAgfVxuXG4gIHB1YmxpYyBzZXQgc3RhdHVzZXMoc3RhdHVzZXM6IFN0YXR1c1tdKSB7XG4gICAgaWYgKCF0aGlzLl9zdGF0dXNlcykge1xuICAgICAgbGV0IHkgPSAxMDtcbiAgICAgIHRoaXMuX3N0YXR1c2VzID0gc3RhdHVzZXMubWFwKChzdGF0dXMpID0+IHtcbiAgICAgICAgY29uc3QgYmFyID0gbmV3IEJhcih7IHNjZW5lOiB0aGlzLnNjZW5lLCB4OiAxMCwgeSwgc3RhdHVzIH0pO1xuICAgICAgICB5ICs9IDIwO1xuICAgICAgICByZXR1cm4gYmFyO1xuICAgICAgfSk7XG4gICAgfSBlbHNlIHtcbiAgICAgIHN0YXR1c2VzLmZvckVhY2goKHN0YXR1cywgaW5kZXgpID0+IHtcbiAgICAgICAgdGhpcy5fc3RhdHVzZXNbaW5kZXhdLnN0YXR1cyA9IHN0YXR1cztcbiAgICAgIH0pO1xuICAgIH1cbiAgfVxufVxuIiwiZXhwb3J0IGRlZmF1bHQgY2xhc3MgU3RhdHVzIHtcbiAgcHJpdmF0ZSBfbmFtZTogc3RyaW5nO1xuICBwcml2YXRlIF9jdXJyZW50X3ZhbHVlOiBudW1iZXI7XG4gIHByaXZhdGUgX21heF92YWx1ZSA9IDEwMDtcbiAgcHJpdmF0ZSBfbWluX3ZhbHVlID0gMDtcblxuICBjb25zdHJ1Y3RvcihuYW1lOiBzdHJpbmcsIGN1cnJlbnRfdmFsdWU6IG51bWJlcikge1xuICAgIHRoaXMuX25hbWUgPSBuYW1lO1xuICAgIHRoaXMuX2N1cnJlbnRfdmFsdWUgPSBjdXJyZW50X3ZhbHVlO1xuICB9XG5cbiAgcHVibGljIGdldCBuYW1lKCk6IHN0cmluZyB7XG4gICAgcmV0dXJuIHRoaXMuX25hbWU7XG4gIH1cblxuICBwdWJsaWMgc2V0IGN1cnJlbnRfdmFsdWUodmFsdWU6IG51bWJlcikge1xuICAgIHRoaXMuX2N1cnJlbnRfdmFsdWUgPSB2YWx1ZTtcbiAgfVxuXG4gIHB1YmxpYyBnZXQgY3VycmVudF92YWx1ZSgpIHtcbiAgICByZXR1cm4gdGhpcy5fY3VycmVudF92YWx1ZTtcbiAgfVxuXG4gIHB1YmxpYyBnZXQgbWF4X3ZhbHVlKCkge1xuICAgIHJldHVybiB0aGlzLl9tYXhfdmFsdWU7XG4gIH1cblxuICBwdWJsaWMgZ2V0IG1pbl92YWx1ZSgpIHtcbiAgICByZXR1cm4gdGhpcy5fbWluX3ZhbHVlO1xuICB9XG59XG4iXSwic291cmNlUm9vdCI6IiJ9