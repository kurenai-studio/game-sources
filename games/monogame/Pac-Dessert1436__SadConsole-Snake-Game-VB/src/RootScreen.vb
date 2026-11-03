Imports SadConsole
Imports SadRogue.Primitives
Imports SadConsole.Input

Public Enum GameState
    Title = 0
    Playing = 1
    Paused = 2
    GameOver = 3
End Enum

Public NotInheritable Class RootScreen
    Inherits ScreenObject

    Private ReadOnly _map As ScreenSurface
    Private _snake As Snake
    Private ReadOnly _playArea As Rectangle
    Private _foodPosition As Point
    Private _score As Integer, _highScore As Integer
    Private _gameState As GameState
    Private Const AREA_WIDTH As Integer = 80
    Private Const AREA_HEIGHT As Integer = 30
    Private Const PAUSE_TEXT As String = "PAUSED - Press 'P' to Resume"

    Public Sub New()
        With Game.Instance
            _map = New ScreenSurface(.ScreenCellsX, .ScreenCellsY) With {
                .UseMouse = False
            }
        End With

        _playArea = New Rectangle(10, 3, AREA_WIDTH, AREA_HEIGHT)
        _score = 0
        _gameState = GameState.Title

        InitializeMap()
        Children.Add(_map)
        DrawTitleScreen()
    End Sub

    Private Sub InitializeMap()
        Dim colors = {Color.LightGreen, Color.LightCoral, Color.LightBlue, Color.Salmon}
        Dim colorStops As Single() = {0F, 0.35F, 0.75F, 1.0F}
        Algorithms.GradientFill(_map.FontSize,
                                _map.Surface.Area.Center,
                                _map.Surface.Width / 3,
                                45,
                                _map.Surface.Area,
                                New Gradient(colors, colorStops),
                                Function(x, y, color)
                                    _map.Surface(x, y).Background = color
                                    Return color
                                End Function)

        For x As Integer = _playArea.X To _playArea.X + _playArea.Width - 1
            For y As Integer = _playArea.Y To _playArea.Y + _playArea.Height - 1
                If x = _playArea.X OrElse x = _playArea.X + _playArea.Width - 1 OrElse
                    y = _playArea.Y OrElse y = _playArea.Y + _playArea.Height - 1 Then
                    GameGlyph.Wall.Glyph.CopyAppearanceTo(_map.Surface(x, y))
                Else
                    _map.Surface(x, y).Background = Color.Black
                End If
            Next y
        Next x

        _map.IsDirty = True
    End Sub

    Private Sub DisplayScore()
        For x As Integer = 0 To _map.Surface.Width - 1
            _map.Surface(x, 0).Foreground = Color.Black
            _map.Surface(x, 0).Glyph = 0
        Next x

        If _score > _highScore Then _highScore = _score
        Dim scoreText As String = $"Score: {_score,5} | Highest: {_highScore,5}"
        Dim xPos As Integer = (_map.Surface.Width - scoreText.Length) \ 2

        For i As Integer = 0 To scoreText.Length - 1
            With _map.Surface(xPos + i, 0)
                .Foreground = Color.MintCream
                .Background = Color.Black
                .Glyph = AscW(scoreText(i))
            End With
        Next i

        _map.IsDirty = True
    End Sub

    Private Sub SpawnFood()
        Dim random As New Random
        Do
            _foodPosition = New Point(
                random.Next(_playArea.X + 1, _playArea.X + _playArea.Width - 1),
                random.Next(_playArea.Y + 1, _playArea.Y + _playArea.Height - 1)
            )
        Loop While _snake IsNot Nothing AndAlso _snake.BodyPositions.Contains(_foodPosition)

        GameGlyph.SnakeFood.Glyph.CopyAppearanceTo(_map.Surface(_foodPosition))
        _map.IsDirty = True
    End Sub

    Public Sub CheckCollision()
        If _snake.HeadPosition = _foodPosition Then
            _score += 10
            _snake.Grow()
            DisplayScore()
            SpawnFood()
            Exit Sub
        End If

        With _snake.HeadPosition
            If .X <= _playArea.X OrElse .X >= _playArea.X + _playArea.Width - 1 OrElse
                .Y <= _playArea.Y OrElse .Y >= _playArea.Y + _playArea.Height - 1 Then
                GameOver()
                Exit Sub
            End If
        End With

        For i As Integer = 1 To _snake.BodyPositions.Count - 1
            If _snake.HeadPosition = _snake.BodyPositions(i) Then
                GameOver()
                Exit For
            End If
        Next i
    End Sub

    Private Sub GameOver()
        _gameState = GameState.GameOver
        Dim message As String = "Game Over! Press 'R' to Restart"
        Dim x As Integer = (_map.Surface.Width - message.Length) \ 2
        Dim y As Integer = _map.Surface.Height \ 2

        For i As Integer = 0 To message.Length - 1
            _map.Surface(x + i, y).Foreground = Color.Red
            _map.Surface(x + i, y).Glyph = AscW(message(i))
        Next i

        _map.IsDirty = True
    End Sub

    Public Overrides Function ProcessKeyboard(keyboard As Keyboard) As Boolean
        Dim handled = False

        Select Case _gameState
            Case GameState.Title
                If keyboard.IsKeyPressed(Keys.Space) Then
                    StartGame()
                    handled = True
                End If

            Case GameState.Playing
                Dim newDir As Direction = _snake.Direction
                If keyboard.IsKeyPressed(Keys.Up) AndAlso newDir <> Direction.Down Then
                    newDir = Direction.Up
                    handled = True
                ElseIf keyboard.IsKeyPressed(Keys.Down) AndAlso newDir <> Direction.Up Then
                    newDir = Direction.Down
                    handled = True
                ElseIf keyboard.IsKeyPressed(Keys.Left) AndAlso newDir <> Direction.Right Then
                    newDir = Direction.Left
                    handled = True
                ElseIf keyboard.IsKeyPressed(Keys.Right) AndAlso newDir <> Direction.Left Then
                    newDir = Direction.Right
                    handled = True
                End If
                _snake.Direction = newDir

                If keyboard.IsKeyPressed(Keys.P) Then
                    PauseGame()
                    handled = True
                ElseIf keyboard.IsKeyPressed(Keys.R) Then
                    RestartGame()
                    handled = True
                End If

            Case GameState.Paused
                If keyboard.IsKeyPressed(Keys.P) Then
                    ResumeGame()
                    handled = True
                End If

            Case GameState.GameOver
                If keyboard.IsKeyPressed(Keys.R) Then
                    RestartGame()
                    handled = True
                End If

        End Select

        Return handled
    End Function

    Public Overrides Sub Update(time As TimeSpan)
        MyBase.Update(time)

        If _gameState = GameState.Playing Then
            _snake.Update(time, _score)
            DisplayScore()
        End If
    End Sub

    Private Sub DrawTitleScreen()
        Const TITLE As String = "SNAKE GAME - Made With SadConsole"
        Const SUBTITLE As String = "Press SPACE to Start"
        Const CONTROLS As String = "Controls: Arrow Keys to Move, 'P' to Pause, 'R' to Restart"

        Dim titleX As Integer = (_map.Surface.Width - TITLE.Length) \ 2
        Dim subtitleX As Integer = (_map.Surface.Width - SUBTITLE.Length) \ 2
        Dim controlsX As Integer = (_map.Surface.Width - CONTROLS.Length) \ 2

        Dim titleY As Integer = _map.Surface.Height \ 2 - 2
        Dim subtitleY As Integer = _map.Surface.Height \ 2
        Dim controlsY As Integer = _map.Surface.Height \ 2 + 2

        For i As Integer = 0 To TITLE.Length - 1
            _map.Surface(titleX + i, titleY).Foreground = Color.Yellow
            _map.Surface(titleX + i, titleY).Glyph = AscW(TITLE(i))
        Next i

        For i As Integer = 0 To SUBTITLE.Length - 1
            _map.Surface(subtitleX + i, subtitleY).Foreground = Color.White
            _map.Surface(subtitleX + i, subtitleY).Glyph = AscW(SUBTITLE(i))
        Next i

        For i As Integer = 0 To CONTROLS.Length - 1
            _map.Surface(controlsX + i, controlsY).Foreground = Color.Cyan
            _map.Surface(controlsX + i, controlsY).Glyph = AscW(CONTROLS(i))
        Next i

        _map.IsDirty = True
    End Sub

    Private Sub InitializeSnake()
        If _snake IsNot Nothing Then
            For Each pos In _snake.BodyPositions
                _map.Surface(Position).Foreground = Color.Transparent
                _map.Surface(Position).Glyph = 0
            Next
        End If
    End Sub

    Private Sub StartGame()
        _gameState = GameState.Playing
        _score = 0

        For y As Integer = _map.Surface.Height \ 2 - 2 To _map.Surface.Height \ 2 + 2
            For x As Integer = 0 To _map.Surface.Width - 1
                _map.Surface(x, y).Foreground = Color.Transparent
                _map.Surface(x, y).Glyph = 0
            Next x
        Next y
        InitializeMap()
        InitializeSnake()
        _snake = New Snake(_map, _playArea.Center, Me)
        SpawnFood()
        DisplayScore()
    End Sub

    Private Sub RestartGame()
        _gameState = GameState.Playing
        _score = 0

        For x As Integer = _playArea.X + 1 To _playArea.X + _playArea.Width - 2
            For y As Integer = _playArea.Y + 1 To _playArea.Y + _playArea.Height - 2
                _map.Surface(x, y).Foreground = Color.Transparent
                _map.Surface(x, y).Glyph = 0
                _map.Surface(x, y).Background = Color.Black
            Next y
        Next x

        For y As Integer = _map.Surface.Height \ 2 - 1 To _map.Surface.Height \ 2 + 1
            For x As Integer = 0 To _map.Surface.Width - 1
                _map.Surface(x, y).Foreground = Color.Transparent
                _map.Surface(x, y).Glyph = 0
            Next x
        Next y

        Dim pauseX As Integer = (_map.Surface.Width - PAUSE_TEXT.Length) \ 2
        For x As Integer = pauseX To pauseX + PAUSE_TEXT.Length - 1
            _map.Surface(x, _map.Surface.Height \ 2).Foreground = Color.Transparent
            _map.Surface(x, _map.Surface.Height \ 2).Glyph = 0
        Next x

        InitializeMap()
        InitializeSnake()
        _snake = New Snake(_map, _playArea.Center, Me)
        SpawnFood()
        DisplayScore()
    End Sub

    Private Sub PauseGame()
        _gameState = GameState.Paused

        Dim x As Integer = (_map.Surface.Width - PAUSE_TEXT.Length) \ 2
        Dim y As Integer = _map.Surface.Height \ 2

        For i As Integer = 0 To PAUSE_TEXT.Length - 1
            _map.Surface(x + i, y).Foreground = Color.Yellow
            _map.Surface(x + i, y).Glyph = AscW(PAUSE_TEXT(i))
        Next i

        _map.IsDirty = True
    End Sub

    Private Sub ResumeGame()
        _gameState = GameState.Playing
        Dim x As Integer = (_map.Surface.Width - PAUSE_TEXT.Length) \ 2
        Dim y As Integer = _map.Surface.Height \ 2

        For xIndex As Integer = x To x + PAUSE_TEXT.Length - 1
            _map.Surface(xIndex, y).Foreground = Color.Transparent
            _map.Surface(xIndex, y).Glyph = 0
        Next xIndex

        _map.IsDirty = True
    End Sub
End Class