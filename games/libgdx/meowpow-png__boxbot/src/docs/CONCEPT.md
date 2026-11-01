# Concept

A small Java warehouse simulation game where the player manages 
a robot and tries to keep the warehouse operating for as long as possible.

## World

The game takes place in one grid-based warehouse with one robot,
one loading bay, one charging station, and a fixed set of shelves.

Each shelf can hold one package, and the robot can carry one package at a time. 
The engine handles movement and pathfinding between locations.

## Jobs

Jobs continuously arrive during the simulation.

Putaway jobs require moving incoming packages from the loading bay to a shelf.
Retrieval jobs require moving stored packages from a shelf back to the loading bay for shipping.

The player decides which job to process next, where incoming packages 
should be stored, and when the robot should stop working to recharge.

## Time and Battery

Every action has a cost.

Moving one cell consumes both time and battery. Picking up and dropping off
packages consumes time, and charging restores battery while also consuming time.

These costs force the player to balance short-term job completion against travel distance,
warehouse organization, and the risk of running out of battery at a bad moment.

## Failure

Outbound orders have a delivery timer.

If packages are not retrieved and shipped before their timers expire, they count as 
failed deliveries. If too many deliveries fail, the warehouse fails and the run ends.

## Score

The score is the number of outbound orders successfully completed before the warehouse fails.

The goal is to keep the warehouse running for as long as possible by making
efficient decisions about job order, package placement, travel, and charging.
