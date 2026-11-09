# Open Practice: A FOSS Hockey Game

<a href="https://wolfrats.com/hockey">
<img width="627" height="360" alt="gameplay" src="https://github.com/user-attachments/assets/4b3097d5-da1f-4f36-a173-a2982dd86f91" />
</a>


This repo contains the code and assets for _Open Practice: A FOSS Hockey Game_, an arcade-style,
local multiplayer ice hockey game. The game is made with Godot and compiled for the web automatically.
It is playable in-browser [here](https://wolfrats.com/hockey). 

# Controls
The game supports both keyboard controls as well as joysticks. It supports 1-4 players locally.

| Action | Keyboard | Joystick            |
|--------|----------|---------------------|
| Move   | WASD     | Left Stick          |
| Shoot  | Spacebar | X                   |
| Swap   | Q        | Y                   |
| Check  | E        | B                   |
| Pass   | F        | A                   |
| Grab   | Hold M   | Hold Right Shoulder |

When the shoot button is pressed and held, an aiming+power indicator will pop up. The longer
it charges, the more powerful the shot will be. The movement controls while charging a shot will instead
change the direction of the shot, allowing you to aim. You may charge shots without possessing the puck, allowing
for one-timers. Whether you automatically take control of the puck carrier is configurable, and pressing the pass button
will have an AI teammate pass you the puck if you don't have it. If you do have the puck, the pass button sends the puck towards
the teammate closest to the line you are currently aiming the puck.

You may slam into another skater to attempt to knock the puck free. You may also cross-check them. Both actions
deal some damage to the other player's stamina. A player will collapse on the ice if their stamina is depleted.
Stamina slowly recharges over time. Stamina may also be recharged by changing shifts by skating to your team's bench.

You may grab other skaters to attempt to slow them down. Checking them while grabbing will deal additional damage. Being checked
has a chance of breaking the grab. 

Playing dirty in front of the ref may lead to penalties and a power play for the opposing team.

<details>
<summary>
<h1>Team Bios</h1>
</summary>
The game currently features 17 totally original teams.

### The Wide Street Wackos
The best team. Prefers violence over skilled hockey.

### The Thunderbolts
A balanced team focused on strong play.

### The Flightless Birds
A team focused on good control over the puck. The worst team, despite their great success.

### The Candy Canes
An offense-focused team aiming to win with high-skill shooters.

### The Loch Ness Monsters
A team hoping to balance offense and defense while still getting the puck to their star snipers.

### The Shapes
A team focused on possession, cycle-control, and generating offensive chances.

### The Pinkertons
A fictional team, I needed an all-pink team to bring incredible violence to the game.

### The Bears
Another team focused on hurting players.

### The Long Island Ice Teas
A defensive team.

### The Haberdashers
A fairly balanced team focused on winning the most.

### The Rockslides
A team focused on generating scoring chances while sacrificing everything else.

Plus 6 teams I did not yet write a bio for: The Queens, the Swords, the Syrups,
the Evil Wrenches, the Tire Fires, and the Gasoline Fights.

To be added:  
- The Hot Wings  
- The Ranges  
- The Music  
- The Congressmen  
- The Planes  
- The Hammerheads  
- The Hosers  
- The Mighty Movie Tie-Ins  
- The Elephants  
- The Silver Squires  
- The Apache Choppers  
- The Blue Belts  
- The Prey  
- The Block Busters  
- The Freeze  
- The Lowers


</details>

# AI Disclosure
AI was used somewhat heavily for the game's code, mostly for trivial features and tweaks. No AI was, or ever will be, used for
graphical or audio assets. At the time of writing, the split of human-to-ai code was about 60%-40%.

# TODO:
- Remove all placeholder assets
- Improve UI and cutscenes
- Add more teams
- Improve readme
