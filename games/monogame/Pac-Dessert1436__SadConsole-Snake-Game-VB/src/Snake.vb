Imports SadConsole
Imports SadRogue.Primitives

Public Structure GameGlyph
    Private ReadOnly code As Integer
    Private ReadOnly color As Color

    Private Sub New(code As Integer, color As Color)
        Me.code = code
        Me.color = color
    End Sub

    Public Shared ReadOnly Property SnakeHead As New GameGlyph(2, Color.LemonChiffon)
    Public Shared ReadOnly Property SnakeBody As New GameGlyph(3, Color.LemonChiffon)
    Public Shared ReadOnly Property SnakeFood As New GameGlyph(5, Color.MintCream)
    Public Shared ReadOnly Property Wall As New GameGlyph(19, Color.CornflowerBlue)

    Public ReadOnly Property Glyph As ColoredGlyph
        Get
            Return New ColoredGlyph(color, Color.Black, code)
        End Get
    End Property
End Structure

Public NotInheritable Class Snake
    Private ReadOnly _map As ScreenSurface
    Private ReadOnly _body As New List(Of Point)
    Private _direction As Direction
    Private _nextDirection As Direction
    Private _moveTimer As Double
    Private ReadOnly _gameScreen As RootScreen

    Private Shared ReadOnly Property MoveDelay(score As Integer) As Double
        Get
            Return Math.Max(0.05, 0.1 - score / 1000)
        End Get
    End Property

    Public Property Direction As Direction
        Get
            Return _nextDirection
        End Get
        Set(value As Direction)
            _nextDirection = value
        End Set
    End Property

    Public ReadOnly Property HeadPosition As Point
        Get
            Return _body(0)
        End Get
    End Property

    Public ReadOnly Property BodyPositions As List(Of Point)
        Get
            Return _body
        End Get
    End Property

    Public Sub New(map As ScreenSurface, startPosition As Point, gameScreen As RootScreen)
        _map = map
        _gameScreen = gameScreen
        _body.Add(startPosition)
        For i As Integer = 1 To 5
            _body.Add(startPosition - New Point(i, 0))
        Next i
        _direction = Direction.Right
        _nextDirection = Direction.Right
        _moveTimer = 0

        GameGlyph.SnakeHead.Glyph.CopyAppearanceTo(_map.Surface(startPosition))
        _map.IsDirty = True
    End Sub

    Public Sub Update(time As TimeSpan, score As Integer)
        _moveTimer += time.TotalSeconds

        If _moveTimer >= MoveDelay(score) Then
            _moveTimer = 0
            Move()
        End If
    End Sub

    Private Sub Move()
        _direction = _nextDirection

        Dim newHead As Point = _body(0) + _direction
        Dim tail As Point = _body(_body.Count - 1)
        _map.Surface(tail).Background = Color.Black
        _map.Surface(tail).Foreground = Color.Black
        _map.Surface(tail).Glyph = 0

        For i As Integer = _body.Count - 1 To 1 Step -1
            _body(i) = _body(i - 1)
        Next i
        _body(0) = newHead

        For i As Integer = 1 To _body.Count - 1
            GameGlyph.SnakeBody.Glyph.CopyAppearanceTo(_map.Surface(_body(i)))
        Next i

        GameGlyph.SnakeHead.Glyph.CopyAppearanceTo(_map.Surface(newHead))

        _map.IsDirty = True
        _gameScreen.CheckCollision()
    End Sub

    Public Sub Grow()
        Dim tail As Point = _body(_body.Count - 1)
        _body.Add(tail)
        GameGlyph.SnakeBody.Glyph.CopyAppearanceTo(_map.Surface(tail))
        _map.IsDirty = True
    End Sub
End Class