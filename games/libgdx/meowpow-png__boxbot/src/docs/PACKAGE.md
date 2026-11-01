# Package

This document describes package types, demand, storage, 
and what happens when an outbound order expires.

See [SHIPPING.md](SHIPPING.md) for how packages move through the loading bay.

## Types

Every package is one of three types, distinguished by color: red, green, or blue.

Package type does not affect how a package behaves physically. 
It exists so that inventory can be matched against demand.

## Demand

Demand for each package type is determined at the start of a run from simulation seed.

The distribution is not shown directly to the player. 
Instead, the player has to infer which package types are in greater 
demand by observing the packages and outbound orders that appear during the run.

## Storage

Where packages are stored matters because retrieval begins 
from the shelf holding the nearest package of the ordered type.

Storage decisions therefore affect future travel distance. 
Packages expected to be retrieved frequently can be placed
more conveniently than packages likely to remain in storage longer.

## Outbound Orders

An outbound order requests a package type, not a specific 
package. Which package ends up fulfilling it is only decided 
once work on the order begins, not when the order first appears.

Each order has its own identity, distinct from its type and 
deadline, so two orders can want the same type at the same time 
without being mistaken for one another. When more than one order 
is open for a type, whichever arrived first is the one fulfilled.

## Delivery Timer

An outbound order has a limited amount of time to ship. If its 
timer expires, the order fails, even if a package is already on 
its way to fulfill it. Because no package is ever reserved for 
an order, nothing returns to inventory; whatever package was 
fulfilling it simply reverts to neutral wherever it currently is.

> [!NOTE]
> A timeout loses the order, not the package.
