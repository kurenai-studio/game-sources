# Difficulty

This document describes how pressure increases over the course of a run.

## Progression

Difficulty increases gradually as the simulation continues.

The main source of pressure is the rate at which new work arrives. 
Early in a run, the warehouse has enough time to recover from inefficient decisions. 

Later, jobs arrive more frequently and leave less room for delay.

## Escalation

Difficulty progression is deterministic for a given simulation seed.

The escalation follows a configured strategy rather than changing unpredictably 
during a run. This keeps repeated runs comparable while still allowing 
the pressure curve to be tuned independently from other systems.

## Purpose

There is no final difficulty level to reach.

The increasing workload exists to make the warehouse progressively 
harder to manage until the player can no longer keep up. 

Better decisions therefore result in surviving further into the same escalating workload.
