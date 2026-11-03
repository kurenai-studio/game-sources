Imports Microsoft.Xna.Framework
Imports Microsoft.Xna.Framework.Input

''' <summary>
''' Manages the game state and logic.
''' </summary>
Public NotInheritable Class GameManager
    Private ReadOnly _random As New Random

    Public Property Player As Actor.Player
    Public Property Maze As MazeTile(,)
    Public ReadOnly Seeds As New List(Of Actor.Seed)
    Public ReadOnly Enemies As New List(Of Actor.Enemy)
    Public ReadOnly Pesticides As New List(Of Point)
    Public ReadOnly Saplings As New List(Of Point)
    Public ReadOnly Trees As New List(Of Point)

    Public Property GameState As GameState = GameState.Title
    Private _previousGameState As GameState = GameState.Title

    Public Property CurrentLevel As Integer = 1
    Public Property HighScore As Integer = 0
    Public Property GetReadyTimer As Single = 0.0F
    Public Property IsGetReadyActive As Boolean = False
    Public Property PesticideActive As Boolean = False
    Public Property PesticideTimer As Single = 0.0F
    Public Property LevelClearedTimer As Single = 0.0F

    Private _previousKeyboardState As KeyboardState
    Private _previousGamePadState As GamePadState
    Private ReadOnly _game As GameMain

    Public Sub New(game As GameMain)
        HighScore = LoadHighScore()
        InitializeGame()
        _game = game
    End Sub

    ''' <summary>
    ''' Requests a normal shutdown through MonoGame.
    ''' </summary>
    Private Sub ExitGame()
        _game.Exit()
    End Sub

    ''' <summary>
    ''' Initializes the game state.
    ''' </summary>
    Public Sub InitializeGame()
        Player = New Actor.Player(PlayerStartingPoint)
        CurrentLevel = 1
        InitializeLevel()
    End Sub

    ''' <summary>
    ''' Resets the game state to the initial conditions.
    ''' </summary>
    Public Sub ResetGame()
        Player.Score = 0
        Player.Lives = STARTING_LIVES
        Player.ResetBonusLifeFlag()
        CurrentLevel = 1
        InitializeLevel()
    End Sub

    ''' <summary>
    ''' Initializes the current level.
    ''' </summary>
    Public Sub InitializeLevel()
        Maze = CreateMazeLayout(CurrentLevel)
        Seeds.Clear()
        Enemies.Clear()
        Pesticides.Clear()
        Saplings.Clear()
        Trees.Clear()
        ParseMaze(CurrentLevel)
        Player.IsAlive = True
        Player.IsInDeathAnimation = False
        Player.DeathAnimationTimer = 0.0F
        Player.ResetPosition()
        GetReadyTimer = If(CurrentLevel <= 1, GET_READY_DURATION, NEXT_LEVEL_DURATION)
        LevelClearedTimer = LEVEL_CLEARED_DURATION
        IsGetReadyActive = True
        PesticideActive = False
        PesticideTimer = 0.0F
        ScheduleEvent_LevelChanged(CurrentLevel)
        ScheduleEvent_GetReadyMessage()
    End Sub

    ''' <summary>
    ''' Parses the maze layout for collectibles, pesticides, and saplings.
    ''' </summary>
    ''' <param name="level">The level number.</param>
    Private Sub ParseMaze(level As Integer)
        For x As Integer = 0 To MAZE_WIDTH - 1
            For y As Integer = 0 To MAZE_HEIGHT - 1
                Dim tile = Maze(x, y)
                Dim pos As New Point(x, y)

                Select Case tile
                    Case MazeTile.Collectible
                        Seeds.Add(New Actor.Seed(pos, SeedTypeForLevel(level)))
                        Maze(x, y) = MazeTile.Walkable

                    Case MazeTile.Pesticide
                        Pesticides.Add(pos)
                        Maze(x, y) = MazeTile.Walkable

                    Case MazeTile.Sapling
                        Saplings.Add(pos)
                End Select
            Next y
        Next x

        SpawnEnemies()
    End Sub

    ''' <summary>
    ''' Spawns enemies in the current level.
    ''' </summary>
    Private Sub SpawnEnemies()
        Dim enemyType = EnemyTypeForLevel(CurrentLevel)
        Dim enemyCount = Math.Min(4 + CurrentLevel, 8)
        Dim spawnPoints As New List(Of Point)

        For x As Integer = 0 To MAZE_WIDTH - 1
            For y As Integer = 0 To MAZE_HEIGHT - 1
                If Maze(x, y) = MazeTile.Enemy AndAlso
                   ManhattanDistance(New Point(x, y), PlayerStartingPoint) > 5 Then
                    spawnPoints.Add(New Point(x, y))
                    Maze(x, y) = MazeTile.Walkable
                End If
            Next y
        Next x

        For i As Integer = 0 To Math.Min(enemyCount - 1, spawnPoints.Count - 1)
            Dim index = _random.Next(spawnPoints.Count)
            Dim pos = spawnPoints(index)
            spawnPoints.RemoveAt(index)
            Enemies.Add(New Actor.Enemy(pos, enemyType))
        Next i
    End Sub

    ''' <summary>
    ''' Updates the game state.
    ''' </summary>
    ''' <param name="deltaTime">The time interval between frames.</param>
    Public Sub Update(deltaTime As Single)
        HandleGameStateTransitions()

        If GameState = GameState.LevelCleared Then
            LevelClearedTimer -= deltaTime
            If LevelClearedTimer <= 0 Then GameState = GameState.Playing
            Exit Sub
        End If

        If GameState = GameState.Playing Then
            If IsGetReadyActive Then
                GetReadyTimer -= deltaTime
                If GetReadyTimer <= 0 Then
                    IsGetReadyActive = False
                    GetReadyTimer = 0
                    ScheduleEvent_GameHasBegun()
                End If
                Exit Sub
            End If

            If Player.IsInDeathAnimation Then
                Player.Update(deltaTime, Maze)
                If Not Player.IsInDeathAnimation Then
                    If Player.Lives <= 0 Then
                        GameState = GameState.GameOver
                    Else
                        ResetPositionsAfterDeath()
                    End If
                End If
                Return
            End If

            Player.Update(deltaTime, Maze)
            Enemies.ForEach(Sub(e) e.Update(deltaTime, Maze))

            If PesticideActive Then
                PesticideTimer -= deltaTime
                If PesticideTimer <= 0 Then
                    PesticideActive = False
                    Enemies.ForEach(Sub(e) e.IsVulnerable = False)
                End If
            End If

            CheckCollisions()
            CheckLevelComplete()
        End If
    End Sub

    ''' <summary>
    ''' Handles transitions between game states.
    ''' </summary>
    Private Sub HandleGameStateTransitions()
        If _previousGameState <> GameState Then
            Dim oldState As GameState = _previousGameState
            _previousGameState = GameState

            ' Reset the virtual joystick position when transitioning to a new game state
            With Renderer.Joystick
                .Value = Vector2.Zero
                .IsActive = False
                .Update(Nothing, Actor.Player.JoystickRadius)
            End With

            Select Case GameState
                Case GameState.Playing
                    If oldState = GameState.Title Then
                        ScheduleEvent_GameStart()
                        ScheduleEvent_GameStateChanged(GameState)
                    ElseIf oldState = GameState.GameOver Then
                        ResetGame()
                        ScheduleEvent_GameStart()
                        ScheduleEvent_GameStateChanged(GameState)
                    ElseIf oldState = GameState.LevelCleared Then
                        CurrentLevel = Math.Clamp(CurrentLevel + 1, 0, 99)
                        InitializeLevel()
                        ScheduleEvent_MovingToNextLevel()
                        ScheduleEvent_GameStateChanged(GameState)
                    ElseIf oldState = GameState.Paused Then
                        ScheduleEvent_GameStateChanged(GameState)
                    End If

                Case GameState.GameOver
                    If Player.Score > HighScore Then
                        HighScore = Player.Score
                        SaveHighScore(HighScore)
                        ScheduleEvent_HighScoreChanged(HighScore)
                    End If
                    ScheduleEvent_GameStateChanged(GameState)

                Case GameState.LevelCleared
                    ScheduleEvent_GameStateChanged(GameState)

                Case GameState.Title
                    InitializeGame()
                    ScheduleEvent_GameStateChanged(GameState)

                Case GameState.Paused
                    ScheduleEvent_GameStateChanged(GameState)
            End Select
        End If
    End Sub

    ''' <summary>
    ''' Checks for collisions between the player and other entities.
    ''' </summary>
    Private Sub CheckCollisions()
        Dim playerBounds = Player.GetBounds()

        For Each seed In Seeds.Where(Function(s) s.IsActive).ToList()
            Dim seedBounds = seed.GetBounds()
            If playerBounds.Intersects(seedBounds) Then
                seed.IsActive = False
                Player.CollectSeed(seed.SeedType)
                GrowSaplingToTree()
            End If
        Next

        For Each pesticidePos In Pesticides.ToList()
            Dim pesticideBounds As New Rectangle(
                pesticidePos.X * CELL_SIZE + (CELL_SIZE - SEED_SIZE) \ 2,
                pesticidePos.Y * CELL_SIZE + (CELL_SIZE - SEED_SIZE) \ 2,
                SEED_SIZE,
                SEED_SIZE
            )
            If playerBounds.Intersects(pesticideBounds) Then
                Pesticides.Remove(pesticidePos)
                Player.CollectPesticide()
                ActivatePesticide()
            End If
        Next

        For Each enemy In From e In Enemies Where e.IsActive AndAlso Not e.IsRespawning
            Dim enemyBounds = enemy.GetBounds()
            If playerBounds.Intersects(enemyBounds) Then
                If enemy.IsVulnerable AndAlso enemy.GracePeriodTimer <= 0 Then
                    enemy.Die()
                    Player.KillEnemy()
                ElseIf enemy.GracePeriodTimer <= 0 AndAlso Not Player.IsInDeathAnimation Then
                    Player.LoseLife()
                    Exit For
                End If
            End If
        Next
    End Sub

    ''' <summary>
    ''' Activates the pesticide effect on enemies.
    ''' </summary>
    Private Sub ActivatePesticide()
        PesticideActive = True
        PesticideTimer = VULNERABLE_DURATION
        Enemies.ForEach(Sub(e) If e.IsActive AndAlso Not e.IsRespawning Then e.MakeVulnerable())
    End Sub

    ''' <summary>
    ''' Grows a sapling to a tree.
    ''' </summary>
    Private Sub GrowSaplingToTree()
        If Saplings.Count > 0 Then
            Dim saplingIndex = _random.Next(Saplings.Count)
            Dim saplingPos = Saplings(saplingIndex)
            Saplings.RemoveAt(saplingIndex)
            Trees.Add(saplingPos)
            Maze(saplingPos.X, saplingPos.Y) = MazeTile.Tree
            ScheduleEvent_TreeGrown(saplingPos)
        End If
    End Sub

    ''' <summary>
    ''' Resets the positions of the player and enemies after a death.
    ''' </summary>
    Private Sub ResetPositionsAfterDeath()
        Player.ResetPosition()

        For Each enemy As Actor.Enemy In Enemies
            If enemy.IsActive AndAlso Not enemy.IsRespawning Then
                enemy.RespawnAt(enemy.SpawnPoint)
            End If
        Next enemy
    End Sub

    ''' <summary>
    ''' Checks if the level is completed.
    ''' </summary>
    Private Sub CheckLevelComplete()
        If Not Aggregate s In Seeds Into Any(s.IsActive) Then
            GameState = GameState.LevelCleared
            ScheduleEvent_LevelCleared()
        End If
    End Sub

    ''' <summary>
    ''' Handles keyboard, touch, mouse and gamepad input from the player.
    ''' </summary>
    Public Sub HandleInput()
        Dim keyboardState = Keyboard.GetState()
        Dim touchCollection = Touch.TouchPanel.GetState()
        Dim mouseState = Mouse.GetState()
        Dim gamePadState = GamePad.GetState(PlayerIndex.One)

        Dim scale = Renderer.ScreenScale
        Dim offsetX = Renderer.ScreenOffset.X
        Dim offsetY = Renderer.ScreenOffset.Y

        Dim aPressed = gamePadState.Buttons.A = ButtonState.Pressed AndAlso
                       _previousGamePadState.Buttons.A = ButtonState.Released
        Dim bPressed = gamePadState.Buttons.B = ButtonState.Pressed AndAlso
                       _previousGamePadState.Buttons.B = ButtonState.Released
        Dim startPressed = gamePadState.Buttons.Start = ButtonState.Pressed AndAlso
                           _previousGamePadState.Buttons.Start = ButtonState.Released
        Dim backPressed = gamePadState.Buttons.Back = ButtonState.Pressed AndAlso
                          _previousGamePadState.Buttons.Back = ButtonState.Released

        Dim zPressed = keyboardState.IsKeyDown(Keys.Z) AndAlso
                       Not _previousKeyboardState.IsKeyDown(Keys.Z)
        Dim xPressed = keyboardState.IsKeyDown(Keys.X) AndAlso
                       Not _previousKeyboardState.IsKeyDown(Keys.X)

        Select Case GameState
            Case GameState.Title
                If keyboardState.IsKeyDown(Keys.Enter) AndAlso
                    Not _previousKeyboardState.IsKeyDown(Keys.Enter) Then
                    GameState = GameState.Playing
                ElseIf keyboardState.IsKeyDown(Keys.Escape) AndAlso
                       Not _previousKeyboardState.IsKeyDown(Keys.Escape) Then
                    ScheduleEvent_GameStateChanged(GameState.Title)
                    ExitGame()
                End If

                If aPressed OrElse zPressed Then
                    GameState = GameState.Playing
                ElseIf bPressed OrElse xPressed Then
                    ScheduleEvent_GameStateChanged(GameState.Title)
                    ExitGame()
                End If

                For Each touchLoc In touchCollection
                    If touchLoc.State = Touch.TouchLocationState.Pressed Then
                        Dim touchPos = touchLoc.Position
                        Dim startButton As New Rectangle(
                            CInt((SCREEN_WIDTH \ 2 - 100) * scale + offsetX),
                            CInt(400 * scale + offsetY),
                            CInt(200 * scale),
                            CInt(80 * scale)
                        )
                        Dim exitButton As New Rectangle(
                            CInt((SCREEN_WIDTH \ 2 - 100) * scale + offsetX),
                            CInt(520 * scale + offsetY),
                            CInt(200 * scale),
                            CInt(80 * scale)
                        )
                        If IsPointInRect(touchPos, startButton) Then
                            GameState = GameState.Playing
                        ElseIf IsPointInRect(touchPos, exitButton) Then
                            ScheduleEvent_GameStateChanged(GameState.Title)
                            ExitGame()
                        End If
                    End If
                Next touchLoc

                If mouseState.LeftButton = ButtonState.Pressed Then
                    Dim mousePos As New Vector2(mouseState.X, mouseState.Y)
                    Dim startButton As New Rectangle(
                        CInt((SCREEN_WIDTH \ 2 - 100) * scale + offsetX),
                        CInt(400 * scale + offsetY),
                        CInt(200 * scale),
                        CInt(80 * scale)
                    )
                    Dim exitButton As New Rectangle(
                        CInt((SCREEN_WIDTH \ 2 - 100) * scale + offsetX),
                        CInt(520 * scale + offsetY),
                        CInt(200 * scale),
                        CInt(80 * scale)
                    )
                    If IsPointInRect(mousePos, startButton) Then
                        GameState = GameState.Playing
                    ElseIf IsPointInRect(mousePos, exitButton) Then
                        ScheduleEvent_GameStateChanged(GameState.Title)
                        ExitGame()
                    End If
                End If

            Case GameState.GameOver
                If keyboardState.IsKeyDown(Keys.Enter) AndAlso
                    Not _previousKeyboardState.IsKeyDown(Keys.Enter) Then
                    GameState = GameState.Playing
                End If

                If aPressed OrElse zPressed Then
                    GameState = GameState.Playing
                ElseIf bPressed OrElse xPressed Then
                    GameState = GameState.Title
                End If

                Dim retryButton = New Rectangle(
                    CInt((SCREEN_WIDTH \ 2 - 100) * scale + offsetX),
                    CInt((SCREEN_HEIGHT \ 2 + 10) * scale + offsetY),
                    CInt(200 * scale),
                    CInt(80 * scale)
                )
                Dim exitButton = New Rectangle(
                    CInt((SCREEN_WIDTH \ 2 - 100) * scale + offsetX),
                    CInt((SCREEN_HEIGHT \ 2 + 130) * scale + offsetY),
                    CInt(200 * scale),
                    CInt(80 * scale)
                )

                For Each touchLoc In touchCollection
                    If touchLoc.State = Touch.TouchLocationState.Pressed Then
                        Dim touchPos = touchLoc.Position
                        If IsPointInRect(touchPos, retryButton) Then
                            GameState = GameState.Playing
                        ElseIf IsPointInRect(touchPos, exitButton) Then
                            GameState = GameState.Title
                        End If
                    End If
                Next touchLoc

                If mouseState.LeftButton = ButtonState.Pressed Then
                    Dim mousePos As New Vector2(mouseState.X, mouseState.Y)
                    If IsPointInRect(mousePos, retryButton) Then
                        GameState = GameState.Playing
                    ElseIf IsPointInRect(mousePos, exitButton) Then
                        GameState = GameState.Title
                    End If
                End If

            Case GameState.Playing
                If keyboardState.IsKeyDown(Keys.P) OrElse
                   (keyboardState.IsKeyDown(Keys.Escape) AndAlso Not _previousKeyboardState.IsKeyDown(Keys.Escape)) Then
                    GameState = GameState.Paused
                End If

                If startPressed OrElse backPressed Then
                    GameState = GameState.Paused
                End If

                Dim basePauseButtonRect As New Rectangle(
                    10,
                    SCREEN_HEIGHT - Renderer.PauseButtonHeight * PAUSE_BUTTON_SCALE - 10,
                    Renderer.PauseButtonWidth * PAUSE_BUTTON_SCALE,
                    Renderer.PauseButtonHeight * PAUSE_BUTTON_SCALE
                )
                Dim realPauseButtonRect As New Rectangle(
                    CInt(basePauseButtonRect.X * scale + offsetX),
                    CInt(basePauseButtonRect.Y * scale + offsetY),
                    CInt(basePauseButtonRect.Width * scale),
                    CInt(basePauseButtonRect.Height * scale)
                )

                Dim touchPadding = CInt(20 * scale)
                Dim expandedPauseButtonRect As New Rectangle(
                    Math.Max(0, realPauseButtonRect.X - touchPadding),
                    Math.Max(0, realPauseButtonRect.Y - touchPadding),
                    realPauseButtonRect.Width + (touchPadding * 2),
                    realPauseButtonRect.Height + (touchPadding * 2)
                )

                For Each touchLoc In touchCollection
                    If touchLoc.State = Touch.TouchLocationState.Pressed Then
                        Dim touchPos = touchLoc.Position
                        If IsPointInRect(touchPos, expandedPauseButtonRect) Then
                            GameState = GameState.Paused
                        End If
                    End If
                Next touchLoc

                If mouseState.LeftButton = ButtonState.Pressed Then
                    Dim mousePos As New Vector2(mouseState.X, mouseState.Y)
                    If IsPointInRect(mousePos, expandedPauseButtonRect) Then
                        GameState = GameState.Paused
                    End If
                End If

            Case GameState.Paused
                If keyboardState.IsKeyDown(Keys.P) OrElse
                   (keyboardState.IsKeyDown(Keys.Escape) AndAlso Not _previousKeyboardState.IsKeyDown(Keys.Escape)) Then
                    GameState = GameState.Playing
                ElseIf keyboardState.IsKeyDown(Keys.Enter) AndAlso
                       Not _previousKeyboardState.IsKeyDown(Keys.Enter) Then
                    GameState = GameState.Playing
                End If

                If aPressed OrElse zPressed OrElse startPressed Then
                    GameState = GameState.Playing
                ElseIf bPressed OrElse xPressed Then
                    GameState = GameState.Title
                End If

                Dim resumeButton As New Rectangle(
                    CInt((SCREEN_WIDTH \ 2 - 100) * scale + offsetX),
                    CInt((SCREEN_HEIGHT \ 2 - 40) * scale + offsetY),
                    CInt(200 * scale),
                    CInt(80 * scale)
                )
                Dim exitButton As New Rectangle(
                    CInt((SCREEN_WIDTH \ 2 - 100) * scale + offsetX),
                    CInt((SCREEN_HEIGHT \ 2 + 80) * scale + offsetY),
                    CInt(200 * scale),
                    CInt(80 * scale)
                )

                For Each touchLoc In touchCollection
                    If touchLoc.State = Touch.TouchLocationState.Pressed Then
                        Dim touchPos = touchLoc.Position
                        If IsPointInRect(touchPos, resumeButton) Then
                            GameState = GameState.Playing
                        ElseIf IsPointInRect(touchPos, exitButton) Then
                            GameState = GameState.Title
                        End If
                    End If
                Next touchLoc

                If mouseState.LeftButton = ButtonState.Pressed Then
                    Dim mousePos As New Vector2(mouseState.X, mouseState.Y)
                    If IsPointInRect(mousePos, resumeButton) Then
                        GameState = GameState.Playing
                    ElseIf IsPointInRect(mousePos, exitButton) Then
                        GameState = GameState.Title
                    End If
                End If
        End Select

        _previousKeyboardState = keyboardState
        _previousGamePadState = gamePadState
    End Sub
End Class