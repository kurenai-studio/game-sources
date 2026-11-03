# MonoGame for VB.NET Developers: A Beginner's Guide

Welcome to MonoGame! If you're coming from `vbPixelGameEngine`, this guide will help you understand how to translate your existing knowledge to MonoGame.

---

## Table of Contents
1. [Key Differences & Similarities](#1-key-differences--similarities)
2. [Project Structure](#2-project-structure)
3. [Drawing Primitives](#3-drawing-primitives)
4. [Working with Sprites](#4-working-with-sprites)
5. [Vector Math](#5-vector-math)
6. [RenderTarget2D Explained](#6-rendertarget2d-explained)
7. [Game Loop](#7-game-loop)
8. [Input Handling](#8-input-handling)
9. [Content Management](#9-content-management)
10. [Tips & Best Practices](#10-tips--best-practices)

---

## 1. Key Differences & Similarities

| Feature | vbPixelGameEngine | MonoGame |
|---------|-------------------|----------|
| **Drawing** | `DrawRect`, `DrawString`, `DrawSprite` | `SpriteBatch.Draw` with overloads |
| **Vectors** | `Vi2d` (Integer), `Vf2d` (Float) | `Point` (Integer), `Vector2` (Float) |
| **Game Loop** | `OnUserUpdate()` | `Update(GameTime)`, `Draw(GameTime)` |
| **Graphics** | Immediate mode | Retained mode via `SpriteBatch` |
| **Render Targets** | Not supported | `RenderTarget2D` |

---

## 2. Project Structure

A typical MonoGame project utilizing VB.NET has these key components in its core layer:

```
YourGame.Core/
├── YourGame.Core.vbproj  # VB.NET project file
├── Content/              # All assets (images, sounds, fonts)
│   ├── Content.mgcb      # Content pipeline config
│   ├── Images/           # Texture assets
│   ├── Fonts/            # SpriteFont assets
│   └── Sounds/           # Audio assets
└── GameMain.vb           # Main game class
```

**Main Game Class:**
```vb
Imports Microsoft.Xna.Framework
Imports Microsoft.Xna.Framework.Graphics
Imports Microsoft.Xna.Framework.Input

Public Class GameMain
    Inherits Game
    
    Private _graphics As GraphicsDeviceManager
    Private _spriteBatch As SpriteBatch
    
    Public Sub New()
        _graphics = New GraphicsDeviceManager(Me)
        Content.RootDirectory = "Content"
        IsMouseVisible = True
    End Sub
    
    Protected Overrides Sub LoadContent()
        _spriteBatch = New SpriteBatch(GraphicsDevice)
        ' Load your assets here
    End Sub
    
    Protected Overrides Sub Update(gameTime As GameTime)
        ' Game logic here
        MyBase.Update(gameTime)
    End Sub
    
    Protected Overrides Sub Draw(gameTime As GameTime)
        GraphicsDevice.Clear(Color.CornflowerBlue)
        
        _spriteBatch.Begin()
        ' Drawing code here
        _spriteBatch.End()
        
        MyBase.Draw(gameTime)
    End Sub
End Class
```

---

## 3. Drawing Primitives

### Drawing Rectangles

**vbPixelGameEngine:**
```vb
DrawRect(New Vi2d(10, 10), New Vi2d(100, 50), Presets.Red)
```

**⭐ MonoGame:**
```vb
' Create a 1x1 white texture for drawing rectangles
Dim pixelTexture As New Texture2D(GraphicsDevice, 1, 1)
pixelTexture.SetData({Color.White})

' Draw a filled rectangle
_spriteBatch.Draw(pixelTexture, 
                  New Rectangle(10, 10, 100, 50), 
                  Color.Red)
```

### Drawing Lines

**vbPixelGameEngine:**
```vb
DrawLine(New Vi2d(10, 10), New Vi2d(100, 100), Presets.Blue)
```

**⭐ MonoGame:**
```vb
' Use the pixel texture and draw multiple horizontal/vertical lines
' or create a line drawing helper function
```

### Drawing Text

**vbPixelGameEngine:**
```vb
DrawString("Hello World!", New Vi2d(10, 10), Presets.White)
```

**⭐ MonoGame:**
```vb
' First, add a SpriteFont to your Content project
Dim font = Content.Load(Of SpriteFont)("Fonts/MyFont")

_spriteBatch.DrawString(font, "Hello World!", New Vector2(10, 10), Color.White)
```

---

## 4. Working with Sprites

### Loading and Drawing Sprites

**vbPixelGameEngine:**
```vb
DrawSprite(New Vi2d(100, 100), New Sprite("player.png"))
```

**⭐ MonoGame:**
```vb
' Add your image to Content project (set "Copy to Output" to Copy if newer)
Dim playerTexture = Content.Load(Of Texture2D)("Images/player")

' Draw the sprite
_spriteBatch.Draw(playerTexture, New Vector2(100, 100), Color.White)
```

### Sprite Transformations

**vbPixelGameEngine:**
```vb
DrawSprite(New Vi2d(100, 100), sprite, Presets.White, scale:=2)
```

**⭐ MonoGame:**
```vb
_spriteBatch.Draw(playerTexture,
    New Vector2(100, 100),
    Nothing,                    ' Source rectangle (Nothing = entire texture)
    Color.White,                ' Tint color
    MathHelper.ToRadians(45),   ' Rotation (in radians)
    New Vector2(0, 0),          ' Origin (center of rotation)
    New Vector2(0.5F, 1.5F),    ' Scale
    SpriteEffects.None,         ' Flip effects
    0                           ' Layer depth
)
```

### Sprite Sheets

**vbPixelGameEngine:**
```vb
DrawPartialSprite(
    pos:=New Vi2d(100, 100), 
    sprite:=New Sprite("sheet.png"), 
    sourcepos:=New Vi2d(0, 0), 
    size:=New Vi2d(32, 32)
)
```

**⭐ MonoGame:**
```vb
Dim spriteSheet = Content.Load(Of Texture2D)("Images/sheet")
Dim sourceRect = New Rectangle(0, 0, 32, 32) ' X, Y, Width, Height

_spriteBatch.Draw(spriteSheet, New Vector2(100, 100), sourceRect, Color.White)
```

---

## 5. Vector Math

### `Vector2` Structure

**vbPixelGameEngine:**
```vb
Dim pos As New Vi2d(100, 200)
Dim vel As New Vf2d(2.5F, 1.0F)
```

**⭐ MonoGame:**
```vb
Dim pos As New Vector2(100, 200)   ' Use Vector2 instead of Point
Dim vel As New Vector2(2.5F, 1.0F)
```
> **Note**: In MonoGame, `Point` is used for integer coordinates only, while `Vector2` is used for general-purpose vector math. These two structures are not compatible with each other.

### Common Operations

```vb
' Addition
Dim newPos = pos + vel
' Subtraction
Dim diff = pos - vel
' Scalar multiplication
Dim scaled = vel * 2.0F
' Length/Magnitude
Dim length = vel.Length()
' Normalization
Dim normalized = Vector2.Normalize(vel)
' Dot product
Dim dot = Vector2.Dot(vel1, vel2)
' Distance between two points
Dim distance = Vector2.Distance(pos1, pos2)
```

---

## 6. `RenderTarget2D` Explained

### What is `RenderTarget2D`?

A `RenderTarget2D` allows you to draw to an off-screen buffer instead of directly to the screen. This is useful for:
- Creating complex visual effects
- Implementing split-screen
- Pre-rendering static scenes
- Creating mini-maps

### Basic Usage

```vb
Private _renderTarget As RenderTarget2D
Private _screenTexture As Texture2D
Private _spriteBatch As SpriteBatch

Private ReadOnly Property BackBufferWidth As Integer
    Get
        Return GraphicsDevice.PresentationParameters.BackBufferWidth
    End Get
End Property

Private ReadOnly Property BackBufferHeight As Integer
    Get
        Return GraphicsDevice.PresentationParameters.BackBufferHeight
    End Get
End Property

Protected Overrides Sub LoadContent()
    _spriteBatch = New SpriteBatch(GraphicsDevice)
    
    ' Create a render target with the same size as the screen
    _renderTarget = New RenderTarget2D(GraphicsDevice, BackBufferWidth, BackBufferHeight)
End Sub

Protected Overrides Sub Draw(gameTime As GameTime)
    ' Step 1: Set render target (draw to off-screen buffer)
    GraphicsDevice.SetRenderTarget(_renderTarget)
    GraphicsDevice.Clear(Color.Black)
    
    _spriteBatch.Begin()
    ' Draw your scene here (this goes to the render target)
    _spriteBatch.Draw(playerTexture, New Vector2(100, 100), Color.White)
    _spriteBatch.End()
    
    ' Step 2: Reset to default render target (draw to screen)
    GraphicsDevice.SetRenderTarget(Nothing)
    GraphicsDevice.Clear(Color.CornflowerBlue)
    
    ' Step 3: Draw the render target to the screen
    _spriteBatch.Begin()
    
    ' Draw with effect (e.g., scale, tint, or apply shader)
    _spriteBatch.Draw(_renderTarget, 
                      New Rectangle(0, 0, BackBufferWidth, BackBufferHeight),
                      Color.White * 0.5F) ' 50% opacity
    
    _spriteBatch.End()
    
    MyBase.Draw(gameTime)
End Sub
```

### Example: Screen Shake Effect

```vb
Private _shakeOffset As Vector2 = Vector2.Zero

Protected Overrides Sub Draw(gameTime As GameTime)
    ' Draw to render target
    GraphicsDevice.SetRenderTarget(_renderTarget)
    GraphicsDevice.Clear(Color.Black)
    
    _spriteBatch.Begin()
    ' Draw game content
    _spriteBatch.End()
    
    ' Draw render target to screen with offset
    GraphicsDevice.SetRenderTarget(Nothing)
    GraphicsDevice.Clear(Color.CornflowerBlue)
    
    _spriteBatch.Begin()
    _spriteBatch.Draw(_renderTarget, _shakeOffset, Color.White)
    _spriteBatch.End()
    
    ' Reset shake
    _shakeOffset = Vector2.Zero
End Sub

' Call this when you want to shake the screen
Private Sub ScreenShake(intensity As Single)
    _shakeOffset = New Vector2(
        CSng((Random.NextDouble() - 0.5) * intensity),
        CSng((Random.NextDouble() - 0.5) * intensity)
    )
End Sub
```

---

## 7. Game Loop

### Update Method

The `Update` method is where you handle game logic:
- Player input
- Physics
- Collision detection
- Game state management

```vb
Protected Overrides Sub Update(gameTime As GameTime)
    Dim keyboardState = Keyboard.GetState()
    
    ' Handle input
    If keyboardState.IsKeyDown(Keys.Left) Then
        playerPosition.X -= playerSpeed * CSng(gameTime.ElapsedGameTime.TotalSeconds)
    End If
    
    ' Update game objects
    enemy.Update(gameTime)
    
    ' Check collisions
    CheckCollisions()
    
    MyBase.Update(gameTime)
End Sub
```

### Draw Method

The `Draw` method is where you render everything:

```vb
Protected Overrides Sub Draw(gameTime As GameTime)
    GraphicsDevice.Clear(Color.Black)
    
    _spriteBatch.Begin()
    
    ' Draw background
    _spriteBatch.Draw(backgroundTexture, Vector2.Zero, Color.White)
    
    ' Draw game objects
    _spriteBatch.Draw(playerTexture, playerPosition, Color.White)
    _spriteBatch.Draw(enemyTexture, enemyPosition, Color.White)
    
    ' Draw UI
    _spriteBatch.DrawString(font, $"Score: {score}", New Vector2(10, 10), Color.White)
    
    _spriteBatch.End()
    
    MyBase.Draw(gameTime)
End Sub
```

---

## 8. Input Handling

### Keyboard Input

`vbPixelGameEngine` uses the `GetKey` method to handle keyboard input. _**In MonoGame, you can use `Keyboard.GetState()` to get the current state of the keyboard.**_

```vb
Dim keyboardState = Keyboard.GetState()

' Check single key press
If keyboardState.IsKeyDown(Keys.Space) Then Jump()

' Check key release (requires previous state tracking)
Private _previousKeyboardState As KeyboardState

Protected Overrides Sub Update(gameTime As GameTime)
    Dim keyboardState = Keyboard.GetState()
    
    ' Detect key press (only on first frame)
    If keyboardState.IsKeyDown(Keys.Enter) AndAlso 
        Not _previousKeyboardState.IsKeyDown(Keys.Enter) Then
        ConfirmSelection()
    End If
    
    _previousKeyboardState = keyboardState
    MyBase.Update(gameTime)
End Sub
```

### Mouse Input

`vbPixelGameEngine` uses the `GetMouse` method to handle mouse input. _**In MonoGame, you can use `Mouse.GetState()` to get the current state of the mouse.**_

```vb
Dim mouseState = Mouse.GetState()
Dim mousePos As New Vector2(mouseState.X, mouseState.Y)

' Check left button click
If mouseState.LeftButton = ButtonState.Pressed Then
    HandleMouseClick(mousePos)
End If

' Check mouse position over a rectangle
Dim buttonRect As New Rectangle(100, 100, 200, 50)
If buttonRect.Contains(CInt(mousePos.X), CInt(mousePos.Y)) Then
    ' Mouse is over button
End If
```

---

## 9. Content Management

### Adding Assets

1. Right-click your Content project → Add → Existing Item
2. Select your image/font/sound file
3. In Properties:
   - Build Action: `Content`
   - Copy to Output Directory: `Copy if newer`

### Loading Assets

```vb
' Textures
Dim playerTexture = Content.Load(Of Texture2D)("Images/player")
' Fonts (SpriteFont .spritefont files)
Dim gameFont = Content.Load(Of SpriteFont)("Fonts/GameFont")
' Sounds
Dim jumpSound = Content.Load(Of SoundEffect)("Sounds/jump")
' Music
Dim backgroundMusic = Content.Load(Of Song)("Music/background")
```

---

## 10. Tips & Best Practices

### 1. Use `SpriteBatch` Wisely
- Always pair `Begin()` with `End()`
- Group similar draw calls together (e.g., all sprites with the same texture)
- Use `SamplerState.PointClamp` for pixel-perfect graphics:
  ```vb
  _spriteBatch.Begin(samplerState:=SamplerState.PointClamp)
  ```

### 2. Dispose Resources
- Always dispose `Texture2D`, `RenderTarget2D`, and other IDisposable objects
- Override `Dispose()` in your game class:
  ```vb
  Protected Overrides Sub Dispose(disposing As Boolean)
      If disposing Then
          _renderTarget?.Dispose()
          _spriteBatch?.Dispose()
      End If
      MyBase.Dispose(disposing)
  End Sub
  ```

### 3. Manage State
- Use enums to manage game states (Title, Playing, Paused, GameOver)
- Keep rendering logic separate from game logic

### 4. Use Delta Time
- Always multiply movement by `gameTime.ElapsedGameTime.TotalSeconds` for consistent speed across different frame rates
```vb
Dim deltaTime As Single = CSng(gameTime.ElapsedGameTime.TotalSeconds)
```

### 5. Organize Your Code
- Split your game into classes (Player, Enemy, GameManager, Renderer)
- Keep related code together

## Additional Resources

- [MonoGame Documentation](https://docs.monogame.net/)
- [MonoGame Samples](https://github.com/MonoGame/MonoGame.Samples)
- [MonoGame Community Discord](https://discord.gg/monogame)

---

Happy coding! Build amazing games with MonoGame and VB.NET! 🎮