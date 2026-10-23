# entities/colony/

`Colony` — autoload holding `colony: Dictionary[int, Rat]`, the live registry
of every generated rat by id. Shared global state only; no behavior lives here.
