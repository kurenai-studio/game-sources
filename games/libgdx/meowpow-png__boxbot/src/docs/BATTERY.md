# Battery

The robot's battery limits how far it can travel before it needs to recharge.

## Draining

Battery is consumed only when the robot moves between cells. Turning, 
picking up packages, and dropping them off do not consume battery.

## Charging

The robot can recharge only at the charging station.

Once charging starts, it continues until the battery is full and cannot 
be interrupted. Charge is restored steadily over time, so arriving 
with less battery means spending longer at the station.

## Running Out

Reaching zero battery does not end the run, but the robot can no longer move.

If this happens away from the charging station, the robot is effectively 
stranded and cannot recover. The player must therefore plan charging 
early enough to avoid running out before reaching the station.
