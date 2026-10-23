# CircusPop Workshop
A step-by-step walkthrough building a 2D game with MonoGame, inspired by the classic Circus Atari arcade game. You'll start with a blank project and layer in concepts one at a time: sprites, physics, animation, input, sound, and game state.

You can check out development of this live on [TheDevTalkShow](https://youtube.com/thedevtalkshow) at the Game Development playlist: https://www.youtube.com/playlist?list=PLK7ylelpv531sxiYheCpRql0BahEW_B62

**Credits**
This sample is based on an implementation of Circus Atari called Circus Linux that was hosted at new breed software.  The link to the page is http - www.newbreedsoftware.com/circus-linux.  This is not a clickable link because the site does not support https.  However, you may choose to check it out at your own risk.

Things come full circle as Circus Linux is ported to XNA and then MonoGame and could be available for many platforms today!

Originally I used this sample to teach XNA development for Windows Phone 7!  Long live XNA!

**Prerequisites**
- [.NET SDK](https://dotnet.microsoft.com/download) (8.0 or later)
- [MonoGame templates](https://docs.monogame.net/articles/getting_started/index.html): `dotnet new install MonoGame.Templates.CSharp`
- An IDE (Visual Studio, VS Code with C# Dev Kit, or Rider)

---

## Step 1: Create the Project

```bash
dotnet new mgdesktopgl -n CircusPop
cd CircusPop
dotnet run
```

You should see the classic cornflower blue window. Take a moment to orient yourself in `Game1.cs`:

- `Initialize()` — runs once before the game loop starts
- `LoadContent()` — load textures, sounds, fonts from the `Content/` pipeline
- `Update(GameTime)` — called ~60 times/second; game logic lives here
- `Draw(GameTime)` — called each frame after Update; render everything here

**Concepts:** The game loop, `GameTime`, separation of update vs. draw.

---

## Step 2: Get the Clown on Screen

Add `clown.png` to your `Content/` folder and register it in `Content.mgcb` using the MonoGame Content Builder (MGCB Editor).

Add the clown fields at the top of the class, then fill in `LoadContent` and `Draw`:

```csharp
public class Game1 : Game
{
    private GraphicsDeviceManager _graphics;
    private SpriteBatch _spriteBatch;

    private Texture2D clownTexture;
    private Vector2 clownPosition = new Vector2(100f, 120f);

    public Game1()
    {
        _graphics = new GraphicsDeviceManager(this);
        Content.RootDirectory = "Content";
        IsMouseVisible = true;

        _graphics.PreferredBackBufferWidth = 800;
        _graphics.PreferredBackBufferHeight = 600;
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);
        clownTexture = Content.Load<Texture2D>("clown");
    }

    protected override void Update(GameTime gameTime)
    {
        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.CornflowerBlue);
        _spriteBatch.Begin();
        _spriteBatch.Draw(clownTexture, clownPosition, Color.White);
        _spriteBatch.End();
        base.Draw(gameTime);
    }
}
```

Run it — you should see the clown sitting motionless on screen.

**Concepts:** `SpriteBatch`, `Texture2D`, the Content Pipeline.

---

## Step 3: Apply Gravity

Add a velocity field we can use to track the clown's velocity.

```csharp
private Texture2D clownTexture;
private Vector2 clownPosition = new Vector2(100f, 120f);
private Vector2 clownVelocity = Vector2.Zero;  // new
```

Now in the **`Update`** method, update the clown's position each frame. Then accumulate downward velocity to simulate gravity:

```csharp
protected override void Update(GameTime gameTime)
{
    // Move clown by velocity (scaled by time so it's frame-rate independent)
    clownPosition += clownVelocity * (float)gameTime.ElapsedGameTime.TotalSeconds;

    // Simulate gravity (accumulates velocity downward each frame)
    clownVelocity.Y += 16f;

    base.Update(gameTime);
}
```

Run it — the clown falls off the bottom of the screen. That's expected.

**Concepts:** Frame-rate independent movement (`delta time`), acceleration vs. velocity vs. position.

---

## Step 4: Introduce the Sprite Class

Notice we now have three separate variables all describing the same object: `clownTexture`, `clownPosition`, `clownVelocity`. Every new game object will need the same set. Create `Sprite.cs` to group them:

```csharp
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

public class Sprite
{
    public Texture2D Texture { get; set; }
    public Vector2 Position;
    public Vector2 Velocity;

    public int Width => Texture.Width;
    public int Height => Texture.Height;

    public Sprite(Vector2 initialPosition, Vector2 initialVelocity)
    {
        Position = initialPosition;
        Velocity = initialVelocity;
    }
}
```

Replace the three loose variables in `Game1.cs`:

```csharp
private Sprite clown;

// in Initialize():
clown = new Sprite(new Vector2(100f, 120f), Vector2.Zero);

// in LoadContent():
clown.Texture = Content.Load<Texture2D>("clown");

// in Update():
clown.Position += clown.Velocity * (float)gameTime.ElapsedGameTime.TotalSeconds;
clown.Velocity.Y += 16f;

// in Draw():
_spriteBatch.Draw(clown.Texture, clown.Position, Color.White);
```

Same behavior — clown still falls off screen — but the code is cleaner and ready to scale.

**Concepts:** Encapsulation, motivation for grouping related state.

---

## Step 5: Bounce Off the Floor

Add `maxX` and `maxY` fields to store the screen boundaries. We calculate them in `LoadContent` because we need the texture dimensions first — and since the window doesn't resize, we only need to do this once:

```csharp
private int maxX;
private int maxY;

// in LoadContent(), after loading the texture:
maxX = GraphicsDevice.Viewport.Width - clown.Width;
maxY = GraphicsDevice.Viewport.Height - clown.Height;
```

Then in `Update`, check if the clown has hit the floor and reverse the Y velocity:

```csharp
// Check if clown has gone below the screen limits
if (clown.Position.Y > maxY)
{
    clown.Velocity.Y *= -1;  // reverse velocity to bounce back up
    clown.Position.Y = maxY; // clamp so it doesn't escape
}
```

The clown now falls and bounces off the floor indefinitely.

**Concepts:** Velocity reversal, clamping positions, the basics of collision response.

---

## Step 6 (Optional): Velocity Display — GameComponents and GameServices

> Skip this step if you're short on time. It doesn't add gameplay but is a great illustration of how velocity vectors work visually, and a showcase of MonoGame's built-in component architecture.

We want to draw an arrow showing the clown's current velocity vector without cluttering `Game1`. We'll use MonoGame's `DrawableGameComponent` and `GameServices`.

**Create `IMovingObject.cs`** — a new file in your project:

```csharp
using Microsoft.Xna.Framework;

namespace CircusPop;

public interface IMovingObject
{
    Vector2 Position { get; }
    Vector2 Velocity { get; }
}
```

**Make `Sprite` implement it** — using explicit interface implementation so `Position` and `Velocity` as fields on `Sprite` stay unchanged internally:

```csharp
public class Sprite : IMovingObject
{
    // ... existing fields ...

    Vector2 IMovingObject.Position => Position;
    Vector2 IMovingObject.Velocity => Velocity;
}
```

**`VelocityDisplay` depends on `PrimitiveBatch`** — a helper class for drawing raw lines directly to the GPU without a texture. It's not something we'll walk through, but copy `PrimitiveBatch.cs` from the repo into your project:

> 📄 [`PrimitiveBatch.cs`](https://raw.githubusercontent.com/SpaceShot/circuspop/104697d766f882e2bb56a13210bbe3d863c780c4/src/PrimitiveBatch.cs)

Note that it lives in the `Microsoft.Xna.Community` namespace — a nod to its origins as a MonoGame community sample.

**Create `VelocityDisplay.cs`** — copy it from the repo into your project:

> 📄 [`VelocityDisplay.cs`](https://raw.githubusercontent.com/SpaceShot/circuspop/104697d766f882e2bb56a13210bbe3d863c780c4/src/VelocityDisplay.cs)

It's a `DrawableGameComponent` that draws an arrow from the clown's position in the direction of its velocity. It retrieves the clown via the game's service locator — no direct reference needed.

**Register the service and component** in `Initialize()`:

```csharp
this.Services.AddService(typeof(IMovingObject), clown);
this.Components.Add(new VelocityDisplay(this));
```

Run it — you'll see an arrow rendered alongside the clown. The arrow grows longer as the clown gains speed (falling under gravity) and shrinks as it slows (rising after a bounce). It's a live visualization of the velocity vector you've been working with.

**Concepts:** `DrawableGameComponent`, `GameServices` as a service locator, `IMovingObject` as a seam between systems. Also: `PrimitiveBatch` for drawing raw lines without textures.

---

## Step 7: Clown Animation with a Sprite Sheet

So far the clown is a static image. Let's make it animated using a sprite sheet — a single image containing multiple animation frames laid out in a grid.

Add `clownSpriteSheet.png` to `Content/` and create `Animation.cs`:

```csharp
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;

namespace CircusPop;

public class Animation
{
    private double _timePerFrame;
    private Texture2D _spriteSheet;
    private int _currentFrame;
    private double _timeElapsed;
    private List<Rectangle> _frames;

    public Rectangle CurrentFrame
    {
        get
        {
            return _frames[_currentFrame];
        }
    }

    public Animation(Texture2D spriteSheet, double timePerFrame, int frameWidth, int frameHeight)
    {
        _spriteSheet = spriteSheet;
        _timePerFrame = timePerFrame;
        _timeElapsed = 0;

        if ((_spriteSheet.Width % frameWidth != 0) || (_spriteSheet.Height % frameHeight != 0))
        {
            throw new FormatException("The width and height of the sprite sheet does not create an exact number of frames");
        }

        _frames = new List<Rectangle>();

        for (int i = 0; i < _spriteSheet.Height; i += frameHeight)
        {
            for (int j = 0; j < _spriteSheet.Width; j += frameWidth)
            {
                _frames.Add(new Rectangle(j, i, frameWidth, frameHeight));
            }
        }
    }

    public void Update(GameTime gameTime)
    {
        _timeElapsed += gameTime.ElapsedGameTime.TotalMilliseconds;

        if (_timeElapsed >= _timePerFrame)
        {
            _currentFrame++;
            if (_currentFrame >= _frames.Count)
            {
                _currentFrame = 0;
            }

            _timeElapsed -= _timePerFrame;
        }
    }
}
```

Load and update it — each method gets specific additions:

**Fields** (top of the class):
```csharp
private Texture2D clownSpriteSheet;
private Animation clownAnimation;
```

**`LoadContent()`** — after loading the clown texture:
```csharp
clownSpriteSheet = Content.Load<Texture2D>("clownSpriteSheet");
clownAnimation = new Animation(clownSpriteSheet, 200, 58, 64);
```

**`Update()`** — add just before the gravity line so the frame advances before velocity changes:
```csharp
// Let the clown animation advance frames if necessary
clownAnimation.Update(gameTime);

// Simulate gravity (accumulates velocity downward each frame)
clown.Velocity.Y += 16f;
```

**`Draw()`** — replace the static clown draw with the animated version:
```csharp
_spriteBatch.Draw(clownSpriteSheet, clown.Position, clownAnimation.CurrentFrame, Color.White);
```

**Concepts:** Sprite sheets, source rectangles in `SpriteBatch.Draw`, building a reusable animation system.

---

## Step 8: Add the Trampoline and Physics Bounce

Add `Trampoline.png` to content. The trampoline sits at the bottom of the screen and is controlled by the player.

**Fields** (top of the class):
```csharp
private Texture2D trampolineTexture;
private Vector2 trampolinePosition;
```

**`LoadContent()`** — load the texture and set its starting position at the bottom of the screen in one go:
```csharp
trampolineTexture = Content.Load<Texture2D>("trampoline");
trampolinePosition = new Vector2(100f, GraphicsDevice.Viewport.Height - trampolineTexture.Height);
```

**`Draw()`** — add after the clown draw:
```csharp
_spriteBatch.Draw(trampolineTexture, trampolinePosition, Color.White);
```

Run it — you should see the trampoline sitting at the bottom of the screen. The clown will fall straight through it for now. That's fine.

**Move the trampoline with keyboard input** — add to `Update()`, right after the exit check that the template gave us:

```csharp
// This is the default exit check in the template. Keep it.
if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
    Exit();

// add trampoline keyboard input here:
KeyboardState keyboardState = Keyboard.GetState();
if (keyboardState.IsKeyDown(Keys.Left))  trampolinePosition.X -= 10f;
if (keyboardState.IsKeyDown(Keys.Right)) trampolinePosition.X += 10f;

// For Gamepad support:
GamePadState padState = GamePad.GetState(PlayerIndex.One);
trampolinePosition.X += padState.ThumbSticks.Left.X * 15f;

// Clamp to screen:
trampolinePosition.X = MathHelper.Clamp(trampolinePosition.X, 0,
    GraphicsDevice.Viewport.Width - trampolineTexture.Width);
```

Run it — you can now move the trampoline left and right with the arrow keys or a gamepad. The clown still falls through it.

**Concepts:** `KeyboardState`, `GamePadState`, clamping input to screen bounds.

---

## Step 9: Trampoline Collision and Bounce Physics

Now make the trampoline actually do something. We'll build rectangles around both the clown and the trampoline each frame and check if they intersect. When they do, we calculate a bounce angle based on where the clown hits the trampoline — hitting the center sends the clown straight up, hitting the edges sends it at an angle.

Add `bounce.wav` to your `Content/` folder and register it in the MGCB Editor with the asset name `bounce`. Then add `using Microsoft.Xna.Framework.Audio;` to the top of `Game1.cs` and add the field and load the asset:

**Fields** (top of the class):
```csharp
private SoundEffect bounce;
```

**`LoadContent()`**:
```csharp
bounce = Content.Load<SoundEffect>("bounce");
```

**`Update()`** — add after the floor/wall bounce checks, before the animation update and gravity line:

```csharp
Rectangle trampolineRect = new Rectangle((int)trampolinePosition.X, (int)trampolinePosition.Y,
    trampolineTexture.Width, trampolineTexture.Height);
Rectangle clownRect = new Rectangle((int)clown.Position.X, (int)clown.Position.Y,
    clown.Width, clown.Height);

if (trampolineRect.Intersects(clownRect))
{
    // The offset from center determines the bounce angle (90° = straight up)
    int angle = trampolineRect.Center.X - clownRect.Center.X + 90;

    clown.Velocity.X = 980f * (float)Math.Cos(MathHelper.ToRadians(angle));
    clown.Velocity.Y = 980f * (float)Math.Sin(MathHelper.ToRadians(angle)) * -1; // upward

    clown.Position.Y = trampolinePosition.Y - clown.Height; // prevent overlap

    bounce.Play();
}
```

Now add left and right wall bouncing. Place this in `Update()` **after** the check for hitting the bottom (the `clown.Position.Y > maxY` block), and **before** the trampoline collision:

```csharp
if (clown.Position.X > maxX)
{
    // We've hit the right side, reverse to create a bounce
    clown.Velocity.X *= -1;
    clown.Position.X = maxX;
}
else if (clown.Position.X < 0)
{
    // We've hit the left side, reverse to create a bounce
    clown.Velocity.X *= -1;
    clown.Position.X = 0;
}
```

> Run it now — the clown bounces around the entire screen and you chase it with the trampoline. You've made a toy that plays itself!

At this point the game plays itself — the clown bounces around and you chase it with the trampoline.

> **For now:** replace the floor bounce (Step 5) with the same soft 90° bounce so the demo keeps going. The clown never dies yet. We'll fix that at the end.

**Concepts:** Rectangle intersection, angle-based velocity from trig, `MathHelper`, input from keyboard and gamepad simultaneously.

---

## Step 10: Add Balloons

Create a new file `Balloon.cs` in your project with the following complete contents:

```csharp
using Microsoft.Xna.Framework;

namespace CircusPop;

public class Balloon
{
    public Vector2 Position;
    public int Color { get; set; } // row index, determines color from sprite sheet

    public Rectangle BoundingBox =>
        new Rectangle((int)(Position.X + 6f), (int)(Position.Y + 1f), 19, 20);

    // static because all balloons share one animation state
    private static int timeTillSwitch = 350;
    public static int State = 0;

    public static void UpdateAnimation(GameTime gameTime)
    {
        timeTillSwitch -= gameTime.ElapsedGameTime.Milliseconds;
        if (timeTillSwitch <= 0)
        {
            State = 1 - State; // toggle between 0 and 1
            timeTillSwitch = 350;
        }
    }
}
```

**Animate the balloons** — notice this is a different, simpler approach than the `Animation` class: a shared static state toggle driven by a countdown timer. All balloons advance frames in lockstep. It's a good contrast to discuss — when is a shared static approach appropriate vs. per-instance state?

Now wire it up in `Game1.cs`. Add the fields, load the texture, set up the grid, call the animation update, and draw:

**Fields:**
```csharp
private Texture2D balloonTexture;
private List<Balloon> balloons = new List<Balloon>();
```

**`LoadContent()`:**
```csharp
balloonTexture = Content.Load<Texture2D>("balloon");
SetupBalloons();
```

**`SetupBalloons()`** — add this helper method to `Game1`:
```csharp
private void SetupBalloons()
{
    balloons.Clear();

    int rows = 3;
    int columns = 21;
    int columnSpacing = 36;
    int rowSpacing = 40;
    int leftMargin = 20;

    for (int i = 0; i < rows; i++)
    {
        for (int j = 0; j < columns; j++)
        {
            balloons.Add(new Balloon { Color = i, Position = new Vector2((j * columnSpacing) + leftMargin, i * rowSpacing) });
        }
    }
}
```

**`Update()`** — add after the trampoline collision block:
```csharp
// update the balloons' animation state
// (they all share the same state, so this is a static method)
Balloon.UpdateAnimation(gameTime);
```

**`Draw()`** — draw each balloon using a source rectangle from the sprite sheet (each row is a color, each column is an animation frame):
```csharp
foreach (Balloon b in balloons)
{
    _spriteBatch.Draw(balloonTexture,
        b.Position,
        new Rectangle(Balloon.State * 32, b.Color * 32, 32, 32),
        Color.White);
}
```

> Run it — you should see three rows of animated balloons across the top of the screen.

**Concepts:** Sprite sheets with color rows, bounding box tricks, static shared state for synchronized animation.

---

## Step 11: Balloon Collision and Sound Effects

Add `pop.wav` to your `Content/` folder and register it in the MGCB Editor with the asset name `pop`.

**Fields** (top of `Game1`):
```csharp
private SoundEffect pop;
private int score = 0;
```

**`LoadContent()`:**
```csharp
pop = Content.Load<SoundEffect>("pop");
```

**`Update()`** — add after the `Balloon.UpdateAnimation` call. When the clown rectangle intersects a balloon's bounding box, pop it, deflect the clown, and add to the score:

```csharp
for (int i = 0; i < balloons.Count; i++)
{
    if (clownRectangle.Intersects(balloons[i].BoundingBox))
    {
        score += balloons[i].Color * 10 + 10; // higher rows worth more
        balloons.RemoveAt(i);
        clown.Velocity.X *= -1;
        clown.Velocity.Y *= -1;
        clown.Velocity.X += new Random().Next(-15, 15); // slight random deflection
        pop.Play();
        break; // only one balloon per frame (avoids index issues after RemoveAt)
    }
}
```

> Note: we're reusing the `clownRectangle` already built for the trampoline collision check earlier in `Update()`.

**Concepts:** `SoundEffect` vs. `Song`, `List.RemoveAt` gotcha (index shifts after removal), `break` to handle one collision per frame.

---

## Step 12: Scoring and the Scoreboard

Add a `SpriteFont` to your project using the MGCB Editor: right-click your Content folder, choose **Add → New Item**, select **SpriteFont Description**, and name it `font`. This generates a `.spritefont` XML file where you can configure the font family and size. The content pipeline compiles it into a bitmap font at build time.

**Fields** (top of `Game1`):
```csharp
private SpriteFont font;
```

> `score` is already declared from Step 11.

**`LoadContent()`:**
```csharp
font = Content.Load<SpriteFont>("font");
```

**`Draw()`** — add after drawing the clown and balloons:
```csharp
_spriteBatch.DrawString(font, "Score: " + score, new Vector2(550f, 180f), Color.DarkBlue);
```

The score increment is already wired up in the balloon collision loop from Step 11 (`balloons[i].Color * 10 + 10`). Rows further from the player are worth more — a small incentive to aim high.

**Concepts:** `SpriteFont`, `.spritefont` XML descriptor, drawing UI elements over the game world.

---

## Step 13: Animated Background

Add `background.png` to your `Content/` folder and register it in the MGCB Editor with the asset name `background`. The background sprite sheet contains two 640×480 frames side by side — the `Animation` class you built in Step 7 handles the rest.

**Fields** (top of `Game1`):
```csharp
private Texture2D backgroundTexture;
private Animation backgroundAnimation;
private Rectangle displaySize;
```

**`LoadContent()`:**
```csharp
backgroundTexture = Content.Load<Texture2D>("background");
backgroundAnimation = new Animation(backgroundTexture, 500, 640, 480);
displaySize = new Rectangle(0, 0, GraphicsDevice.Viewport.Width, GraphicsDevice.Viewport.Height);
```

The `Animation` constructor takes the texture, frame duration in milliseconds, and frame width and height. Each 640×480 frame exactly fills the viewport.

**`Update()`:**
```csharp
backgroundAnimation.Update(gameTime);
```

**`Draw()`** — this must be the **first** draw call inside `_spriteBatch.Begin()`/`End()`, before the clown, trampoline, and balloons, so it appears behind everything:
```csharp
_spriteBatch.Draw(backgroundTexture, displaySize, backgroundAnimation.CurrentFrame, Color.White);
```

Notice `Animation` is now used for two completely different things — the clown sprite sheet and the background — demonstrating its value as a reusable abstraction.

**Concepts:** Draw order matters, reusing the `Animation` class, stretching a texture to fill the viewport.

---

## Step 14: Game Over

Replace the soft floor bounce with a real game-over state:

```csharp
private bool isGameOver = false;

// In the floor collision check (previously the soft bounce):
if (clown.Position.Y > maxY)
{
    isGameOver = true;
    MediaPlayer.Stop();
}

// At the top of Update, after the start check:
if (isGameOver)
{
    if (keyboardState.IsKeyDown(Keys.Space) && previousKeyboardState.IsKeyUp(Keys.Space))
    {
        // Reset everything
        isGameOver = false;
        isGameStarted = false;
        score = 0;
        clown.Position = new Vector2(100f, 120f);
        clown.Velocity = Vector2.Zero;
        SetupBalloons();
    }
    base.Update(gameTime);
    previousKeyboardState = keyboardState;
    return;
}

// In Draw:
if (isGameOver)
{
    _spriteBatch.DrawString(font, "GAME OVER", new Vector2(280f, 220f), Color.Red);
    _spriteBatch.DrawString(font, "Score: " + score, new Vector2(310f, 260f), Color.White);
    _spriteBatch.DrawString(font, "Press <Space> to Play Again", new Vector2(150f, 300f), Color.White);
}
```

**Concepts:** Multiple game states (not started / playing / game over), state machine thinking, resetting world state cleanly.

---

## Assets Reference

| File | Type | Notes |
|---|---|---|
| `clown.png` | Texture | Static clown image (Steps 2–6) |
| `clownSpriteSheet.png` | Texture | Animated clown (58×64 per frame) |
| `Trampoline.png` | Texture | Trampoline image |
| `balloon.png` | Texture | 2×3 sprite sheet: 2 frames × 3 colors |
| `Background.png` | Texture | Multi-frame background sprite sheet (640×480 per frame) |
| `pop.wav` | Sound Effect | Balloon pop |
| `bounce.wav` | Sound Effect | Trampoline bounce |
| `Caliope.mp3` | Song | Background music |
| `font.spritefont` | Font | Used for score and messages |

---

## Concepts Introduced (in order)

1. MonoGame project structure and the game loop
2. `SpriteBatch`, `Texture2D`, the Content Pipeline
3. Delta-time movement, acceleration, gravity simulation
4. Encapsulation with a `Sprite` class
5. Velocity reversal for wall/floor bouncing
6. `IMovingObject`, `GameServices`, `DrawableGameComponent` *(detour)*
7. Sprite sheet animation with a reusable `Animation` class
8. Rectangle collision detection, angle-based bounce physics
9. Keyboard and gamepad input, edge-triggered key detection
10. Grid layout, shared static animation state (contrast with `Animation` class)
11. `SoundEffect`, list mutation during iteration
12. `SpriteFont`, UI overlay
13. Multi-frame animated backgrounds
14. Multi-state game flow (start → playing → game over → restart)
