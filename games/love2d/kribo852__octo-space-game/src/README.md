# A space dodger game project using the Love 2D Lua framework


## installation
install the Love 2D framework to run the game


## Controls
Control the spaceship with the keys "up", "left" and "right"
Jump wormholes with the key "space"

Avoid crashing into planets. Look out for the enemies

## Design of the code
there are three lua modules that work in a similar fashion  

- keyboard.lua, here most keyboard interactions are registered. Different game states can have different keys registered. 
- drawer.lua, here all the screen drawing is registered.
- action_runner.lua here all actions are registered and run each game tick. functions run in the action_runner shall return true if they are active, and false if they are spent and shall be discarded. The main game action is discarded when the player dies, and the wormhole action is discarded when the player has traveled the worm hole.  

## Current state of the project
The game is fully functional, but there some small things that I consider adding still

- [ ] some refactoring, to help implement additional features
- [x] remove enemies and lasers that are too far away from the player, this is to avoid using unnesseccary memory
- [x] play a little beep when the enemies fire a laser
- [x] make the enemies crash into planets, to remove them from the game
- [x] debris, that makes it easier to see which direction the player is traveling
- [x] a life meter, so the player can get hit multiple times by enemy lasers, this would open up for enemies fireing more frequently
- [x] after game over, show the score achived on the game over screen 
- [ ] converting player speed with a key press, to energy, to open wormholes
- [ ] better configuration for meters, score, map, speed, life, energy ...
- [ ] save high scores to a file

