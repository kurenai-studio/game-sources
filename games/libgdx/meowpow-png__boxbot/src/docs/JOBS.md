# Jobs

This document describes how work enters the warehouse and how jobs move through the simulation.

## Job Types

There are two kinds of jobs: putaway and retrieval:

- putaway job moves an inbound package from the loading bay into storage
- retrieval job moves a stored package from its shelf to the loading bay for shipping

## Arrival

Jobs arrive continuously during a run.

Putaway jobs are created when inbound packages enter the warehouse.

Outbound orders arrive and start their delivery timer independently of the 
robot. A retrieval job is not created at that moment — only once the robot 
is free to act does it select a shelf to match one of the open orders.

Job arrival is deterministic for a given simulation seed, 
allowing the same run conditions to be reproduced.

## Availability

A job can only be acted on when its required package and destination are available.

Putaway requires an inbound package waiting at the loading bay and 
a free shelf to store it on. Retrieval requires a matching package 
in storage and enough room at the loading bay for the retrieved package.

Jobs that cannot currently be completed remain 
pending until their required conditions become available.

## Selection

When the robot becomes available, the controller decides which
pending job to process next, using its own logic.

Choosing between putaway and retrieval work is part of what
that logic has to balance to keep the warehouse running efficiently.

## Completion

A putaway job is complete once its package has been placed on its chosen shelf.

A retrieval job is complete once its package has been delivered to the loading bay.
Shipping the package after that point is handled separately by the truck.

See [SHIPPING.md](SHIPPING.md) for more information.

## Difficulty

The rate at which work arrives increases over the course of a run.

This creates growing pressure on the warehouse without changing the underlying
job rules. The exact progression is configured separately from the job system.
