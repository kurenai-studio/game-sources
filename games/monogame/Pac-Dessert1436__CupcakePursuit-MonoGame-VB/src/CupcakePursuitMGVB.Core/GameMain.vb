Imports Microsoft.Xna.Framework
Imports Microsoft.Xna.Framework.Graphics

''' <summary>
''' Main game class that coordinates all game systems using proper object-oriented patterns.
''' </summary>
Public NotInheritable Class GameMain
    Inherits Game

    Private ReadOnly _graphics As GraphicsDeviceManager
    
    ' Game systems
    Private _gameManager As GameManager
    Private _renderer As Renderer
    Private _soundManager As SoundManager

    Public Sub New()
        _graphics = New GraphicsDeviceManager(Me)
        Content.RootDirectory = "Content"
        IsMouseVisible = True
    End Sub

    Protected Overrides Sub Initialize()
        If OperatingSystem.IsAndroid() OrElse OperatingSystem.IsIOS() Then  ' Experimental for iOS
            _graphics.IsFullScreen = True
            With GraphicsDevice.PresentationParameters
                ' The Viewport constructor defaults `MinDepth` to 0.0 and `MaxDepth` to 1.0.
                ' We rely on these defaults here.
                GraphicsDevice.Viewport = New Viewport(0, 0, .BackBufferWidth, .BackBufferHeight)
            End With
        Else
            _graphics.PreferredBackBufferWidth = SCREEN_WIDTH
            _graphics.PreferredBackBufferHeight = SCREEN_HEIGHT
            _graphics.IsFullScreen = False
        End If
        _graphics.ApplyChanges()

        MyBase.Initialize()
    End Sub

    Protected Overrides Sub LoadContent()
        ' Game systems must be initialized right after the `Initialize` phase, so
        ' they have access to the graphics device and content manager.
        _gameManager = New GameManager(Me)
        _renderer = New Renderer(GraphicsDevice, Content)
        _soundManager = New SoundManager(Content)

        MyBase.LoadContent()
    End Sub

    Protected Overrides Sub Update(gameTime As GameTime)
        ' Handle input for game state transitions
        _gameManager.HandleInput()

        ' Update game logic
        Dim deltaTime As Single = CSng(gameTime.ElapsedGameTime.TotalSeconds)
        _gameManager.Update(deltaTime)
        MyBase.Update(gameTime)
    End Sub

    Protected Overrides Sub Draw(gameTime As GameTime)
        Dim deltaTime As Single = CSng(gameTime.ElapsedGameTime.TotalSeconds)
        _renderer.Render(_gameManager, _gameManager.GameState, deltaTime)
        EventScheduler.RaiseScheduledEvents()
        MyBase.Draw(gameTime)
    End Sub

    Protected Overrides Sub Dispose(disposing As Boolean)
        If disposing Then
            ' Dispose of all game systems
            _soundManager?.Dispose()
            _renderer?.Dispose()
        End If

        MyBase.Dispose(disposing)
    End Sub
End Class