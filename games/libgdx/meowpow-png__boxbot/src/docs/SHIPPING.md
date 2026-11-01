# Shipping

This document describes how packages enter and leave the warehouse through the loading bay.

## The Loading Bay

The loading bay is the warehouse's only connection to the outside world.

Inbound packages wait there until they are put away. Outbound packages
wait there after retrieval until they are collected for shipping.

Both directions share the same limited bay capacity,
so every package waiting there occupies physical space.

## The Truck

A truck visits the loading bay on a fixed recurring schedule.

On each visit, it works through its load one package at a time
instead of unloading everything at once. It picks up the next
outbound package waiting in the bay, then drops off the next package
from its manifest onto any free tile. A fixed delay separates each
of these operations, so a visit plays out as a steady back-and-forth.

> [!NOTE]
> Pickup happens before drop-off in each step, so a tile freed
> by an outgoing package can be reused by the very next drop-off.

If there's nothing to pick up, or nowhere to drop off, the truck simply waits
until the bay changes. It never skips a package and never leaves early on its
own. A visit normally only ends once the truck has picked up and dropped off
everything it came with.

> [!NOTE]
> The player can force the truck to depart early from the HUD, but only
> once its manifest is fully dropped off. Outstanding pickups are forfeited
> for that visit; the control is unavailable while the truck is en route or
> still has packages left to drop off.

## The Manifest

What a truck delivers next isn't decided when it arrives, it's decided
the moment it leaves. Departing, it assembles a shipment manifest:
the batch of packages it will bring on its next visit.

Colors are chosen deterministically, covering whichever colors are short 
of their storage quota. Those quotas are sized from the same demand model 
that drives retrieval, so popular colors still make up most of what 
the truck brings, without leaving less-popular colors to chance. 

The manifest can never carry more packages than the truck's 
capacity, but it isn't guaranteed to reach that number either. 
Storage quotas, described below, decide how much of each 
color the warehouse actually has room for. 

If demand is already satisfied for every color, 
the truck can arrive with a smaller manifest, or none at all.

Because the manifest is set in advance, what's coming is 
known before the truck shows up, not revealed as it happens. 
The truck's very first manifest is created when it's set up, 
so even the opening visit is already known ahead of time.

## Storage Quotas

The warehouse doesn't want unlimited stock of every color, it wants 
a mix that reflects demand. Each color gets a target share of total 
shelf capacity, taken directly from that color's weight in the demand model.

Demand weights already form a complete distribution, so the targets
they produce always add up to the warehouse's full shelf count. 

Here is an example of a 20-shelf warehouse with
demand weighted 50% blue, 30% red, and 20% green:

```
target(blue)  = round(0.50 x 20) = 10
target(red)   = round(0.30 x 20) = 6
target(green) = round(0.20 x 20) = 4
```

A color's live count is everything of that color currently inside 
the warehouse: on a shelf, waiting in the bay, or being carried by
the robot. It only stops counting once the truck picks it up and it
leaves for good. A color is at quota once its live count reaches its
target, and stays that way until retrieval brings the count back down.

A package's color isn't necessarily permanent, either. A package 
reverts to generic stock if the order it was retrieved for goes
unfulfilled. Once that happens it stops counting toward its old 
color's live count immediately. Live counts always follow a 
package's current color, not the color it arrived as.

> [!NOTE]
> Targets are measured against shelf capacity only, not shelf
> space plus bay space. A color can hit its target slightly 
> before its shelves are literally full, because packages of
> that color already sitting in the bay count against it too.

## Filling a Manifest

Building a manifest means covering each color's deficit: 
how far its live count sits below its storage quota target.
Colors already at quota have no deficit and are left out entirely.

If every deficit together fits within the truck's capacity, 
the manifest simply brings exactly what's missing, color for color.
A manifest can end up smaller than capacity this way, down to empty
when the whole warehouse is already stocked to its demand-proportional mix.

When total deficit exceeds capacity, the truck can't cover 
everyone this trip, so capacity is split across colors proportional
to their share of the total deficit, the same largest-remainder method 
used for quota targets. A color's split is capped by its own deficit,
so it never receives more than it actually needs.

Take a truck with capacity 5, where blue is short 8, 
red is short 3, and green is already at quota:

```
total deficit = 8 + 3 = 11, which exceeds capacity 5

blue = round(8 / 11 x 5) = round(3.6) = 4
red  = round(3 / 11 x 5) = round(1.4) = 1

manifest = 4 blue, 1 red
```

Quotas are only checked while a manifest is being built. 
Once the truck sets off with it, that manifest is fixed: 
every package in it gets delivered over the course of 
the visit, even if storage levels shift in the meantime.

## Capacity

The truck's capacity is a single number, but it means 
something slightly different on each side of a visit.

Pickup always targets exactly capacity: it picks up outbound
packages until it has that many or the bay runs out of them. 
Drop-off treats capacity as a ceiling instead of a target, 
since storage quotas can leave a manifest short, as described above.

That's separate from the loading bay's own capacity, which is 
about physical space rather than the truck's load. If the bay is 
full when the truck tries to drop off, it doesn't lose the package
or skip it, it just waits for a tile to open up before continuing.

> [!NOTE]
> There is no overflow area or separate queue inside the warehouse.

## Restocking Model

Drop-off capacity does not stay fixed at the truck's full capacity for
the whole run. It cycles between full strength and a throttled floor,
so restocking happens in phases rather than as a constant stream.

A restock factor scales how much of each 
visit's drop-off ceiling actually gets used:

```
half = cycleLengthTicks / 2
phase = t mod cycleLengthTicks

restockFactor(t) =
  1.0 - (1.0 - r_min) * (phase / half)              if phase < half
  r_min + (1.0 - r_min) * ((phase - half) / half)   otherwise

effectiveDropoffCapacity(t) = round(truckCapacity * restockFactor(t))
```

`t` is ticks elapsed since the run began, the same clock the escalation
model in [DIFFICULTY.md](DIFFICULTY.md) uses. The shape is a triangle
wave: capacity drains linearly down to `r_min` of its maximum, then
recovers linearly back to full, on a fixed cycle. 

It never exceeds the truck's normal capacity, so it only ever throttles
deliveries, it never adds extra ones on top of what the quota math already allows.

Starting values:

| param            | value |
|------------------|-------|
| cycleLengthTicks | 2400  |
| r_min            | 0.35  |

With `truckCapacity: 6`, effective drop-off
capacity moves over one cycle. It never reaches zero.

```text
6 → 5 → 4 → 3 → 2 → 3 → 4 → 5 → 6
```

### Floor Guard

The restock factor alone doesn't guarantee any single color stays
stocked, since a popular color could still get squeezed low during a trough. 

A separate floor protects each color individually: if a color's
live count drops below a fixed fraction of its quota target, that
color is exempt from the restock factor for that visit and receives
its full deficit share regardless of where the cycle currently sits.

```
floorLiveCount(color) = ceil(floorFraction * target(color))
```

Starting value: `floorFraction = 0.15`.

This keeps the wave's amplitude free to be tuned for how strongly
it pushes activity toward the back of the warehouse, without 
risking a color running out entirely.

Supply controls incoming stock. The demand model below controls order
arrivals. They are configured separately, but their cycles are tuned to
work against each other so the warehouse visibly fills and depletes.

## Demand Model

Order demand runs in the opposite phase to supply. When the truck can
bring plenty of stock, orders arrive less often and the warehouse fills.
When supply is throttled, orders arrive more often and that stock is
drawn down again.

The demand planner has its own configuration and does not read supply
state at runtime. To create this rhythm, configure both cycles to the
same length and start demand at its low point when supply starts at full
strength.

```
half = cycleLengthTicks / 2
phase = t mod cycleLengthTicks

demandRateFactor(t) =
  d_min + (d_max - d_min) * (phase / half)          if phase < half
  d_max - (d_max - d_min) * ((phase - half) / half) otherwise

effectiveOrderInterval(t) =
  round(baseOrderIntervalTicks / demandRateFactor(t))
```

This is an opposing wave, not a direct dependency between the demand
and supply planners. The base interval remains the average order pace;
the rate factor only shifts arrivals earlier or later within the cycle.

Starting values:

| param                       | value |
|-----------------------------|-------|
| cycleLengthTicks            | 800   |
| baseOrderIntervalTicks      | 15    |
| d_min                       | 0.5   |
| d_max                       | 1.5   |

At the supply peak, orders arrive every 30 ticks. At the supply trough,
they arrive every 10 ticks. The average rate stays centered on the
15-tick base interval, so tune that base value to control the run's
overall pressure.

Difficulty escalation remains separate. It can change the base interval
over a run, while this model continues to create the stock-and-depletion
rhythm around it.

## Orders and Shipping

Outbound orders arrive independently from the truck schedule. 
Retrieving a package to the loading bay does not ship it 
immediately; it must remain there until a truck collects it.
