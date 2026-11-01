# Movement

This document describes how the robot moves through the warehouse.

## Grid

The warehouse is divided into cells.

Some cells are walkable while others are blocked by shelves 
or other fixed parts of the map. The robot can move only through walkable cells.

## Movement

The robot moves between adjacent cells and follows a valid route to its destination.

Movement is handled by the simulation rather than controlled one step 
at a time by the player. The player chooses what the robot should do or 
where it should go, and the robot follows the route required to get there.

## Destinations

Jobs and other actions can only target locations the robot can reach.

If no valid route exists, the action cannot begin.

## Facing

The robot may turn to face a different direction without moving to another cell.

Turning affects presentation only and does not consume simulation time or battery.
