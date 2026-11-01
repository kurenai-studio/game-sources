# Mister Barista
by Karl Lilje 2020/02/05

## To Run: 
npx serve 
or 
rungame.bat (windows)

## Objective  
Select a cup of coffee.   \
If your choice matches what the Barista poured, you win 1 coin.   \
If you guess wrong, you lose 1 coin.

## Server
Uses a mock game server to simulate game logic  \
(src/mocks/gameserver)  \
https://github.com/BigFun123/Mister-Barista/blob/master/src/mocks/mock_gameserver.js  \
The switch between mock game server and real server happens in:  \
https://github.com/BigFun123/Mister-Barista/blob/master/src/services/gameserver.js  \
(real server is not implemented)

## Engine
Phaser 3.22  \
Included via CDN in index.html for simplicity  

## Scenes
Menu https://github.com/BigFun123/Mister-Barista/blob/master/src/game/scenes/scene_menu.js  \
Main Game https://github.com/BigFun123/Mister-Barista/blob/master/src/game/scenes/scene_main.js  \
Scores https://github.com/BigFun123/Mister-Barista/blob/master/src/game/scenes/scene_scores.js  \

## Classes
AGame Abstract Game Class  \
https://github.com/BigFun123/Mister-Barista/blob/master/src/game/agame.js  \
AGameServer Abstract Server Service Class \
https://github.com/BigFun123/Mister-Barista/blob/master/src/services/agameserver.js  \
Game Class  \
https://github.com/BigFun123/Mister-Barista/blob/master/src/game/game.js  \
GameState  \
https://github.com/BigFun123/Mister-Barista/blob/master/src/game/state.js  \
Cup Component  \
https://github.com/BigFun123/Mister-Barista/blob/master/src/game/components/cup.js  \
ToggleButton Component  \
https://github.com/BigFun123/Mister-Barista/blob/master/src/game/components/togglebutton.js


## Menu Screen
![Menu Screen](/doc/screen0.JPG)

## Game Screen
![Game Screen](/doc/screen1.JPG)

## Music
My Robot by Karl Lilje

## Assets
https://github.com/BigFun123/Mister-Barista/tree/master/assets