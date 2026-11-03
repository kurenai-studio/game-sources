Imports Microsoft.Xna.Framework
Imports Microsoft.Xna.Framework.Graphics
Imports Microsoft.Xna.Framework.Content
Imports Microsoft.Xna.Framework.Input

''' <summary>
''' Renders the game scene, game entities, and HUD to the screen.
''' </summary>
Public NotInheritable Class Renderer
    Implements IDisposable

    Private ReadOnly _spriteBatch As SpriteBatch
    Private ReadOnly _content As ContentManager
    Private ReadOnly _graphicsDevice As GraphicsDevice
    Private ReadOnly _pixelTexture As Texture2D

    Private _renderTarget As RenderTarget2D
    Private _gameFont As SpriteFont
    Private disposedValue As Boolean
    Private _playerSpriteSheet As SpriteSheet
    Private _enemySpriteSheet As SpriteSheet
    Private _objectSpriteSheet As SpriteSheet
    Private _iconSpriteSheet As Texture2D
    Private _titleCard As Texture2D
    Private _joystickBase As Texture2D
    Private _joystickKnob As Texture2D
    Private _pauseButton As Texture2D
    Private _generalButton As Texture2D

    Private _playerAnimations As Dictionary(Of Direction, Animation)
    Private _playerDeathAnimation As Animation
    Private _enemyAnimations As Dictionary(Of (EnemyType, Direction), Animation)

    Private Shared _joystick As VirtualJoystick
    Private Shared _screenScale As Single = 1.0F
    Private Shared _screenOffset As Vector2 = Vector2.Zero
    Private Const HUD_HEIGHT As Integer = 100

    ' Cached UI instruction strings and their measured sizes (computed after font load)
    Private Shared ReadOnly _instructions As String() = {
        "--- HOW TO PLAY ---",
        "Move with joystick/keyboard",
        "Collect seeds to plant trees",
        "Pesticide weakens enemies",
        "Survive as long as possible"
    }
    ' Cached sizes for each instruction text
    Private ReadOnly _instructionSizes(_instructions.Length - 1) As Vector2

    Public Shared ReadOnly Property ScreenScale As Single
        Get
            Return _screenScale
        End Get
    End Property

    Public Shared ReadOnly Property ScreenOffset As Vector2
        Get
            Return _screenOffset
        End Get
    End Property

    Private Shared _actualScreenWidth As Integer = SCREEN_WIDTH
    Private Shared _actualScreenHeight As Integer = SCREEN_HEIGHT
    Private Shared _pauseButtonWidth As Integer = 0
    Private Shared _pauseButtonHeight As Integer = 0

    Public Shared ReadOnly Property ActualScreenWidth As Integer
        Get
            Return _actualScreenWidth
        End Get
    End Property

    Public Shared ReadOnly Property ActualScreenHeight As Integer
        Get
            Return _actualScreenHeight
        End Get
    End Property

    Public Shared Property PauseButtonWidth As Integer
        Get
            Return _pauseButtonWidth
        End Get
        Private Set(value As Integer)
            _pauseButtonWidth = value
        End Set
    End Property

    Public Shared Property PauseButtonHeight As Integer
        Get
            Return _pauseButtonHeight
        End Get
        Private Set(value As Integer)
            _pauseButtonHeight = value
        End Set
    End Property

    Public Sub New(graphicsDevice As GraphicsDevice, content As ContentManager)
        _graphicsDevice = graphicsDevice
        _spriteBatch = New SpriteBatch(graphicsDevice)
        _content = content

        _pixelTexture = New Texture2D(graphicsDevice, 1, 1)
        _pixelTexture.SetData({Color.White})

        UpdateScreenScale()
        CreateRenderTarget()
        LoadContent()
    End Sub

    ''' <summary>
    ''' Updates the screen scale and offset.
    ''' </summary>
    Private Sub UpdateScreenScale()
        Dim newScreenWidth = _graphicsDevice.Viewport.Width
        Dim newScreenHeight = _graphicsDevice.Viewport.Height

        If newScreenWidth <> _actualScreenWidth OrElse newScreenHeight <> _actualScreenHeight Then
            _actualScreenWidth = newScreenWidth
            _actualScreenHeight = newScreenHeight

            Dim scaleX = CSng(_actualScreenWidth) / SCREEN_WIDTH
            Dim scaleY = CSng(_actualScreenHeight) / SCREEN_HEIGHT
            _screenScale = Math.Min(scaleX, scaleY)

            _screenOffset.X = (_actualScreenWidth - SCREEN_WIDTH * _screenScale) / 2
            _screenOffset.Y = (_actualScreenHeight - SCREEN_HEIGHT * _screenScale) / 2

            CreateRenderTarget()
        End If
    End Sub

    ''' <summary>
    ''' Creates a new render target for the game screen.
    ''' </summary>
    Private Sub CreateRenderTarget()
        _renderTarget?.Dispose()
        _renderTarget = New RenderTarget2D(_graphicsDevice, SCREEN_WIDTH, SCREEN_HEIGHT)
    End Sub

    ''' <summary>
    ''' Returns a sequence of zero-based indices from the given inclusive range.
    ''' </summary>
    ''' <param name="startIndex">The first index in the range.</param>
    ''' <param name="endIndex">The last index in the range.</param>
    ''' <returns>An array of zero-based indices from <paramref name="startIndex"/> to 
    ''' <paramref name="endIndex"/>, inclusive.</returns>
    Private Shared Function BuildIndexRange(startIndex As Integer, endIndex As Integer) As Integer()
        Dim length = endIndex - startIndex + 1
        Dim result(length - 1) As Integer
        For i As Integer = 0 To length - 1 : result(i) = startIndex + i - 1 : Next i
        Return result
    End Function

    ''' <summary>
    ''' Loads the game content (called manually in the constructor).
    ''' </summary>
    Private Sub LoadContent()
        _playerSpriteSheet = New SpriteSheet(_content, "Images/player_sheet", CELL_SIZE, CELL_SIZE)
        _enemySpriteSheet = New SpriteSheet(_content, "Images/enemy_sheet", CELL_SIZE, CELL_SIZE)
        _objectSpriteSheet = New SpriteSheet(_content, "Images/object_sheet", CELL_SIZE, CELL_SIZE)

        _playerAnimations = New Dictionary(Of Direction, Animation) From {
            {Direction.Left, New Animation(_playerSpriteSheet, BuildIndexRange(1, 2), 0.1F)},
            {Direction.Right, New Animation(_playerSpriteSheet, BuildIndexRange(3, 4), 0.1F)},
            {Direction.Up, New Animation(_playerSpriteSheet, BuildIndexRange(5, 6), 0.1F)},
            {Direction.Down, New Animation(_playerSpriteSheet, BuildIndexRange(7, 8), 0.1F)}
        }
        _playerDeathAnimation = New Animation(_playerSpriteSheet, BuildIndexRange(9, 16), 0.1F)

        _enemyAnimations = New Dictionary(Of (EnemyType, Direction), Animation) From {
            {(EnemyType.Beetle, Direction.Left), New Animation(_enemySpriteSheet, BuildIndexRange(1, 2), 0.1F)},
            {(EnemyType.Beetle, Direction.Right), New Animation(_enemySpriteSheet, BuildIndexRange(3, 4), 0.1F)},
            {(EnemyType.Beetle, Direction.Up), New Animation(_enemySpriteSheet, BuildIndexRange(5, 6), 0.1F)},
            {(EnemyType.Beetle, Direction.Down), New Animation(_enemySpriteSheet, BuildIndexRange(7, 8), 0.1F)},
            {(EnemyType.Caterpillar, Direction.Left), New Animation(_enemySpriteSheet, BuildIndexRange(9, 10), 0.1F)},
            {(EnemyType.Caterpillar, Direction.Right), New Animation(_enemySpriteSheet, BuildIndexRange(11, 12), 0.1F)},
            {(EnemyType.Caterpillar, Direction.Up), New Animation(_enemySpriteSheet, BuildIndexRange(13, 14), 0.1F)},
            {(EnemyType.Caterpillar, Direction.Down), New Animation(_enemySpriteSheet, BuildIndexRange(15, 16), 0.1F)}
        }

        _iconSpriteSheet = _content.Load(Of Texture2D)("Images/icon_sheet")
        _titleCard = _content.Load(Of Texture2D)("Images/title_card")
        _joystickBase = _content.Load(Of Texture2D)("Images/joystick_base")
        _joystickKnob = _content.Load(Of Texture2D)("Images/joystick_knob")
        _pauseButton = _content.Load(Of Texture2D)("Images/pause_button")
        _generalButton = _content.Load(Of Texture2D)("Images/general_button")
        _gameFont = _content.Load(Of SpriteFont)("Fonts/GameFont")

        Actor.Player.JoystickBaseWidth = _joystickBase.Width
        PauseButtonWidth = _pauseButton.Width
        PauseButtonHeight = _pauseButton.Height
        _joystick = New VirtualJoystick(_joystickBase, _joystickKnob, New Vector2(SCREEN_WIDTH / 2, SCREEN_HEIGHT - 100))

        ' Precompute UI instruction sizes once to avoid repeated MeasureString calls each frame.
        For i As Integer = 0 To _instructions.Length - 1
            _instructionSizes(i) = _gameFont.MeasureString(_instructions(i))
        Next i
    End Sub

    ''' <summary>
    ''' Gets the virtual joystick instance.
    ''' </summary>
    Public Shared ReadOnly Property Joystick As VirtualJoystick
        Get
            Return _joystick
        End Get
    End Property

    ''' <summary>
    ''' Renders the game scene to the screen.
    ''' </summary>
    ''' <param name="gameManager">The game manager instance.</param>
    ''' <param name="gameState">The current game state.</param>
    ''' <param name="deltaTime">The time interval between frames.</param>
    Public Sub Render(gameManager As GameManager, gameState As GameState, deltaTime As Single)
        UpdateScreenScale()

        _graphicsDevice.SetRenderTarget(_renderTarget)
        _graphicsDevice.Clear(Color.DarkGreen)
        _spriteBatch.Begin(samplerState:=SamplerState.PointClamp)

        Select Case gameState
            Case GameState.Title
                DrawTitleScreen()

            Case GameState.Playing, GameState.Paused
                DrawGameArea(gameManager, deltaTime)
                DrawHUD(gameManager)
                DrawJoystick()
                DrawPauseButton()
                If gameState = GameState.Paused Then DrawPauseOverlay()

            Case GameState.GameOver
                DrawGameArea(gameManager, deltaTime)
                DrawHUD(gameManager)
                DrawJoystick()
                DrawPauseButton()
                DrawGameOverScreen(gameManager)

            Case GameState.LevelCleared
                DrawGameArea(gameManager, deltaTime)
                DrawHUD(gameManager)
                DrawJoystick()
                DrawPauseButton()
                DrawLevelClearedScreen()
        End Select

        _spriteBatch.End()
        _graphicsDevice.SetRenderTarget(Nothing)
        _graphicsDevice.Clear(Color.Black)

        Dim renderWidth = CInt(SCREEN_WIDTH * _screenScale)
        Dim renderHeight = CInt(SCREEN_HEIGHT * _screenScale)
        Dim renderRect As New Rectangle(
            CInt(_screenOffset.X), CInt(_screenOffset.Y), renderWidth, renderHeight
        )
        _spriteBatch.Begin(samplerState:=SamplerState.PointClamp)
        _spriteBatch.Draw(_renderTarget, renderRect, Color.White)
        _spriteBatch.End()
    End Sub

    ''' <summary>
    ''' Draws the title screen.
    ''' </summary>
    Private Sub DrawTitleScreen()
        Dim titleRect As New Rectangle(
            CInt((SCREEN_WIDTH - _titleCard.Width * 2) / 2),
            100,
            _titleCard.Width * 2,
            _titleCard.Height * 2
        )
        _spriteBatch.Draw(_titleCard, titleRect, Color.White)

        DrawButton("START", CInt(SCREEN_WIDTH / 2), 400, "A"c)
        DrawButton("EXIT", CInt(SCREEN_WIDTH / 2), 520, "B"c)

        Dim bonusLifeStr = $"BONUS LIFE AT {BONUS_LIFE_AT} PTS."
        Dim bonusSize = _gameFont.MeasureString(bonusLifeStr)
        _spriteBatch.DrawString(_gameFont,
            bonusLifeStr,
            New Vector2((SCREEN_WIDTH - bonusSize.X) / 2, 300),
            Color.MintCream
        )

        Dim instrY As Integer = 700
        For i As Integer = 0 To _instructions.Length - 1
            Dim instr = _instructions(i)
            Dim instrSize = If(
                _instructionSizes IsNot Nothing AndAlso i < _instructionSizes.Length,
                _instructionSizes(i),
                _gameFont.MeasureString(instr)
            )
            Dim instructionPos As New Vector2(
                (SCREEN_WIDTH - instrSize.X) / 2,
                instrY
            )
            _spriteBatch.DrawString(_gameFont, instr, instructionPos, Color.White)
            instrY += 50
        Next i
    End Sub

    ''' <summary>
    ''' Draws a button on the screen. Rendering is separate from input handling.
    ''' </summary>
    ''' <remarks>
    ''' If you add or change buttons, also update <see cref="GameManager.HandleInput"/> so the
    ''' input zones stay in sync.
    ''' </remarks>
    ''' <param name="text">The text to display on the button.</param>
    ''' <param name="centerX">The center X coordinate of the button.</param>
    ''' <param name="y">The Y coordinate of the button.</param>
    ''' <param name="buttonMarker">The button marker to display on the button.</param>
    Private Sub DrawButton(text As String, centerX As Integer, y As Integer, buttonMarker As Char)
        Dim buttonWidth = _generalButton.Width * 2
        Dim buttonHeight = _generalButton.Height * 2
        Dim buttonRect As New Rectangle(
            centerX - buttonWidth \ 2,
            y,
            buttonWidth,
            buttonHeight
        )
        _spriteBatch.Draw(_generalButton, buttonRect, Color.White)

        Dim textSize As Vector2 = _gameFont.MeasureString(text)
        Dim textPos As New Vector2(
            centerX - textSize.X / 2.0F,
            y + buttonHeight / 2.0F - textSize.Y / 2.0F
        )
        _spriteBatch.DrawString(
            _gameFont,
            text,
            textPos,
            Color.Wheat,
            0,
            Vector2.Zero,
            1,
            SpriteEffects.None,
            0
        )
        _spriteBatch.DrawString(
            _gameFont,
            $"[{buttonMarker}]",
            New Vector2(buttonRect.X - 50, textPos.Y),
            Color.LightGreen,
            0,
            Vector2.Zero,
            1,
            SpriteEffects.None,
            0
        )
    End Sub

    ''' <summary>
    ''' Draws the HUD on the screen.
    ''' </summary>
    ''' <param name="gameManager">The game manager instance.</param>
    Private Sub DrawHUD(gameManager As GameManager)
        With gameManager
            DrawText($"1UP { .Player.Score,6}", New Vector2(10, 10), Color.MintCream, 1.0F)
            Dim isHighScore As Boolean = .Player.Score > .HighScore
            DrawText(
                "HI. " & If(isHighScore, $"{ .Player.Score,6}", $"{ .HighScore,6}"),
                New Vector2(SCREEN_WIDTH \ 2 + 10, 10),
                If(isHighScore, Color.Wheat, Color.MintCream), 1.0F)
        End With

        Dim lifeIconRect As New Rectangle(0, 0, ICON_SIZE, ICON_SIZE)
        For i As Integer = 0 To gameManager.Player.Lives - 1
            _spriteBatch.Draw(
                _iconSpriteSheet,
                New Rectangle(
                    10 + i * (ICON_SIZE * 2 + 4),
                    35,
                    ICON_SIZE * 2,
                    ICON_SIZE * 2
                ),
                lifeIconRect,
                Color.White
            )
        Next i

        Dim seedType = SeedTypeForLevel(gameManager.CurrentLevel)
        Dim seedIconIndex = GetSeedIconIndex(seedType)
        Dim seedIconRect As New Rectangle(seedIconIndex * ICON_SIZE, 0, ICON_SIZE, ICON_SIZE)

        Dim seasonText = $"SEASON {gameManager.CurrentLevel,2}"
        Dim seasonSize = _gameFont.MeasureString(seasonText)
        Dim seasonX = SCREEN_WIDTH \ 2 - 50
        Dim seasonY = 45
        _spriteBatch.DrawString(_gameFont, seasonText, New Vector2(seasonX, seasonY), Color.White)
        _spriteBatch.Draw(
            _iconSpriteSheet,
            New Rectangle(
                CInt(seasonX + seasonSize.X + 8),
                seasonY,
                ICON_SIZE * 2,
                ICON_SIZE * 2
            ),
            seedIconRect,
            Color.White
        )

        If gameManager.IsGetReadyActive Then
            _spriteBatch.DrawString(_gameFont, "GET READY!", New Vector2(10, 70), Color.LightGreen)
        End If
    End Sub

    ''' <summary>
    ''' Gets the index of the seed icon for the given seed type.
    ''' </summary>
    ''' <param name="seedType">The seed type.</param>
    ''' <returns>The index of the icon.</returns>
    Private Shared Function GetSeedIconIndex(seedType As SeedType) As Integer
        Select Case seedType
            Case SeedType.Acorn
                Return 1
            Case SeedType.Berry
                Return 2
            Case SeedType.Nut
                Return 3
            Case Else
                Return 1
        End Select
    End Function

    ''' <summary>
    ''' Draws the game area on the screen.
    ''' </summary>
    ''' <param name="gameManager">The game manager instance.</param>
    ''' <param name="deltaTime">The time interval since the last frame.</param>
    Private Sub DrawGameArea(gameManager As GameManager, deltaTime As Single)
        DrawMaze(gameManager.Maze, gameManager.CurrentLevel)
        DrawSpawnPoints(gameManager.Enemies)
        DrawSeeds(gameManager.Seeds)
        DrawPesticides(gameManager.Pesticides)
        DrawPlayer(gameManager.Player, deltaTime)
        DrawEnemies(gameManager.Enemies, deltaTime)
    End Sub

    ''' <summary>
    ''' Draws the spawn points on the screen.
    ''' </summary>
    ''' <param name="enemies">The list of enemies to draw.</param>
    Private Sub DrawSpawnPoints(enemies As List(Of Actor.Enemy))
        Dim renderScale = CSng(SCREEN_WIDTH) / (MAZE_WIDTH * CELL_SIZE)

        For Each enemy As Actor.Enemy In enemies
            Dim enemyPos As New Vector2(
                CInt(enemy.SpawnPoint.X * CELL_SIZE * renderScale),
                CInt(enemy.SpawnPoint.Y * CELL_SIZE * renderScale + HUD_HEIGHT)
            )
            _objectSpriteSheet.DrawFrame(_spriteBatch, 9, enemyPos, renderScale, Color.White)
        Next enemy
    End Sub

    ''' <summary>
    ''' Draws the maze on the screen.
    ''' </summary>
    ''' <param name="maze">The maze to draw.</param>
    ''' <param name="currentLevel">The current level.</param>
    Private Sub DrawMaze(maze As MazeTile(,), currentLevel As Integer)
        Dim scale = CSng(SCREEN_WIDTH) / (MAZE_WIDTH * CELL_SIZE)

        For x As Integer = 0 To MAZE_WIDTH - 1
            For y As Integer = 0 To MAZE_HEIGHT - 1
                If maze(x, y) = MazeTile.Fence Then
                    Dim rect As New Rectangle(
                        CInt(x * CELL_SIZE * scale),
                        CInt(y * CELL_SIZE * scale + HUD_HEIGHT),
                        CInt(CELL_SIZE * scale),
                        CInt(CELL_SIZE * scale)
                    )
                    DrawFence(rect, scale)
                ElseIf maze(x, y) = MazeTile.Sapling OrElse maze(x, y) = MazeTile.Tree Then
                    DrawVegetation(x, y, maze(x, y), currentLevel, scale, HUD_HEIGHT)
                End If
            Next y
        Next x
    End Sub

    ''' <summary>
    ''' Draws the vegetation on the screen.
    ''' </summary>
    ''' <param name="x">The x-coordinate of the tile.</param>
    ''' <param name="y">The y-coordinate of the tile.</param>
    ''' <param name="tileType">The type of the tile.</param>
    ''' <param name="currentLevel">The current level.</param>
    ''' <param name="scale">The scale factor.</param>
    ''' <param name="yOffset">The y-offset for the tile.</param>
    Private Sub DrawVegetation(x As Integer, y As Integer, tileType As MazeTile, Optional currentLevel As Integer = 1, Optional scale As Single = 1.0F, Optional yOffset As Integer = 0)
        Dim frameIndex As Integer
        If tileType = MazeTile.Sapling Then
            frameIndex = 7
        Else
            Dim seedType As SeedType
            Select Case (currentLevel - 1) Mod 6
                Case 0, 3
                    seedType = SeedType.Acorn
                Case 1, 4
                    seedType = SeedType.Berry
                Case 2, 5
                    seedType = SeedType.Nut
                Case Else
                    seedType = SeedType.Acorn
            End Select
            Select Case seedType
                Case SeedType.Acorn
                    frameIndex = 4
                Case SeedType.Berry
                    frameIndex = 5
                Case SeedType.Nut
                    frameIndex = 6
                Case Else
                    frameIndex = 4
            End Select
        End If

        Dim cellScale = CSng(CELL_SIZE / _objectSpriteSheet.FrameWidth) * scale
        Dim drawPos As New Vector2(x * CELL_SIZE * scale, y * CELL_SIZE * scale + yOffset)
        _objectSpriteSheet.DrawFrame(_spriteBatch, frameIndex, drawPos, cellScale, Color.White)
    End Sub

    ''' <summary>
    ''' Draws the fence on the screen.
    ''' </summary>
    ''' <param name="rect">The rectangle to draw the fence.</param>
    ''' <param name="scale">The scale factor.</param>
    Private Sub DrawFence(rect As Rectangle, Optional scale As Single = 1.0F)
        Dim cellScale = CSng(CELL_SIZE / _objectSpriteSheet.FrameWidth) * scale
        _objectSpriteSheet.DrawFrame(_spriteBatch, 0, New Vector2(rect.X, rect.Y), cellScale, Color.White)
    End Sub

    ''' <summary>
    ''' Draws the seeds on the screen.
    ''' </summary>
    ''' <param name="seeds">The list of seeds to draw.</param>
    Private Sub DrawSeeds(seeds As List(Of Actor.Seed))
        Dim renderScale = CSng(SCREEN_WIDTH) / (MAZE_WIDTH * CELL_SIZE)
        Dim scaleFactor = CSng(CELL_SIZE / _objectSpriteSheet.FrameWidth) * renderScale
        For Each seed As Actor.Seed In seeds
            If seed.IsActive Then
                Dim frameIndex As Integer = seed.SeedType + 1
                Dim drawPos As New Vector2(seed.GridPosition.X * CELL_SIZE * renderScale, seed.GridPosition.Y * CELL_SIZE * renderScale + HUD_HEIGHT)
                _objectSpriteSheet.DrawFrame(_spriteBatch, frameIndex, drawPos, scaleFactor, Color.White)
            End If
        Next seed
    End Sub

    ''' <summary>
    ''' Draws the pesticides on the screen.
    ''' </summary>
    ''' <param name="pesticides">The list of pesticides to draw.</param>
    Private Sub DrawPesticides(pesticides As List(Of Point))
        Dim renderScale = CSng(SCREEN_WIDTH) / (MAZE_WIDTH * CELL_SIZE)
        Dim scaleFactor = CSng(CELL_SIZE / _objectSpriteSheet.FrameWidth) * renderScale
        For Each item As Point In pesticides
            Dim drawPos As New Vector2(item.X * CELL_SIZE * renderScale, item.Y * CELL_SIZE * renderScale + HUD_HEIGHT)
            _objectSpriteSheet.DrawFrame(_spriteBatch, 8, drawPos, scaleFactor, Color.White)
        Next item
    End Sub

    ''' <summary>
    ''' Draws the player on the screen.
    ''' </summary>
    ''' <param name="player">The player to draw.</param>
    ''' <param name="deltaTime">The time interval since the last frame.</param>
    Private Sub DrawPlayer(player As Actor.Player, deltaTime As Single)
        If Not player.IsAlive Then Exit Sub
        Dim animation As Animation, frameIndex As Integer

        If player.IsInDeathAnimation Then
            animation = _playerDeathAnimation
            animation.Update(deltaTime)
            frameIndex = animation.CurrentFrameIndex
        Else
            animation = _playerAnimations(player.CurrentDirection)
            If player.IsMoving Then animation.Update(deltaTime) Else animation.Reset()
            frameIndex = animation.CurrentFrameIndex
        End If

        Dim renderScale = CSng(SCREEN_WIDTH) / (MAZE_WIDTH * CELL_SIZE)
        Dim scale As Single = CSng(PLAYER_SIZE / animation.SpriteSheet.FrameWidth) * renderScale
        Dim drawPos As New Vector2(
            player.PixelPosition.X * renderScale - PLAYER_SIZE * renderScale / 2,
            player.PixelPosition.Y * renderScale - PLAYER_SIZE * renderScale / 2 + HUD_HEIGHT
        )

        ' Draw actual player
        animation.SpriteSheet.DrawFrame(_spriteBatch, frameIndex, drawPos, scale, Color.White)
    End Sub

    ''' <summary>
    ''' Draws the enemies on the screen.
    ''' </summary>
    ''' <param name="enemies">The list of enemies to draw.</param>
    ''' <param name="deltaTime">The time interval since the last frame.</param>
    Private Sub DrawEnemies(enemies As List(Of Actor.Enemy), deltaTime As Single)
        Dim renderScale = CSng(SCREEN_WIDTH) / (MAZE_WIDTH * CELL_SIZE)
        Dim hasWeakEnemies As Boolean = False

        ' First pass: draw normal (non-vulnerable) enemies and detect weak ones
        For Each enemy As Actor.Enemy In enemies
            If enemy.IsActive AndAlso Not enemy.IsVulnerable Then
                Dim direction = enemy.Direction
                Dim key = (enemy.EnemyType, direction)
                Dim animation = _enemyAnimations(key)
                animation.Update(deltaTime)
                Dim frameIndex = animation.CurrentFrameIndex

                Dim scale = CSng(ENEMY_SIZE / animation.SpriteSheet.FrameWidth) * renderScale
                Dim drawPos As New Vector2(
                    enemy.PixelPosition.X * renderScale - ENEMY_SIZE * renderScale / 2,
                    enemy.PixelPosition.Y * renderScale - ENEMY_SIZE * renderScale / 2 + HUD_HEIGHT
                )

                Dim enemyColor = If(enemy.GracePeriodTimer > 0, New Color(200, 200, 255, 128), Color.White)
                animation.SpriteSheet.DrawFrame(_spriteBatch, frameIndex, drawPos, scale, enemyColor)
            ElseIf enemy.IsActive AndAlso enemy.IsVulnerable Then
                hasWeakEnemies = True
            End If
        Next enemy

        ' Second pass: draw vulnerable enemies with blink effect if any
        If hasWeakEnemies Then
            Dim blinkValue = Math.Abs(Math.Sin(Date.Now.TimeOfDay.TotalSeconds * 8.0))
            Dim blinkColor = If(blinkValue > 0.5, Color.White, Color.BlueViolet)

            For Each enemy As Actor.Enemy In enemies
                If enemy.IsActive AndAlso enemy.IsVulnerable Then
                    Dim direction = enemy.Direction
                    Dim key = (enemy.EnemyType, direction)
                    Dim animation = _enemyAnimations(key)
                    animation.Update(deltaTime)
                    Dim frameIndex = animation.CurrentFrameIndex

                    Dim scale = CSng(ENEMY_SIZE / animation.SpriteSheet.FrameWidth) * renderScale
                    Dim drawPos As New Vector2(
                        enemy.PixelPosition.X * renderScale - ENEMY_SIZE * renderScale / 2,
                        enemy.PixelPosition.Y * renderScale - ENEMY_SIZE * renderScale / 2 + HUD_HEIGHT
                    )

                    animation.SpriteSheet.DrawFrame(_spriteBatch, frameIndex, drawPos, scale, blinkColor)
                End If
            Next enemy
        End If
    End Sub

    ''' <summary>
    ''' Draws the joystick on the screen.
    ''' Uses the joystick state that was updated by the Player's input handling.
    ''' </summary>
    Private Sub DrawJoystick()
        Dim keyboardState = Keyboard.GetState()

        ' Update joystick value for keyboard input (joystick position is already set by Player)
        If keyboardState.IsKeyDown(Keys.Left) OrElse keyboardState.IsKeyDown(Keys.A) Then
            _joystick.Value = New Vector2(-1, 0)
            _joystick.IsActive = True
        ElseIf keyboardState.IsKeyDown(Keys.Right) OrElse keyboardState.IsKeyDown(Keys.D) Then
            _joystick.Value = New Vector2(1, 0)
            _joystick.IsActive = True
        ElseIf keyboardState.IsKeyDown(Keys.Up) OrElse keyboardState.IsKeyDown(Keys.W) Then
            _joystick.Value = New Vector2(0, -1)
            _joystick.IsActive = True
        ElseIf keyboardState.IsKeyDown(Keys.Down) OrElse keyboardState.IsKeyDown(Keys.S) Then
            _joystick.Value = New Vector2(0, 1)
            _joystick.IsActive = True
        Else
            ' Reset joystick value if no keyboard input is detected
            If Not _joystick.IsActive Then _joystick.Value = Vector2.Zero
        End If

        ' Draw the joystick at the correct position
        _joystick.Position = New Vector2(
            SCREEN_WIDTH / 2.0F,
            SCREEN_HEIGHT - _joystickBase.Height * 2 - 10
        )
        _joystick.Draw(_spriteBatch, 1.0F)
    End Sub

    ''' <summary>
    ''' Draws the pause button on the screen.
    ''' </summary>
    Private Sub DrawPauseButton()
        Dim scale = 2.0F
        Dim buttonRect As New Rectangle(
            10,
            CInt(SCREEN_HEIGHT - _pauseButton.Height * scale - 10),
            CInt(_pauseButton.Width * scale),
            CInt(_pauseButton.Height * scale)
        )
        _spriteBatch.Draw(_pauseButton, buttonRect, Color.White)
    End Sub

    ''' <summary>
    ''' Draws the pause overlay on the screen.
    ''' </summary>
    Private Sub DrawPauseOverlay()
        Dim overlayRect As New Rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
        _spriteBatch.Draw(_pixelTexture, overlayRect, New Color(0, 0, 0, 150))

        DrawCenteredText("PAUSED", -80, Color.White, 2.0F)
        DrawButton("RESUME", CInt(SCREEN_WIDTH / 2), CInt(SCREEN_HEIGHT / 2), "A"c)
        DrawButton("MENU", CInt(SCREEN_WIDTH / 2), CInt(SCREEN_HEIGHT / 2) + 120, "B"c)
    End Sub

    ''' <summary>
    ''' Draws the game over screen on the screen.
    ''' </summary>
    ''' <param name="gameManager">The game manager to use for drawing the game over screen.</param>
    Private Sub DrawGameOverScreen(gameManager As GameManager)
        Dim overlayRect As New Rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
        _spriteBatch.Draw(_pixelTexture, overlayRect, New Color(0, 0, 0, 150))

        DrawCenteredText("GAME OVER", -100, Color.White, 2.0F)
        DrawCenteredText($"Final Score: {gameManager.Player.Score}", -50, Color.White, 1.0F)
        DrawCenteredText($"Highest Score: {gameManager.HighScore}", -20, Color.White, 1.0F)

        DrawButton("RETRY", CInt(SCREEN_WIDTH / 2), CInt(SCREEN_HEIGHT / 2) + 50, "A"c)
        DrawButton("MENU", CInt(SCREEN_WIDTH / 2), CInt(SCREEN_HEIGHT / 2) + 170, "B"c)
    End Sub

    ''' <summary>
    ''' Draws the level cleared screen on the screen.
    ''' </summary>
    Private Sub DrawLevelClearedScreen()
        Dim overlayRect As New Rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
        _spriteBatch.Draw(_pixelTexture, overlayRect, New Color(0, 0, 0, 150))

        DrawCenteredText($"SEASON CLEARED", -100, Color.White, 1.5F)
        DrawCenteredText($"Let's move on to the next!", -50, Color.White, 1.0F)
    End Sub

    ''' <summary>
    ''' Draws text on the screen.
    ''' </summary>
    ''' <param name="text">The text to draw.</param>
    ''' <param name="position">The position to draw the text.</param>
    ''' <param name="color">The color of the text.</param>
    ''' <param name="scale">The scale factor for the text.</param>
    Private Sub DrawText(text As String, position As Vector2, color As Color, Optional scale As Single = 1.0F)
        _spriteBatch.DrawString(_gameFont, text, position, color, 0, Vector2.Zero, scale, SpriteEffects.None, 0)
    End Sub

    ''' <summary>
    ''' Draws centered text on the screen.
    ''' </summary>
    ''' <param name="text">The text to draw.</param>
    ''' <param name="yOffset">The vertical offset to draw the text.</param>
    ''' <param name="color">The color of the text.</param>
    ''' <param name="scale">The scale factor for the text.</param>
    Private Sub DrawCenteredText(text As String, yOffset As Integer, color As Color, Optional scale As Single = 1.0F)
        Dim textSize As Vector2 = _gameFont.MeasureString(text) * scale
        Dim position As New Vector2(
            (SCREEN_WIDTH - textSize.X) / 2,
            (SCREEN_HEIGHT - textSize.Y) / 2 + yOffset
        )
        _spriteBatch.DrawString(_gameFont, text, position, color, 0, Vector2.Zero, scale, SpriteEffects.None, 0)
    End Sub

    Private Sub Dispose(disposing As Boolean)
        If Not disposedValue Then
            If disposing Then
                _spriteBatch?.Dispose()
                _pixelTexture?.Dispose()
                _renderTarget?.Dispose()
            End If
            disposedValue = True
        End If
    End Sub

    ''' <summary>
    ''' Disposes of the current <see cref="Renderer"/> instance.
    ''' </summary>
    Public Sub Dispose() Implements IDisposable.Dispose
        Dispose(disposing:=True)
        GC.SuppressFinalize(Me)
    End Sub
End Class