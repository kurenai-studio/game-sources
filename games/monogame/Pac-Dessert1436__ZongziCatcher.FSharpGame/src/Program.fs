module ZongziCatcher.FSharpGame.Program

open Microsoft.Xna.Framework
open Microsoft.Xna.Framework.Graphics
open Microsoft.Xna.Framework.Input
open Mibo.Elmish
open Mibo.Elmish.Graphics2D
open Mibo.Input
open Essentials

type GameAction =
    | MoveLeft = 0
    | MoveRight = 1
    | Restart = 2
    | Pause = 3

let inputMap: InputMap<GameAction> =
    InputMap.empty
    |> InputMap.key GameAction.MoveLeft Keys.Left
    |> InputMap.key GameAction.MoveLeft Keys.A
    |> InputMap.key GameAction.MoveRight Keys.Right
    |> InputMap.key GameAction.MoveRight Keys.D
    |> InputMap.key GameAction.Restart Keys.Enter
    |> InputMap.key GameAction.Pause Keys.P
    |> InputMap.key GameAction.Pause Keys.Escape

type GameStatus =
    | Title = 0
    | Playing = 1
    | Paused = 2
    | GameOver = 3

type Model =
    { Player: Player
      FallingItems: FallingItem list
      WaterSplashes: WaterSplash list
      Captions: Caption list
      Input: ActionState<GameAction>
      GameStatus: GameStatus
      SpawnTimer: float32 }

type Msg =
    | Tick of GameTime
    | InputChanged of ActionState<GameAction>
    | RestartGame

let createPlayer () : Player =
    let playerPosition: Vector2 =
        Vector2(float32 SCREEN_WIDTH / 2.f - 65.f, float32 SCREEN_HEIGHT - 100.f)

    let player: Player = Player playerPosition
    player.Lives <- INITIAL_LIVES
    player.Score <- 0
    player

let init (ctx: GameContext) : struct (Model * Cmd<Msg>) =
    if not soundManager.Initialized then
        soundManager.LoadSounds ctx.Content

    let model: Model =
        { Player = createPlayer ()
          FallingItems = []
          WaterSplashes = []
          Captions = []
          Input = ActionState.empty
          GameStatus = GameStatus.Title
          SpawnTimer = 0.f }

    model, Cmd.none

let random: System.Random = System.Random.Shared

let spawnItem (score: int) : FallingItem =
    let itemType: ActorType =
        if random.NextDouble() < 0.8 then
            ActorType.Zongzi
        else
            ActorType.Scorpion

    let x: float32 = float32 (random.Next(int (SCREEN_WIDTH - 50)))
    let speedBoost = float32 (score / 50) * 10.f
    let speed: float32 = BASE_ITEM_SPEED + float32 (random.Next(100)) + speedBoost

    FallingItem(Vector2(x, -50.f), speed, itemType)

let checkCollision (player: Player) (item: FallingItem) : bool =
    let playerRect: Rectangle =
        Rectangle(int player.Position.X, int player.Position.Y, int player.SpriteSize.X, int player.SpriteSize.Y)

    let itemRect: Rectangle =
        Rectangle(int item.Position.X, int item.Position.Y, int item.SpriteSize.X, int item.SpriteSize.Y)

    playerRect.Intersects itemRect

let update (msg: Msg) (model: Model) : struct (Model * Cmd<Msg>) =
    match msg with
    | InputChanged(input: ActionState<GameAction>) -> { model with Input = input }, Cmd.none

    | RestartGame -> init Unchecked.defaultof<_>

    | Tick(gt: GameTime) ->
        if model.GameStatus = GameStatus.Title then
            if model.Input.Held.Contains GameAction.Restart then
                soundManager.PlayBGM()
                gameEvents.TriggerGameStarted()

                { model with
                    GameStatus = GameStatus.Playing
                    Player = createPlayer ()
                    FallingItems = []
                    WaterSplashes = []
                    Captions = []
                    SpawnTimer = 0.f },
                Cmd.none
            else
                model, Cmd.none
        elif model.GameStatus = GameStatus.GameOver then
            if model.Input.Held.Contains GameAction.Restart then
                soundManager.PlayBGM()
                gameEvents.TriggerGameStarted()

                { model with
                    GameStatus = GameStatus.Playing
                    Player = createPlayer ()
                    FallingItems = []
                    WaterSplashes = []
                    Captions = []
                    SpawnTimer = 0.f },
                Cmd.none
            else
                model, Cmd.none
        elif model.GameStatus = GameStatus.Paused then
            if model.Input.Started.Contains GameAction.Restart then
                soundManager.ResumeBGM()

                { model with
                    GameStatus = GameStatus.Playing },
                Cmd.none
            else
                model, Cmd.none
        else if model.Input.Started.Contains GameAction.Pause then
            soundManager.PauseBGM()

            { model with
                GameStatus = GameStatus.Paused },
            Cmd.none
        else
            let dt: float32 = float32 gt.ElapsedGameTime.TotalSeconds

            if model.Input.Held.Contains GameAction.MoveLeft then
                model.Player.MoveLeft(PLAYER_SPEED, dt)

            if model.Input.Held.Contains GameAction.MoveRight then
                model.Player.MoveRight(PLAYER_SPEED, dt, SCREEN_WIDTH)

            model.FallingItems |> List.iter (fun item -> item.Update(gt))

            model.WaterSplashes |> List.iter (fun splash -> splash.Update(gt))

            let activeSplashes: WaterSplash list =
                model.WaterSplashes |> List.filter (fun s -> not s.IsDead)

            model.Captions |> List.iter (fun caption -> caption.Update(gt))

            let activeCaptions: Caption list =
                model.Captions |> List.filter (fun c -> not c.IsDead)

            let mutable remainingItems: FallingItem list = []
            let mutable newSplashes: WaterSplash list = activeSplashes
            let mutable newCaptions: Caption list = activeCaptions

            for item in model.FallingItems do
                let captionPos = Vector2(item.Position.X, item.Position.Y - 30.f)

                if item.IsOffScreen SCREEN_HEIGHT then
                    if item.Type = ActorType.Zongzi then
                        model.Player.Score <- model.Player.Score + POINTS_PER_DROP

                        newSplashes <-
                            WaterSplash(Vector2(item.Position.X, float32 SCREEN_HEIGHT - 25.f))
                            :: newSplashes

                        newCaptions <- Caption(sprintf "-%d" (abs POINTS_PER_DROP), captionPos) :: newCaptions
                        soundManager.PlayDrop()
                elif checkCollision model.Player item then
                    if item.Type = ActorType.Zongzi then
                        model.Player.Score <- model.Player.Score + POINTS_PER_COLLECT

                        newCaptions <- Caption(sprintf "+%d" POINTS_PER_COLLECT, captionPos) :: newCaptions

                        soundManager.PlayItemCollected()
                    else
                        model.Player.Lives <- model.Player.Lives - 1

                        newCaptions <-
                            Caption("Ouch!", Vector2(item.Position.X, item.Position.Y - 30.f))
                            :: newCaptions

                        soundManager.PlayPlayerHit()
                else
                    remainingItems <- item :: remainingItems

            let newSpawnTimer: float32 = model.SpawnTimer + dt
            let mutable newItems: FallingItem list = remainingItems

            let spawnInterval: float32 =
                max 0.3f (SPAWN_INTERVAL - float32 (model.Player.Score / 100) * 0.1f)

            if newSpawnTimer >= spawnInterval then
                newItems <- spawnItem model.Player.Score :: newItems

            let finalSpawnTimer: float32 =
                if newSpawnTimer >= spawnInterval then
                    0.f
                else
                    newSpawnTimer

            let gameStatus: GameStatus =
                if model.Player.Lives <= 0 then
                    soundManager.StopBGM()
                    soundManager.PlayGameOver()
                    GameStatus.GameOver
                else
                    GameStatus.Playing

            { model with
                FallingItems = newItems
                WaterSplashes = newSplashes
                Captions = newCaptions
                SpawnTimer = finalSpawnTimer
                GameStatus = gameStatus },
            Cmd.none

let view (ctx: GameContext) (model: Model) (buffer: RenderBuffer<RenderCmd2D>) =
    let (content: Content.ContentManager), (gfx: GraphicsDevice) =
        ctx.Content, ctx.GraphicsDevice

    let loadTexture (name: string) =
        Assets.getOrCreate name (fun _ -> content.Load<Texture2D> name) ctx

    let loadFont (name: string) =
        Assets.getOrCreate name (fun _ -> content.Load<SpriteFont> name) ctx

    let background: Texture2D = loadTexture "Images/background"
    let dragonBoat: Texture2D = loadTexture "Images/dragon_boat"
    let zongzi: Texture2D = loadTexture "Images/zongzi"
    let scorpion: Texture2D = loadTexture "Images/scorpion"
    let waterSplash: Texture2D = loadTexture "Images/water_splash"
    let font: SpriteFont = loadFont "Fonts/GameFont"
    let padding: float32 = 5.f
    let defaultBgColor: Color = Color(0, 0, 0, 200)

    let drawTextWithBgColor
        (batch: SpriteBatch)
        (text: string)
        (position: Vector2)
        (textColor: Color)
        (bgColor: Color)
        : unit =
        let textSize: Vector2 = font.MeasureString text

        let bgRect: Rectangle =
            Rectangle(
                int (position.X - padding),
                int (position.Y - padding),
                int (textSize.X + padding * 2.f),
                int (textSize.Y + padding * 2.f)
            )

        let pixel: Texture2D = new Texture2D(gfx, 1, 1)
        pixel.SetData [| bgColor |]
        batch.Draw(pixel, bgRect, bgColor)
        batch.DrawString(font, text, position, textColor)

    let drawCustom (ctx: GameContext) =
        let batch: SpriteBatch =
            Assets.getOrCreate "spriteBatch" (fun _ -> new SpriteBatch(gfx)) ctx

        batch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend)

        batch.Draw(background, Rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT), Color.White)

        if model.GameStatus = GameStatus.Title then
            drawTextWithBgColor
                batch
                "ZONGZI CATCHER: Dragon Boat Festival"
                (Vector2(float32 SCREEN_WIDTH / 2.f - 200.f, float32 SCREEN_HEIGHT / 2.f - 80.f))
                Color.White
                Color.DarkCyan

            drawTextWithBgColor
                batch
                "Press Enter to begin the game"
                (Vector2(float32 SCREEN_WIDTH / 2.f - 150.f, float32 SCREEN_HEIGHT / 2.f - 30.f))
                Color.Yellow
                defaultBgColor

            drawTextWithBgColor
                batch
                "Use arrow keys or A/D to move"
                (Vector2(float32 SCREEN_WIDTH / 2.f - 160.f, float32 SCREEN_HEIGHT / 2.f + 50.f))
                Color.White
                defaultBgColor

            drawTextWithBgColor
                batch
                "Catch zongzi (+10 pts) | Avoid scorpions (-1 Life)"
                (Vector2(float32 SCREEN_WIDTH / 2.f - 225.f, float32 SCREEN_HEIGHT / 2.f + 90.f))
                Color.White
                defaultBgColor
        else
            for item: FallingItem in model.FallingItems do
                let texture: Texture2D = if item.Type = ActorType.Zongzi then zongzi else scorpion

                batch.Draw(
                    texture,
                    Rectangle(int item.Position.X, int item.Position.Y, int item.SpriteSize.X, int item.SpriteSize.Y),
                    Color.White
                )

            batch.Draw(
                dragonBoat,
                Rectangle(
                    int model.Player.Position.X,
                    int model.Player.Position.Y,
                    int model.Player.SpriteSize.X,
                    int model.Player.SpriteSize.Y
                ),
                Color.White
            )

            for splash: WaterSplash in model.WaterSplashes do
                let alpha: int = int (splash.LifeTime / 0.5f * 255.f)

                batch.Draw(
                    waterSplash,
                    Rectangle(int splash.Position.X - 25, int splash.Position.Y - 25, 50, 50),
                    Color(255, 255, 255, alpha)
                )

            drawTextWithBgColor
                batch
                (sprintf "Score: %d" model.Player.Score)
                (Vector2(10.f, 10.f))
                Color.White
                defaultBgColor

            drawTextWithBgColor
                batch
                (sprintf "Lives: %d" model.Player.Lives)
                (Vector2(float32 SCREEN_WIDTH - 100.f, 10.f))
                Color.White
                defaultBgColor

            for caption: Caption in model.Captions do
                let alpha: int = int (caption.LifeTime * 255.f)

                let textColor: Color =
                    if caption.Text.StartsWith "+" then Color.Green
                    elif caption.Text.StartsWith "-" then Color.Red
                    else Color.Yellow

                batch.DrawString(
                    font,
                    caption.Text,
                    caption.Position,
                    Color(int textColor.R, int textColor.G, int textColor.B, alpha)
                )

            if model.GameStatus = GameStatus.GameOver then
                drawTextWithBgColor
                    batch
                    "GAME OVER!"
                    (Vector2(float32 SCREEN_WIDTH / 2.f - 80.f, float32 SCREEN_HEIGHT / 2.f - 50.f))
                    Color.White
                    Color.DarkRed

                drawTextWithBgColor
                    batch
                    (sprintf "Final Score: %5d" model.Player.Score)
                    (Vector2(float32 SCREEN_WIDTH / 2.f - 100.f, float32 SCREEN_HEIGHT / 2.f))
                    Color.White
                    defaultBgColor

                drawTextWithBgColor
                    batch
                    "Press Enter to restart the game"
                    (Vector2(float32 SCREEN_WIDTH / 2.f - 155.f, float32 SCREEN_HEIGHT / 2.f + 50.f))
                    Color.White
                    defaultBgColor

            if model.GameStatus = GameStatus.Paused then
                drawTextWithBgColor
                    batch
                    "PAUSED"
                    (Vector2(float32 SCREEN_WIDTH / 2.f - 60.f, float32 SCREEN_HEIGHT / 2.f - 30.f))
                    Color.White
                    Color.DarkBlue

                drawTextWithBgColor
                    batch
                    "Press Enter to continue"
                    (Vector2(float32 SCREEN_WIDTH / 2.f - 120.f, float32 SCREEN_HEIGHT / 2.f + 20.f))
                    Color.Yellow
                    defaultBgColor

        batch.End()

    Draw2D.custom drawCustom 0<RenderLayer> buffer

[<EntryPoint>]
let main (_: string[]) : int =
    let program: Program<Model, Msg> =
        Program.mkProgram init update
        |> Program.withAssets
        |> Program.withRenderer (fun (g: Game) -> Batch2DRenderer.create g view)
        |> Program.withInput
        |> Program.withSubscription (fun (ctx: GameContext) _ -> InputMapper.subscribeStatic inputMap InputChanged ctx)
        |> Program.withTick Tick
        |> Program.withConfig (fun (game: Game, graphics: GraphicsDeviceManager) ->
            game.Content.RootDirectory <- "Content"
            game.Window.Title <- "Zongzi Catcher - Dragon Boat Festival"
            game.IsMouseVisible <- true
            graphics.PreferredBackBufferWidth <- SCREEN_WIDTH
            graphics.PreferredBackBufferHeight <- SCREEN_HEIGHT
            game.Window.AllowUserResizing <- false)

    use game: ElmishGame<Model, Msg> = new ElmishGame<Model, Msg>(program)
    game.Run()
    0
