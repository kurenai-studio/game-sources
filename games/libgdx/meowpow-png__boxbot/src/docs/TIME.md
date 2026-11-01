# Time

This document describes how time passes inside the simulation and how long robot actions take.

## Ticks

Simulation time is measured in ticks.

All gameplay systems use ticks rather than real-world seconds. 
This keeps action timing consistent regardless of rendering speed or playback settings.

## Movement

Moving into an adjacent cell takes one tick.

A longer route therefore takes time proportional to the number of cells the robot travels.

## Actions

Picking up and dropping off packages each take a fixed number of ticks.

Once an action begins, it continues until complete and cannot be interrupted by another command.

Charging also consumes simulation time. Its duration depends on how 
much battery needs to be restored rather than using a fixed action duration.

## Playback Speed

Changing playback speed only changes how quickly simulation 
ticks are processed in real time. It does not change action durations, 
movement costs, job timers, or any other gameplay rule measured in ticks.
