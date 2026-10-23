# Orbit Defender

[![CI](https://github.com/Momik-jpg/orbit-defender-monogame/actions/workflows/ci.yml/badge.svg)](https://github.com/Momik-jpg/orbit-defender-monogame/actions/workflows/ci.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Kurz erklärt
Orbit Defender ist mein grösstes C#-Game im Portfolio.  
Ziel war, saubere Architektur, Spielmechanik und gute Bedienung in einem grösseren Projekt zu verbinden.

## Was kann das Projekt?
- Echtzeit-Gameplay mit Game-Loop (`Menu`, `Playing`, `Paused`, `GameOver`)
- Steuerung per WASD oder Pfeiltasten
- schnelleres Schiff für flüssigeres Gameplay
- Schusssystem mit Cooldown, Score und Level-Fortschritt
- Gegner-Spawn mit steigender Schwierigkeit
- Kollisionen (`Player <-> Asteroid`, `Laser <-> Asteroid`)
- Namenseingabe für personalisierte Highscores
- persistente Top-10-Highscores als JSON
- atomare Highscore-Speicherung ohne falsche Erfolgsmeldung

## Projektaufbau (OOP)
```text
Core/
  GameMode, GameSettings, GameSession
Models/
  PlayerShip, LaserShot, Asteroid, Star, HighScoreEntry
Services/
  IInputService + InputService
  ISpawnService + SpawnService
  ICollisionService + CollisionService
  IHighScoreService + HighScoreService
OrbitDefenderGame.cs
```

## Architektur

`OrbitDefenderGame` koordiniert die Spielsitzung und die klar getrennten Dienste.

```mermaid
flowchart TD
    Game["OrbitDefenderGame"] --> Session["GameSession"]
    Game --> Input["InputService"]
    Game --> Spawn["SpawnService"]
    Game --> Collision["CollisionService"]
    Game --> Scores["HighScoreService"]
    Scores --> File[("Top-10-Highscores · JSON")]
```

## Start
1. Voraussetzungen:
   - .NET 8 SDK
   - OpenGL-fähige Umgebung (MonoGame DesktopGL)
2. Im Projektordner ausführen:

```powershell
dotnet restore
dotnet run
```

## Tests

Der Spawn-Service akzeptiert optional einen `Random` mit festem Seed.
Die Tests prüfen reproduzierbare Asteroiden, Spawn-Grenzen, Level-Skalierung
und die Erzeugung sowie Wiederverwendung von Sternen ohne Spielfenster.
Im normalen Spiel bleibt die Zufallsquelle automatisch erzeugt.

```powershell
dotnet test tests/OrbitDefender.Tests/OrbitDefender.Tests.csproj
```

## Steuerung
- Bewegung: `WASD` oder Pfeiltasten
- Schiessen: `SPACE`
- Pause: `P`
- Fortsetzen: `P` oder `ENTER`
- Neustart nach Game Over: `ENTER` oder `R`
- Zurück ins Menü: `ESC`

## Was ich gelernt habe
- grössere C#-Projekte in klare Komponenten aufteilen
- stabile Game-Loop mit Zustandswechseln bauen
- Services und Interfaces für wartbaren Code nutzen
- JSON-Persistenz robust in ein Spiel integrieren

## Warum im Portfolio?
Orbit Defender zeigt, dass ich OOP-Strukturen nicht nur für Business-Apps, sondern auch für interaktive Echtzeit-Anwendungen einsetzen kann.


## Mein Beitrag

Ich habe die Spielmechanik, den Game Loop, die Service-Struktur, die Kollisionslogik und die persistente Highscore-Verwaltung umgesetzt.

## Lizenz

MIT – siehe [LICENSE](LICENSE).
