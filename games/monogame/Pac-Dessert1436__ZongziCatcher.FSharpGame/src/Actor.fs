namespace ZongziCatcher.FSharpGame

open Microsoft.Xna.Framework
open Microsoft.Xna.Framework.Graphics

type ActorType =
    | DragonBoat = 0
    | Zongzi = 1
    | Scorpion = 2

type Actor(position: Vector2, speed: float32, actorType: ActorType) =
    let mutable _position: Vector2 = position
    let mutable _speed: float32 = speed
    let _actorType: ActorType = actorType

    member val Id = System.Guid.NewGuid()

    member _.Position
        with get (): Vector2 = _position
        and set (value: Vector2) = _position <- value

    member _.Speed
        with get (): float32 = _speed
        and set (value: float32) = _speed <- value

    member _.Type: ActorType = _actorType

    member _.SpriteSize: Vector2 =
        match _actorType with
        | ActorType.DragonBoat -> Vector2(130f, 80f)
        | _ -> Vector2(50f, 50f)

    member _.Update(gameTime: GameTime) : unit =
        let dt: float32 = float32 gameTime.ElapsedGameTime.TotalSeconds
        _position <- Vector2(_position.X, _position.Y + _speed * dt)

    member this.Draw(spriteBatch: SpriteBatch, texture: Texture2D) : unit =
        spriteBatch.Draw(
            texture,
            Rectangle(int _position.X, int _position.Y, int this.SpriteSize.X, int this.SpriteSize.Y),
            Color.White
        )

type Player(position: Vector2) =
    inherit Actor(position, 0.f, ActorType.DragonBoat)

    let mutable _lives = 3
    let mutable _score = 0

    member _.Score
        with get (): int = _score
        and set (value: int) = _score <- value

    member _.Lives
        with get (): int = _lives
        and set (value: int) = _lives <- value

    member this.MoveLeft(speed: float32, dt: float32) : unit =
        let newX = max 0.f (this.Position.X - speed * dt)
        this.Position <- Vector2(newX, this.Position.Y)

    member this.MoveRight(speed: float32, dt: float32, screenWidth: int) : unit =
        let maxX: float32 = float32 screenWidth - this.SpriteSize.X
        let newX: float32 = min maxX (this.Position.X + speed * dt)
        this.Position <- Vector2(newX, this.Position.Y)

type FallingItem(position: Vector2, speed: float32, itemType: ActorType) =
    inherit Actor(position, speed, itemType)

    member this.IsOffScreen(screenHeight: int) : bool = this.Position.Y > float32 screenHeight

type WaterSplash(position: Vector2) =
    let mutable _position: Vector2 = position
    let mutable _lifeTime: float32 = 0.5f

    member _.Position: Vector2 = _position
    member _.LifeTime: float32 = _lifeTime

    member _.Update(gameTime: GameTime) : unit =
        let dt: float32 = float32 gameTime.ElapsedGameTime.TotalSeconds
        _lifeTime <- _lifeTime - dt

    member _.IsDead: bool = _lifeTime <= 0.f

    member _.Draw(spriteBatch: SpriteBatch, texture: Texture2D) : unit =
        let alpha: int = int (_lifeTime / 0.5f * 255.f)

        spriteBatch.Draw(
            texture,
            Rectangle(int _position.X - 25, int _position.Y - 25, 50, 50),
            Color(255, 255, 255, alpha)
        )

type Caption(text: string, position: Vector2) =
    let mutable _text: string = text
    let mutable _position: Vector2 = position
    let mutable _lifeTime: float32 = 1.0f

    member _.Text: string = _text
    member _.Position: Vector2 = _position
    member _.LifeTime: float32 = _lifeTime

    member _.Update(gameTime: GameTime) : unit =
        let dt: float32 = float32 gameTime.ElapsedGameTime.TotalSeconds
        _lifeTime <- _lifeTime - dt
        _position <- Vector2(_position.X, _position.Y - 20.f * dt)

    member _.IsDead: bool = _lifeTime <= 0.f
