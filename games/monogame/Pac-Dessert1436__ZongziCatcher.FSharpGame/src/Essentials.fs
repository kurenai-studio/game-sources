module ZongziCatcher.FSharpGame.Essentials

open Microsoft.Xna.Framework.Audio
open Microsoft.Xna.Framework.Media

[<Literal>]
let SCREEN_WIDTH: int = 800

[<Literal>]
let SCREEN_HEIGHT: int = 600

[<Literal>]
let PLAYER_SPEED: float32 = 300.f

[<Literal>]
let SPAWN_INTERVAL: float32 = 1.5f

[<Literal>]
let BASE_ITEM_SPEED: float32 = 150.f

[<Literal>]
let POINTS_PER_COLLECT: int = 10

[<Literal>]
let POINTS_PER_DROP: int = -5

[<Literal>]
let INITIAL_LIVES: int = 3

type GameEvents() =
    let mutable _zongziCollected: Event<unit> = Event<unit>()
    let mutable _zongziDropped: Event<unit> = Event<unit>()
    let mutable _playerHit: Event<unit> = Event<unit>()
    let mutable _gameStarted: Event<unit> = Event<unit>()
    let mutable _gameEnded: Event<unit> = Event<unit>()

    [<CLIEvent>]
    member _.ZongziCollected: IEvent<unit> = _zongziCollected.Publish

    [<CLIEvent>]
    member _.ZongziDropped: IEvent<unit> = _zongziDropped.Publish

    [<CLIEvent>]
    member _.PlayerHit: IEvent<unit> = _playerHit.Publish

    [<CLIEvent>]
    member _.GameStarted: IEvent<unit> = _gameStarted.Publish

    [<CLIEvent>]
    member _.GameEnded: IEvent<unit> = _gameEnded.Publish

    member _.TriggerZongziCollected() : unit = _zongziCollected.Trigger()

    member _.TriggerZongziDropped() : unit = _zongziDropped.Trigger()

    member _.TriggerPlayerHit() : unit = _playerHit.Trigger()

    member _.TriggerGameStarted() : unit = _gameStarted.Trigger()

    member _.TriggerGameEnded() : unit = _gameEnded.Trigger()

type SoundManager() =
    let mutable _initialized: bool = false
    let mutable _itemCollectedSound: SoundEffect option = None
    let mutable _dropSound: SoundEffect option = None
    let mutable _playerHitSound: SoundEffect option = None
    let mutable _gameOverSound: SoundEffect option = None
    let mutable _bgm: Song option = None

    member _.Initialized = _initialized

    member _.LoadSounds(content: Microsoft.Xna.Framework.Content.ContentManager) : unit =
        if not _initialized then
            try
                _itemCollectedSound <- Some(content.Load<SoundEffect> "Sounds/item_collected")
            with _ ->
                ()

            try
                _dropSound <- Some(content.Load<SoundEffect> "Sounds/drop_into_water")
            with _ ->
                ()

            try
                _playerHitSound <- Some(content.Load<SoundEffect> "Sounds/player_hit")
            with _ ->
                ()

            try
                _gameOverSound <- Some(content.Load<SoundEffect> "Sounds/game_over")
            with _ ->
                ()

            try
                _bgm <- Some(content.Load<Song> "Sounds/BGM/main_theme")
            with _ ->
                ()

            _initialized <- true

    member _.PlayItemCollected() : unit =
        _itemCollectedSound |> Option.iter (fun s -> s.Play() |> ignore)

    member _.PlayDrop() : unit =
        _dropSound |> Option.iter (fun s -> s.Play() |> ignore)

    member _.PlayPlayerHit() : unit =
        _playerHitSound |> Option.iter (fun s -> s.Play() |> ignore)

    member _.PlayGameOver() : unit =
        _gameOverSound |> Option.iter (fun s -> s.Play() |> ignore)

    member _.PlayBGM() : unit =
        if MediaPlayer.State <> MediaState.Playing then
            _bgm
            |> Option.iter (fun s ->
                MediaPlayer.Play(s)
                MediaPlayer.IsRepeating <- true)

    member _.StopBGM() : unit = MediaPlayer.Stop()

    member _.PauseBGM() : unit = MediaPlayer.Pause()

    member _.ResumeBGM() : unit = MediaPlayer.Resume()

let gameEvents: GameEvents = GameEvents()
let soundManager: SoundManager = SoundManager()
