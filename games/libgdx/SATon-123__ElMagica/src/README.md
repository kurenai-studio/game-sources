# ElMagica

**Build Beta1.0 — Endless Play / Mechanics Test**

Ru:

Небольшая пиксельная игра про мага, который поднимается по бесконечной башне. Четыре стихии, разные враги, боссы и торговец между боями. Чем выше забираешься, тем сложнее становится.

![ElMagica](assets/ui/menu/cover.png)

## Зачем я это делал

Хотел собрать свою игру: чтобы можно было выбрать стихию, попробовать разные атаки, прокачивать персонажа и посмотреть, насколько далеко получится зайти. Началось всё с сетки клеток и квадрата, который умеет двигаться и стрелять. Потом появились враги, боссы, комнаты, магазин, проестенькая пиксельная графика и сгенерированый на пайтоне звук.

Делал на Java и LibGDX, прибегая к помощи OpenAI Codex. Я придумывал механики, реализовывал их как мог, тестировал, менял баланс и постепенно разбирался в реализации. Codex реализовывал сложные технические решения, на которые моих сил не хватало, оптимизировал и дебагал код. Картинки тоже сделаны с помощью ИИ, музыка и эффекты — через скрипт синтеза звука.

Сейчас это рабочая бета для проверки механик. Хочу понять, что интересно играть, где ломается баланс и что стоит развивать дальше.

## Попробовать

Нужна **Java 17+**, рекомендую Java 21. Java в комплект не входит.

1. Скачай [ElMagica-Beta1.0-play.zip](https://github.com/SATon-123/ElMagica/releases/download/v1.0.0-beta.1/ElMagica-Beta1.0-play.zip).
2. Распакуй архив целиком и открой папку `play`.
3. Запусти `Run-ElMagica.bat` из этой папки.

Этот файл находится в архиве игры. В исходниках (`Source code` или `ElMagica-Beta1.0-source.zip`) его нет. 

Для запуска из исходников на Windows нужен JDK (рекомендую Java 21). Открой PowerShell в корне распакованного проекта — рядом с `gradlew.bat` и `settings.gradle` — и выполни:

```powershell
.\gradlew.bat lwjgl3:run
```

## Если хочется покопаться

- [Сборка, проверки и структура проекта](docs/PROJECT_GUIDE.md)
- [Заметки по коду](docs/CODE_REVIEW.md)
- [Ассеты и их происхождение](docs/ASSETS.md)
- [Как внести изменения](CONTRIBUTING.md)

**Автор: SA_Ton_**  
**Спасибо: OpenAI Codex (GPT-6.1 Sol)**

Код проекта — [MIT](LICENSE). У сторонних библиотек [свои лицензии](THIRD_PARTY_NOTICES.md).



En:

A small pixel-art game about a mage climbing an endless tower. Four elements, different enemies, bosses, and a merchant between fights. The higher you climb, the harder it gets.

![ElMagica](assets/ui/menu/cover.png)

## Why I made this

I wanted to make my own game: something where you could choose an element, try different attacks, upgrade your character, and see how far you could get. It all started with a grid of tiles and a square that could move and shoot. Then came enemies, bosses, rooms, a shop, simple pixel art, and sound generated with Python.

I made it with Java and LibGDX, with help from OpenAI Codex. I came up with the mechanics, implemented them as best I could, tested the game, adjusted the balance, and gradually learned more about how everything works. Codex helped implement complex technical solutions that were beyond my abilities, optimize the code, and debug it. The images were also made with AI, while the music and sound effects were created using a sound synthesis script.

Right now, this is a working beta for testing the mechanics. I want to find out what's fun to play, where the balance breaks, and what is worth developing further.

## Try it out

Java 17+ is required; Java 21 is recommended. Java is not included.

1. Download [ElMagica-Beta1.0-play.zip](https://github.com/SATon-123/ElMagica/releases/download/v1.0.0-beta.1/ElMagica-Beta1.0-play.zip).
2. Extract the whole archive and open the `play` folder.
3. Run `Run-ElMagica.bat` from that folder.

This launcher is in the playable archive, not in `Source code` or `ElMagica-Beta1.0-source.zip`. 

To run from source on Windows, install a JDK (Java 21 recommended). Open PowerShell in the extracted project root, next to `gradlew.bat` and `settings.gradle`, and run:

```powershell
.\gradlew.bat lwjgl3:run
```

## If you want to explore the code

- [Build, testing, and project structure](docs/PROJECT_GUIDE.md)
- [Code review notes](docs/CODE_REVIEW.md)
- [Assets and their origins](docs/ASSETS.md)
- [How to contribute](CONTRIBUTING.md)

**Author: SA_Ton_**  
**Thanks: OpenAI Codex (GPT-6.1 Sol)**

The project code is licensed under [MIT](LICENSE). Third-party libraries have [their own licenses](THIRD_PARTY_NOTICES.md).
