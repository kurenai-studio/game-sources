# Boats

## Project description
Boats is a simple 2D game. The player steers their boat between the two shores of a river trying to avoid obstacles such as stones and floating branches. The objective is to transport passengers appearing on both shores through the river. Each level of the story mode has a different goal and requires precise skills and strategy. There is a much harder survival mode where the current of the river is faster and there are more obstacles.
The game has a responsive design which fits on mobile and desktop devices. The user interface is as simple as possible and user input while guiding a boat through the river is meant to be intuitive and light. All visual elements are custom-made for this project.

## Input
Game input is based on custom wave object grouped into ripples. The player can control the movement of boats and obstacles by clicking and dragging along the surface of the river. The built-in Unity Event System interfaces (IPointerClickHandler and IDragHandler) are suitable for capturing user input on different devices.

## Game core
There is an object-oriented layer of abstraction at the bottom of the game logic. A base class in this part of the architecture is Movable, which is inherited by all moving game objects. It acts as a garbage collector for out-of-scene objects and enforces an event-based lifetime management. For example, all floating obstacles are destroyed once the river has dragged them far enough.
Hittables take care of collisions which involve damage and hit points for cases such as a log hitting a boat or two boats hitting each other. They add an additional "killed" lifetime event to handle sinking boats and other objects being destroyed due to collisions.
Creatables are just an abstract sub-layer which satisfies the open-closed principle. They are mainly used by spawners - game objects resembling factories for logs, passengers, etc. As number of creatables grows and different kinds of obstacles and passengers are introduced in later version of the game the Creatable class can help managing some of the things they have in common.

## Components
The main components of the game are boats and passengers. All boats have a rigid body component which lets them interact with the area effector of the river, shore colliders, and obstaces. A life bar is attached to each boat giving valuable information about hit points left by changing color from green to red and shrinking in size.
Passengers have a bit more special behaviour based on their origin and destination. This is why their position and actions are managed by a classical state machine. Some of the states are approaching, waiting, on-boat, leaving, etc. Each passengers waits for a boat near the shore and a pick-up area component is looking for passing boats. Passengers may leave after a set number of seconds if there are no boats close enough to take them. A transported passenger counts as a single point when counting score in story levels and survival mode.

## Levels
A LevelManagerBase singleton class is used to control most events that occur during a single level. It is a vital link between the user interface and the game logic, because it takes care of the score, the objective, the number of boats left and decides when the level is complete or failed. The Level and Story managers introduce the strange concept of singleton inheritance, but it is a suitable design pattern in such cases.

## User Interface
All UI components are designed to support different screen sizes and resolutions. The main menu and the level menus follow the concept of sliding screens while the river and the shores stay in the background accompanied by a famous theme song. All levels support basic actions such as pause, resume and restart. The menu of the survival mode also displays the highest score of the player.
