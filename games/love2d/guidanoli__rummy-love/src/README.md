# Rummy in LÖVE

This is an implementation of a variation of the classic rummy game (called _mexe-mexe_ in Brazil) in LÖVE, a Lua game engine.

## Dependencies

* [LÖVE](https://love2d.org/)

## How to run

```sh
git clone https://github.com/guidanoli/rummy-love/
cd rummy-love
love .
```

## Mouse commands

| Button | Object | Description |
| :-: | :-: | :- |
| Left | Deck | Draw the top card from the stock |
| Left | Card | Select the card |
| Right | Meld | Move selected card(s) to meld |
| Right | Table | Create new meld from selected card(s) |

## Keyboard commands

| Key | Description |
| :-: | :- |
| `u` | Undo the last move |
| `e` | Unselect all cards |
| `d` | Print debugging information |
| `r` | Refresh game rendering information |
