This prototype was a project made for the Godot Wild Jam #60 in July 2023. 
The game is completely functional, allowing the player to place towers by left-clicking of the right menu buttons. Right-click to cancel tower placement. 
There are three waves of, which are to experiment with. If need be, press CTRL+ALT+M to add 1000 dollars, which can be used to buy more expensive towers. Calling a wave early by clicking the red bubble also gives the player money dependant on how long it took to click.
Left-click a tower to see its current fuel amount and available upgrades.
Each tower has it's own attack behaviour and malfunction behaviour (once the tower runs out of fuel), which is described below.

ArchOS
- Cheap, rotates slow, shoots slow.
- No additional effects.
- Deativated on malfunction.
  
Gattling Golem
- Expensive, fast rotation, firing rate accelerates for each consecutive shot.
- On malfunction, fires a barage of projectiles before deactivating.
  
Jukebot
- Slightly cheap. Fires in an area of effect, damaging enemies in a circle around itself. Shoots slow.
- Increases damage of towers around itself.
- Permanently increases damage of towers in huge area on malfunction.
  
Newtron
- Slightly expensive, shoots fire darts that do constant damage to enemy for a short amount of time (aka inflicts the fire status effect on hit enemies).
- Can only be placed in water.
- Creates water tiles around itself on malfunction.
  
SEBA
- Average price, shoots bombs that explode and damage in an area.
- Tower itself explodes on malfunction, replacing ground with decorative dirt on surrounding tiles and creates a scorched tile in the center. No towers can be placed on that tile.


Godot Engine Logo
Copyright (c) 2017 Andrea Calabró

This work is licensed under the Creative Commons Attribution 4.0 International
license (CC BY 4.0 International): https://creativecommons.org/licenses/by/4.0/
