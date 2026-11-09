# Tower Defense MVP
A basic tower defense game implementation done in a few days.

<p align="center">
  <a>
    <img alt="Made With Unity" src="https://img.shields.io/badge/made%20with-Unity-57b9d3.svg?logo=Unity">
  </a>
  <a>
    <img alt="License" src="https://img.shields.io/github/license/JoanStinson/TicTacToeTDD?logo=github">
  </a>
  <a>
    <img alt="Last Commit" src="https://img.shields.io/github/last-commit/JoanStinson/TowerDefenseMVP?logo=Mapbox&color=orange">
  </a>
  <a>
    <img alt="Repo Size" src="https://img.shields.io/github/repo-size/JoanStinson/TowerDefenseMVP?logo=VirtualBox">
  </a>
  <a>
    <img alt="Downloads" src="https://img.shields.io/github/downloads/JoanStinson/TowerDefenseMVP/total?color=brightgreen">
  </a>
  <a>
    <img alt="Last Release" src="https://img.shields.io/github/v/release/JoanStinson/TowerDefenseMVP?include_prereleases&logo=Dropbox&color=yellow">
  </a>
</p>

<p align="center">
  <img src="https://github.com/JoanStinson/TowerDefenseMVP/blob/main/preview.gif">
</p>

## 📜 Kata Rules
* In the center of the provided battlefield there is a **Base** for the player to defend. Create a
system of spawnable “creeps”. Creeps spawn from the **SpawnPoints** already placed in
the battlefield. When they spawn, they automatically move towards the Base **in a straight
line (don’t implement or integrate any pathfinding, as NavMesh)**. Make the timing,
number, and behavior of spawned creeps easy to tweak and tune.
* When a number of creeps reach the player’s base, inform the player that has lost the game
-- feel free to add a health bar to the creeps or to the base. When the game is lost, display
the **LosePopup**.
* Create a system of placeable **turrets**. The player can instantiate a turret anywhere on the
battlefield.
* Make the turrets shoot projectiles at creeps. Projectiles that hit creeps cause damage to
them. Make the parameters for the amount of damage caused by a projectile and the
amount of damage a creep can take easy to tune and tweak.
* Implement a simple economy such as making each turret cost 5 coins to build and each
creep giving you a coin when it dies.
* Implement two types of turrets with different capabilities: a regular one and a
freeze/slow-down effect on the other. (You have both assets provided).
* Add different types of creeps with varying attributes such as speed and hit points. (You
have two different creep assets provided).
* Implement a system of waves. Once all the creeps of a particular wave are cleared, the
next wave starts. If all the waves are cleared and the base is still alive, then display the
**WinPopup**.
* Implement game reset functionality that allows the player to restart the game without
exiting Play Mode. The game should support a full lifecycle: starting, winning/losing, and
restarting — all within a single Play session. Ensure that game state is correctly reset
(e.g., enemies cleared, towers reset, resources reinitialized) without relying on manually
stopping and starting the Unity Editor.

## 👾 How to Add a New Enemy
1. Create a new prefab with a root script inheriting from ICreep
2. Add a new creep config to the prefab
3. Attach the prefab to a wave asset
<p align="center">
  <img src="https://github.com/JoanStinson/TowerDefenseMVP/blob/main/add enemy.PNG">
</p>

## 🤖 How to Add a New Turret
1. Create a new prefab with a root script inheriting from ITurret
2. Add a new turret config to the prefab
3. Attach the prefab to the turret list
<p align="center">
  <img src="https://github.com/JoanStinson/TowerDefenseMVP/blob/main/add turret.PNG">
</p>

## 🔍 Unit Tests
<p align="center">
  <img src="https://github.com/JoanStinson/TowerDefenseMVP/blob/main/tests.PNG">
</p>
