# Cosmic Dash #MadeWithDefold Jam 2025

![logo](/media/game_logo.png)

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)


## Overview

This is the source code of the Cosmic Dash game, which was made for MadeWithDefold Jam 2025.

Play on itch.io: https://insality.itch.io/cosmic-dash

Forum postmortem: https://forum.defold.com/t/cosmic-dash-is-published-madewithdefold-jam-2025/81557

This game was made with [tiny-ecs](https://github.com/bakpakin/tiny-ecs) wrapped in the [Decore](https://github.com/Insality/decore) library.

## Project structure

```sh
cosmic-dash/
├── assets/ # General game assets
├── decore/ # Decore ECS Data Manager
├── detiled/ # Tiled to Decore converter
├── entity/ # Game entity objects and definitions
├── game/ # Main game script to create ECS world
├── locales/ # Localization files
├── music/ # Game music sources
├── system/ # Game systems
├── tiled/ # Tiled project
├── widget/ # Druid widgets
├── loader.script # Bootstrap script to initialize the game
├── game.project # Defold project file
```

Start reading the game from `loader.script` and `game.script` files. Start with `loader.script` to initialize the game, then `game.script` to create the world and start the game itself.

## ECS part

All systems are defined in the `system/systems.lua` file.

Each system can be split into the following structures:

```sh
system/name/
├── name_system.lua # System implementation
├── name_command.lua # World system API for other systems
```

All entities are defined in the `entity/entities.lua` file.

Each entity can be split into the following structures:

```sh
entity/name/
├── name_entity.lua # Entity definition
├── name.collection # Game object for the entity (possibly go or gui)
├── name_panthera.lua # Panthera animation for the entity
```

## License

This project is licensed under the MIT License - see the LICENSE file for details. This project is published for educational purposes.

## ❤️ Support project ❤️

Your donation helps me stay engaged in creating valuable projects for **Defold**. If you appreciate what I'm doing, please consider supporting me!

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)
