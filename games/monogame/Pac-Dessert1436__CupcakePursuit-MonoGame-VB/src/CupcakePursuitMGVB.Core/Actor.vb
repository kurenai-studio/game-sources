Imports Microsoft.Xna.Framework
Imports Microsoft.Xna.Framework.Input

''' <summary>
''' Base class for all actors in the game.
''' </summary>
''' <remarks>
''' Actors are entities in the game that can move, interact with the environment,
''' and be drawn on the screen. This abstract class provides core functionality
''' for position management, collision detection, and movement.
''' </remarks>
Public MustInherit Class Actor
    ''' <summary>
    ''' Gets or sets the actor's position on the grid.
    ''' </summary>
    Public Property GridPosition As Point

    ''' <summary>
    ''' Gets or sets the actor's precise pixel position in the game world.
    ''' </summary>
    Public Property PixelPosition As Vector2

    ''' <summary>
    ''' Gets or sets the actor's size in pixels.
    ''' </summary>
    Public Property Size As Integer

    ''' <summary>
    ''' Gets or sets whether the actor is active and should be updated/drawn.
    ''' </summary>
    Public Property IsActive As Boolean = True

    ''' <summary>
    ''' Threshold for snapping to grid cell centers (in pixels).
    ''' </summary>
    Protected Const SNAP_THRESHOLD As Integer = 5

    ''' <summary>
    ''' Initializes a new instance of the Actor class.
    ''' </summary>
    ''' <param name="gridPosition">Initial grid position of the actor.</param>
    ''' <param name="size">Size of the actor in pixels.</param>
    Public Sub New(gridPosition As Point, size As Integer)
        Me.GridPosition = gridPosition
        PixelPosition = New Vector2(
            gridPosition.X * CELL_SIZE + CELL_SIZE \ 2,
            gridPosition.Y * CELL_SIZE + CELL_SIZE \ 2
        )
        Me.Size = size
    End Sub

    ''' <summary>
    ''' Gets the actor's bounding rectangle.
    ''' </summary>
    ''' <returns>The actor's bounding rectangle.</returns>
    ''' <remarks>
    ''' The bounding rectangle is used to check for collisions with other actors.
    ''' </remarks>
    Public Overridable Function GetBounds() As Rectangle
        Return New Rectangle(
            CInt(PixelPosition.X - Size / 2),
            CInt(PixelPosition.Y - Size / 2),
            Size,
            Size
        )
    End Function

    ''' <summary>
    ''' Updates the actor's state.
    ''' </summary>
    ''' <param name="deltaTime">The time interval since the last update.</param>
    ''' <param name="maze">The maze in which the actor is moving.</param>
    ''' <remarks>
    ''' This method is called every frame to update the actor's position, direction,
    ''' and other properties.
    ''' </remarks>
    Public Overridable Sub Update(deltaTime As Single, Optional maze As MazeTile(,) = Nothing)
    End Sub

    ''' <summary>
    ''' Represents the player character in the game.
    ''' </summary>
    ''' <remarks>
    ''' Handles player input, movement, scoring, and life management.
    ''' Supports multiple input methods: keyboard, mouse, touch, and gamepad.
    ''' </remarks>
    Public NotInheritable Class Player
        Inherits Actor

        ''' <summary>
        ''' Path to the player sprite sheet.
        ''' </summary>
        Public Const IMAGE_PATH As String = "Images/player_sheet"

        ''' <summary>
        ''' Gets or sets the player's current score.
        ''' </summary>
        Public Property Score As Integer = 0

        ''' <summary>
        ''' Gets or sets the player's remaining lives.
        ''' </summary>
        Public Property Lives As Integer = STARTING_LIVES

        ''' <summary>
        ''' Gets or sets whether the player has received a bonus life.
        ''' </summary>
        Public Property HasReceivedBonusLife As Boolean = False

        ''' <summary>
        ''' Gets or sets whether the player is alive.
        ''' </summary>
        Public Property IsAlive As Boolean = True

        ''' <summary>
        ''' Gets or sets the player's movement speed.
        ''' </summary>
        Public Property Speed As Single = PLAYER_SPEED

        ''' <summary>
        ''' Gets or sets the player's current movement direction.
        ''' </summary>
        Public Property CurrentDirection As Direction = Direction.Right

        ''' <summary>
        ''' Gets or sets the player's next intended movement direction.
        ''' </summary>
        Public Property NextDirection As Direction = Direction.Right

        ''' <summary>
        ''' Gets or sets whether the player is currently moving.
        ''' </summary>
        Public Property IsMoving As Boolean = False

        ''' <summary>
        ''' Gets or sets whether the player is in a death animation.
        ''' </summary>
        Public Property IsInDeathAnimation As Boolean = False

        ''' <summary>
        ''' Gets or sets the timer for the death animation.
        ''' </summary>
        Public Property DeathAnimationTimer As Single = 0.0F

        ''' <summary>
        ''' Gets or sets the base width of the virtual joystick (default: 64).
        ''' </summary>
        Public Shared Property JoystickBaseWidth As Integer = 64

        ''' <summary>
        ''' Gets the virtual joystick instance.
        ''' </summary>
        Public Property Joystick As VirtualJoystick

        ''' <summary>
        ''' Gets the center position of the virtual joystick.
        ''' This property is used to calculate the position of the virtual joystick on the screen.
        ''' </summary>
        ''' <returns>The center position of the virtual joystick.</returns>
        Public Shared ReadOnly Property JoystickCenter As Vector2
            Get
                Return New Vector2(
                    Renderer.ScreenOffset.X + SCREEN_WIDTH * Renderer.ScreenScale / 2.0F,
                    Renderer.ScreenOffset.Y + SCREEN_HEIGHT * Renderer.ScreenScale -
                        JoystickBaseWidth * Renderer.ScreenScale * 2 - 10.0F * Renderer.ScreenScale
                )
            End Get
        End Property

        ''' <summary>
        ''' Gets the radius of the virtual joystick.
        ''' This property is used to calculate the position of the virtual joystick on the screen.
        ''' </summary>
        ''' <returns>The radius of the virtual joystick.</returns>
        Public Shared ReadOnly Property JoystickRadius As Single
            Get
                Return JoystickBaseWidth * Renderer.ScreenScale * 2
            End Get
        End Property

        ''' <summary>
        ''' Initializes a new instance of the Player class.
        ''' </summary>
        ''' <param name="gridPosition">Initial grid position of the player.</param>
        Public Sub New(gridPosition As Point)
            MyBase.New(gridPosition, PLAYER_SIZE)
        End Sub

        ''' <summary>
        ''' Updates the player's state, handling input and movement.
        ''' </summary>
        ''' <param name="deltaTime">Time elapsed since the last update.</param>
        ''' <param name="maze">The maze grid for collision detection.</param>
        Public Overrides Sub Update(deltaTime As Single, Optional maze As MazeTile(,) = Nothing)
            If Joystick Is Nothing Then Joystick = Renderer.Joystick

            If Not IsAlive Then Exit Sub

            If IsInDeathAnimation Then
                DeathAnimationTimer += deltaTime
                If DeathAnimationTimer >= DEATH_ANIM_DURATION Then CompleteDeathAnimation()
                Exit Sub
            End If

            Dim keyboardState = Keyboard.GetState()
            Dim touchCollection = Touch.TouchPanel.GetState()
            Dim mouseState = Mouse.GetState()
            Dim gamePadState = GamePad.GetState(PlayerIndex.One)
            IsMoving = False

            If keyboardState.IsKeyDown(Keys.Left) OrElse keyboardState.IsKeyDown(Keys.A) Then
                NextDirection = Direction.Left
                IsMoving = True
            ElseIf keyboardState.IsKeyDown(Keys.Right) OrElse keyboardState.IsKeyDown(Keys.D) Then
                NextDirection = Direction.Right
                IsMoving = True
            ElseIf keyboardState.IsKeyDown(Keys.Up) OrElse keyboardState.IsKeyDown(Keys.W) Then
                NextDirection = Direction.Up
                IsMoving = True
            ElseIf keyboardState.IsKeyDown(Keys.Down) OrElse keyboardState.IsKeyDown(Keys.S) Then
                NextDirection = Direction.Down
                IsMoving = True
            End If

            Dim leftThumbStick = gamePadState.ThumbSticks.Left
            If Math.Abs(leftThumbStick.X) > 0.2F OrElse Math.Abs(leftThumbStick.Y) > 0.2F Then
                If Math.Abs(leftThumbStick.X) > Math.Abs(leftThumbStick.Y) Then
                    NextDirection = If(leftThumbStick.X < 0, Direction.Left, Direction.Right)
                Else
                    NextDirection = If(leftThumbStick.Y < 0, Direction.Up, Direction.Down)
                End If
                IsMoving = True
            End If

            Select Case ButtonState.Pressed
                Case gamePadState.DPad.Left
                    NextDirection = Direction.Left
                    IsMoving = True
                Case gamePadState.DPad.Right
                    NextDirection = Direction.Right
                    IsMoving = True
                Case gamePadState.DPad.Up
                    NextDirection = Direction.Up
                    IsMoving = True
                Case gamePadState.DPad.Down
                    NextDirection = Direction.Down
                    IsMoving = True
            End Select

            Dim scale = Renderer.ScreenScale
            Dim offsetX = Renderer.ScreenOffset.X
            Dim offsetY = Renderer.ScreenOffset.Y

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

            ' Update virtual joystick with dead zone support
            Dim activeTouchPoint As Vector2? = Nothing
            For Each touchLoc In touchCollection
                If touchLoc.State = Touch.TouchLocationState.Pressed OrElse
                   touchLoc.State = Touch.TouchLocationState.Moved Then
                    Dim touchPos = touchLoc.Position
                    If Not expandedPauseButtonRect.Contains(CInt(touchPos.X), CInt(touchPos.Y)) Then
                        Dim delta = touchPos - JoystickCenter
                        If delta.Length() <= JoystickRadius * 2 Then
                            activeTouchPoint = touchPos
                            Exit For
                        End If
                    End If
                End If
            Next touchLoc

            If activeTouchPoint Is Nothing AndAlso mouseState.LeftButton = ButtonState.Pressed Then
                Dim mousePos As New Vector2(mouseState.X, mouseState.Y)
                If Not realPauseButtonRect.Contains(CInt(mousePos.X), CInt(mousePos.Y)) Then
                    Dim delta = mousePos - JoystickCenter
                    If delta.Length() <= JoystickRadius * 2 Then
                        activeTouchPoint = mousePos
                    End If
                End If
            End If

            ' Use VirtualJoystick class for input processing with dead zone
            ArgumentNullException.ThrowIfNull(Joystick)
            Joystick.Position = JoystickCenter
            Joystick.Update(activeTouchPoint, JoystickRadius)
            If Joystick.IsActive Then HandleJoystickInput(Joystick.Value)

            If IsMoving Then
                Dim nextPosition = PixelPosition + NextDirection.ToVector2() * Speed * deltaTime
                If IsValidPosition(nextPosition, maze) Then CurrentDirection = NextDirection
                Dim newPosition = PixelPosition + CurrentDirection.ToVector2() * Speed * deltaTime

                If IsValidPosition(newPosition, maze) Then
                    PixelPosition = newPosition
                    GridPosition = New Point(
                        CInt(PixelPosition.X / CELL_SIZE),
                        CInt(PixelPosition.Y / CELL_SIZE)
                    )
                End If
            End If
        End Sub

        ''' <summary>
        ''' Handles input from the virtual joystick using normalized values.
        ''' Dead zone is handled by the VirtualJoystick class.
        ''' </summary>
        ''' <param name="joystickValue">Normalized joystick value (-1 to 1).</param>
        Private Sub HandleJoystickInput(joystickValue As Vector2)
            ' Only process input if joystick is active (beyond dead zone)
            If joystickValue.Length() < 0.01F Then
                IsMoving = False
                Return
            End If

            If Math.Abs(joystickValue.X) > Math.Abs(joystickValue.Y) Then
                NextDirection = If(joystickValue.X < 0, Direction.Left, Direction.Right)
            Else
                NextDirection = If(joystickValue.Y < 0, Direction.Up, Direction.Down)
            End If
            IsMoving = True
        End Sub

        ''' <summary>
        ''' Checks if a position is valid (not colliding with obstacles).
        ''' </summary>
        ''' <param name="newPosition">The position to check.</param>
        ''' <param name="maze">The maze grid for collision detection.</param>
        ''' <returns>True if the position is valid, False otherwise.</returns>
        Private Function IsValidPosition(newPosition As Vector2, maze As MazeTile(,)) As Boolean
            Dim bounds As New Rectangle(
                CInt(newPosition.X - Size / 2),
                CInt(newPosition.Y - Size / 2),
                Size,
                Size
            )

            Dim startTileX = Math.Max(0, bounds.Left \ CELL_SIZE)
            Dim endTileX = Math.Min(MAZE_WIDTH - 1, bounds.Right \ CELL_SIZE)
            Dim startTileY = Math.Max(0, bounds.Top \ CELL_SIZE)
            Dim endTileY = Math.Min(MAZE_HEIGHT - 1, bounds.Bottom \ CELL_SIZE)

            For tileX As Integer = startTileX To endTileX
                For tileY As Integer = startTileY To endTileY
                    Dim tile = maze(tileX, tileY)
                    If tile = MazeTile.Fence OrElse tile = MazeTile.Sapling OrElse tile = MazeTile.Tree Then Return False
                Next tileY
            Next tileX

            Return True
        End Function

        ''' <summary>
        ''' Limits the player's score to a maximum of 999999.
        ''' </summary>
        Private Sub LimitPlayerScore()
            Score = Math.Clamp(Score, 0, 999999)
        End Sub

        ''' <summary>
        ''' Collects a seed and updates the score.
        ''' </summary>
        ''' <param name="seedType">The type of seed collected.</param>
        Public Sub CollectSeed(seedType As SeedType)
            Score += SEED_POINTS
            CheckBonusLife()
            ScheduleEvent_PlayerScoreChanged(Score)
            ScheduleEvent_SeedCollected(New Seed(GridPosition, seedType))
            LimitPlayerScore()
        End Sub

        ''' <summary>
        ''' Checks if the player qualifies for a bonus life.
        ''' </summary>
        Public Sub CheckBonusLife()
            If Not HasReceivedBonusLife AndAlso Score >= BONUS_LIFE_AT Then
                Lives += 1
                HasReceivedBonusLife = True
                ScheduleEvent_LivesChanged(Lives)
            End If
        End Sub

        ''' <summary>
        ''' Collects pesticide and updates the score.
        ''' </summary>
        Public Sub CollectPesticide()
            Score += PESTICIDE_POINTS
            CheckBonusLife()
            ScheduleEvent_PlayerScoreChanged(Score)
            ScheduleEvent_PesticideCollected()
            LimitPlayerScore()
        End Sub

        ''' <summary>
        ''' Kills an enemy and updates the score.
        ''' </summary>
        Public Sub KillEnemy()
            Score += ENEMY_POINTS
            CheckBonusLife()
            ScheduleEvent_PlayerScoreChanged(Score)
            LimitPlayerScore()
        End Sub

        ''' <summary>
        ''' Reduces the player's life count and triggers death animation.
        ''' </summary>
        Public Sub LoseLife()
            Lives -= 1
            ScheduleEvent_LivesChanged(Lives)
            ScheduleEvent_LifeLost()
            IsInDeathAnimation = True
        End Sub

        ''' <summary>
        ''' Completes the death animation and either respawns or ends the game.
        ''' </summary>
        Public Sub CompleteDeathAnimation()
            IsInDeathAnimation = False
            DeathAnimationTimer = 0.0F

            If Lives <= 0 Then
                IsAlive = False
                ScheduleEvent_GameHasEnded()
            Else
                ResetPosition()
                ScheduleEvent_DeathAnimationComplete()
            End If
        End Sub

        ''' <summary>
        ''' Resets the player to the starting position.
        ''' </summary>
        Public Sub ResetPosition()
            GridPosition = PlayerStartingPoint
            PixelPosition = New Vector2(
                GridPosition.X * CELL_SIZE + CELL_SIZE \ 2,
                GridPosition.Y * CELL_SIZE + CELL_SIZE \ 2
            )
            CurrentDirection = Direction.Right
            NextDirection = Direction.Right
            IsInDeathAnimation = False
            DeathAnimationTimer = 0.0F
        End Sub

        ''' <summary>
        ''' Resets the bonus life flag for a new level.
        ''' </summary>
        Public Sub ResetBonusLifeFlag()
            HasReceivedBonusLife = False
        End Sub
    End Class

    ''' <summary>
    ''' Represents an enemy character in the game.
    ''' </summary>
    ''' <remarks>
    ''' Handles enemy movement, vulnerability state, and respawning mechanics.
    ''' Enemies patrol the maze and can be made vulnerable by collecting pesticide.
    ''' </remarks>
    Public NotInheritable Class Enemy
        Inherits Actor

        ''' <summary>
        ''' Path to the enemy sprite sheet.
        ''' </summary>
        Public Const IMAGE_PATH As String = "Images/enemy_sheet"

        ''' <summary>
        ''' Gets or sets the enemy's current movement direction.
        ''' </summary>
        Public Property Direction As Direction

        ''' <summary>
        ''' Gets or sets the enemy's movement speed.
        ''' </summary>
        Public Property Speed As Single = ENEMY_SPEED

        ''' <summary>
        ''' Gets or sets whether the enemy is vulnerable (can be killed).
        ''' </summary>
        Public Property IsVulnerable As Boolean = False

        ''' <summary>
        ''' Gets or sets the remaining time the enemy stays vulnerable.
        ''' </summary>
        Public Property VulnerableTimer As Single = 0.0F

        ''' <summary>
        ''' Gets or sets the type of enemy (Beetle or Caterpillar).
        ''' </summary>
        Public Property EnemyType As EnemyType = EnemyType.Beetle

        ''' <summary>
        ''' Gets or sets whether the enemy is respawning.
        ''' </summary>
        Public Property IsRespawning As Boolean = False

        ''' <summary>
        ''' Gets or sets the respawn timer.
        ''' </summary>
        Public Property RespawnTimer As Single = 0.0F

        ''' <summary>
        ''' Gets or sets the grace period timer after spawning.
        ''' </summary>
        Public Property GracePeriodTimer As Single = 0.0F

        ''' <summary>
        ''' Gets or sets the enemy's spawn point.
        ''' </summary>
        Public Property SpawnPoint As Point

        Private ReadOnly random As Random = Random.Shared
        Private _previousDirection As Direction

        ' List of all possible directions
        Private ReadOnly _directions As Direction() = {
            Direction.Up, Direction.Down, Direction.Left, Direction.Right
        }

        ''' <summary>
        ''' Initializes a new instance of the Enemy class.
        ''' </summary>
        ''' <param name="gridPosition">Initial grid position of the enemy.</param>
        ''' <param name="enemyType">Type of enemy to create.</param>
        Public Sub New(gridPosition As Point, Optional enemyType As EnemyType = EnemyType.Beetle)
            MyBase.New(gridPosition, ENEMY_SIZE)
            Me.EnemyType = enemyType
            Me.SpawnPoint = gridPosition
            SetRandomDirection()
            _previousDirection = Direction
            IsActive = True
        End Sub

        ''' <summary>
        ''' Updates the enemy's state, handling movement and vulnerability.
        ''' </summary>
        ''' <param name="deltaTime">Time elapsed since the last update.</param>
        ''' <param name="maze">The maze grid for collision detection.</param>
        Public Overrides Sub Update(deltaTime As Single, Optional maze As MazeTile(,) = Nothing)
            If IsRespawning Then
                RespawnTimer += deltaTime
                If RespawnTimer >= ENEMY_RESPAWN_TIME Then
                    RespawnAt(SpawnPoint)
                    ScheduleEvent_EnemyRespawned(Me)
                End If
                Exit Sub
            End If

            If Not IsActive Then Exit Sub

            If GracePeriodTimer > 0 Then
                GracePeriodTimer -= deltaTime
                If GracePeriodTimer < 0 Then GracePeriodTimer = 0
            End If

            If IsVulnerable Then
                VulnerableTimer -= deltaTime
                If VulnerableTimer <= 0 Then
                    IsVulnerable = False
                    VulnerableTimer = 0
                End If
            End If

            Dim cellCenterX = GridPosition.X * CELL_SIZE + CELL_SIZE \ 2
            Dim cellCenterY = GridPosition.Y * CELL_SIZE + CELL_SIZE \ 2
            Dim distToCenterX = Math.Abs(PixelPosition.X - cellCenterX)
            Dim distToCenterY = Math.Abs(PixelPosition.Y - cellCenterY)

            Dim isAtCellCenter = distToCenterX < SNAP_THRESHOLD AndAlso distToCenterY < SNAP_THRESHOLD

            If isAtCellCenter Then
                PixelPosition = New Vector2(cellCenterX, cellCenterY)
            End If

            Dim movement = Direction.ToVector2()
            Dim newPosition = PixelPosition + movement * Speed * deltaTime

            If maze IsNot Nothing AndAlso IsValidPosition(newPosition, maze) Then
                PixelPosition = newPosition
                GridPosition = New Point(
                    CInt(PixelPosition.X / CELL_SIZE),
                    CInt(PixelPosition.Y / CELL_SIZE)
                )

                Dim tempPixelPosition = PixelPosition
                If Direction = Direction.Left OrElse Direction = Direction.Right Then
                    If distToCenterY < SNAP_THRESHOLD Then tempPixelPosition.Y = cellCenterY
                Else
                    If distToCenterX < SNAP_THRESHOLD Then tempPixelPosition.X = cellCenterX
                End If
                PixelPosition = tempPixelPosition
            Else
                ChangeDirection()
            End If

            ' Change enemies' direction randomly at a 5% chance
            If random.Next(100) < 5 Then ChangeDirection()
            ' Set previous direction only when current direction is different
            If Direction <> _previousDirection Then _previousDirection = Direction
        End Sub

        ''' <summary>
        ''' Checks if a position is valid (not colliding with obstacles).
        ''' </summary>
        ''' <param name="newPosition">The position to check.</param>
        ''' <param name="maze">The maze grid for collision detection.</param>
        ''' <returns>True if the position is valid, False otherwise.</returns>
        Private Function IsValidPosition(newPosition As Vector2, maze As MazeTile(,)) As Boolean
            Dim bounds As New Rectangle(
                CInt(newPosition.X - Size / 2),
                CInt(newPosition.Y - Size / 2),
                Size,
                Size
            )

            Dim startTileX = Math.Max(0, bounds.Left \ CELL_SIZE)
            Dim endTileX = Math.Min(MAZE_WIDTH - 1, bounds.Right \ CELL_SIZE)
            Dim startTileY = Math.Max(0, bounds.Top \ CELL_SIZE)
            Dim endTileY = Math.Min(MAZE_HEIGHT - 1, bounds.Bottom \ CELL_SIZE)

            For tileX As Integer = startTileX To endTileX
                For tileY As Integer = startTileY To endTileY
                    Dim tile = maze(tileX, tileY)
                    If tile = MazeTile.Fence OrElse tile = MazeTile.Sapling OrElse tile = MazeTile.Tree Then Return False
                Next tileY
            Next tileX

            Return True
        End Function

        ''' <summary>
        ''' Sets a random valid direction for the enemy.
        ''' </summary>
        Public Sub SetRandomDirection()
            Dim validDirections = Direction.GetValidDirections()

            If validDirections IsNot Nothing AndAlso validDirections.Length > 0 Then
                Direction = validDirections(random.Next(validDirections.Length))
            Else
                Direction = _directions(random.Next(_directions.Length))
            End If
        End Sub

        ''' <summary>
        ''' Changes the enemy's direction to a new valid direction.
        ''' </summary>
        Private Sub ChangeDirection()
            Dim validDirections = Direction.GetValidDirections()
            Dim currOpposite = Direction.GetOppositeDirection()
            Dim prevOpposite = _previousDirection.GetOppositeDirection()
            If validDirections IsNot Nothing AndAlso validDirections.Length > 0 Then
                Dim nextDirection = validDirections(random.Next(validDirections.Length))
                If nextDirection = prevOpposite Then
                    ' Maintain the same direction if it's the opposite of the previous one
                    Direction = _previousDirection
                ElseIf nextDirection <> currOpposite Then
                    Direction = nextDirection
                End If
            End If
        End Sub

        ''' <summary>
        ''' Makes the enemy vulnerable for a set duration.
        ''' </summary>
        Public Sub MakeVulnerable()
            IsVulnerable = True
            VulnerableTimer = VULNERABLE_DURATION
        End Sub

        ''' <summary>
        ''' Kills the enemy and triggers respawn.
        ''' </summary>
        Public Sub Die()
            IsActive = False
            IsRespawning = True
            RespawnTimer = 0.0F
            GridPosition = SpawnPoint
            PixelPosition = New Vector2(
                SpawnPoint.X * CELL_SIZE + CELL_SIZE \ 2,
                SpawnPoint.Y * CELL_SIZE + CELL_SIZE \ 2
            )
            ScheduleEvent_EnemyKilled(Me)
        End Sub

        ''' <summary>
        ''' Immediately respawns the enemy at a specified position.
        ''' </summary>
        ''' <param name="position">The position to respawn at.</param>
        Public Sub RespawnAt(position As Point)
            GridPosition = position
            PixelPosition = New Vector2(
                position.X * CELL_SIZE + CELL_SIZE \ 2,
                position.Y * CELL_SIZE + CELL_SIZE \ 2
            )
            IsActive = True
            IsRespawning = False
            IsVulnerable = False
            GracePeriodTimer = ENEMY_GRACE_PERIOD
            SetRandomDirection()
        End Sub
    End Class

    ''' <summary>
    ''' Represents a collectible seed in the game.
    ''' </summary>
    ''' <remarks>
    ''' Seeds are collected by the player to grow trees and earn points.
    ''' Different seed types have different point values.
    ''' </remarks>
    Public NotInheritable Class Seed
        Inherits Actor

        ''' <summary>
        ''' Path to the seed sprite sheet.
        ''' </summary>
        Public Const IMAGE_PATH As String = "Images/object_sheet"

        ''' <summary>
        ''' Gets or sets the type of seed.
        ''' </summary>
        Public Property SeedType As SeedType = SeedType.Acorn

        ''' <summary>
        ''' Initializes a new instance of the Seed class.
        ''' </summary>
        ''' <param name="gridPosition">Grid position of the seed.</param>
        ''' <param name="seedType">Type of seed to create.</param>
        Public Sub New(gridPosition As Point, Optional seedType As SeedType = SeedType.Acorn)
            MyBase.New(gridPosition, SEED_SIZE)
            Me.SeedType = seedType
        End Sub
    End Class
End Class