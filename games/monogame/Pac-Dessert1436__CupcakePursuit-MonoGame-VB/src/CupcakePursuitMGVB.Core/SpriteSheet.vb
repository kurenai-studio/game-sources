Imports Microsoft.Xna.Framework
Imports Microsoft.Xna.Framework.Graphics
Imports Microsoft.Xna.Framework.Content

''' <summary>
''' Represents a sprite sheet with multiple frames.
''' </summary>
Public NotInheritable Class SpriteSheet
    Private ReadOnly _texture As Texture2D

    ''' <summary>
    ''' Gets the width of a single frame in pixels.
    ''' </summary>
    Public ReadOnly FrameWidth As Integer

    ''' <summary>
    ''' Gets the height of a single frame in pixels.
    ''' </summary>
    Public ReadOnly FrameHeight As Integer

    ''' <summary>
    ''' Gets the total number of frames in the sprite sheet.
    ''' </summary>
    Public ReadOnly FrameCount As Integer
    Private ReadOnly _columns As Integer
    Private ReadOnly _rows As Integer

    ''' <summary>
    ''' Initializes a new instance of the <see cref="SpriteSheet"/> class.
    ''' </summary>
    ''' <param name="content">The content manager used to load the texture.</param>
    ''' <param name="path">The asset path of the texture.</param>
    ''' <param name="frameWidth">The width of a single frame in pixels.</param>
    ''' <param name="frameHeight">The height of a single frame in pixels.</param>
    Public Sub New(content As ContentManager, path As String, frameWidth As Integer, frameHeight As Integer)
        _texture = content.Load(Of Texture2D)(path)

        If frameWidth <= 0 Then
            Throw New ArgumentException("FrameWidth must be greater than 0", NameOf(frameWidth))
        End If
        If frameHeight <= 0 Then
            Throw New ArgumentException("FrameHeight must be greater than 0", NameOf(frameHeight))
        End If

        Me.FrameWidth = frameWidth
        Me.FrameHeight = frameHeight

        ' Calculate columns and rows based on texture dimensions
        ArgumentNullException.ThrowIfNull(_texture)
        _columns = If(_texture.Width > 0, Math.Max(1, _texture.Width \ frameWidth), 1)
        _rows = If(_texture.Height > 0, Math.Max(1, _texture.Height \ frameHeight), 1)
        FrameCount = _columns * _rows
    End Sub

    ''' <summary>
    ''' Gets the rectangle for a specific frame in the sprite sheet.
    ''' The <paramref name="frameIndex"/> is clamped to the valid range [0, <see cref="FrameCount"/> - 1].
    ''' </summary>
    ''' <param name="frameIndex">The index of the frame to retrieve.</param>
    ''' <returns>The rectangle defining the frame's position in the sprite sheet.</returns>
    Public Function GetFrameRectangle(frameIndex As Integer) As Rectangle
        If _texture Is Nothing Then Return New Rectangle(0, 0, FrameWidth, FrameHeight)

        ' Clamp the frame index to valid range
        Dim clampedIndex = Math.Max(0, Math.Min(frameIndex, FrameCount - 1))

        ' Calculate the row and column for this frame
        Dim row As Integer = clampedIndex \ _columns
        Dim col As Integer = clampedIndex Mod _columns

        ' Return the rectangle for this frame
        Return New Rectangle(col * FrameWidth, row * FrameHeight, FrameWidth, FrameHeight)
    End Function

    ''' <summary>
    ''' Draws a specific frame from the sprite sheet to the sprite batch.
    ''' </summary>
    ''' <param name="spriteBatch">The SpriteBatch to draw with.</param>
    ''' <param name="frameIndex">The index of the frame to draw.</param>
    ''' <param name="position">The position to draw the sprite at.</param>
    ''' <param name="scale">The scale to apply to the sprite.</param>
    ''' <param name="tintColor">The color to tint the sprite.</param>
    Public Sub DrawFrame(spriteBatch As SpriteBatch, frameIndex As Integer, position As Vector2,
                         Optional scale As Single = 1.0F, Optional tintColor As Color? = Nothing)
        spriteBatch.Draw(
            _texture,
            position,
            GetFrameRectangle(frameIndex),
            If(tintColor, Color.White),
            0.0F,
            Vector2.Zero,
            scale,
            SpriteEffects.None,
            0.0F
        )
    End Sub

    ''' <summary>
    ''' Gets the texture used by the sprite sheet.
    ''' </summary>
    ''' <returns>The texture object.</returns>
    Public ReadOnly Property Texture As Texture2D
        Get
            Return _texture
        End Get
    End Property

    ''' <summary>
    ''' Gets the number of columns in the sprite sheet.
    ''' </summary>
    ''' <returns>The number of columns in the sprite sheet.</returns>
    Public ReadOnly Property Columns As Integer
        Get
            Return _columns
        End Get
    End Property

    ''' <summary>
    ''' Gets the number of rows in the sprite sheet.
    ''' </summary>
    ''' <returns>The number of rows in the sprite sheet.</returns>
    Public ReadOnly Property Rows As Integer
        Get
            Return _rows
        End Get
    End Property
End Class

''' <summary>
''' Represents an animation sequence for a sprite sheet.
''' </summary>
Public NotInheritable Class Animation
    Private ReadOnly _spriteSheet As SpriteSheet
    Private ReadOnly _frameIndices As Integer()
    Private _currentFrameIndex As Integer = 0
    Private _frameTimer As Single = 0

    ''' <summary>
    ''' Gets the duration of each frame in seconds. Clamped to a minimum of 0.001 s.
    ''' </summary>
    Public ReadOnly FrameDuration As Single

    ''' <summary>
    ''' Initializes a new instance of the <see cref="Animation"/> class.
    ''' </summary>
    ''' <param name="spriteSheet">The sprite sheet containing the animation frames.</param>
    ''' <param name="frameIndices">The indices of the frames to include in the animation. Falls back to {0} if empty.</param>
    ''' <param name="frameDuration">The duration of each frame in seconds. Clamped to a minimum of 0.001 s.</param>
    Public Sub New(spriteSheet As SpriteSheet, frameIndices As Integer(), frameDuration As Single)
        _spriteSheet = spriteSheet
        ' Use the first frame if `frameIndices` is empty
        _frameIndices = If(frameIndices Is Nothing OrElse frameIndices.Length = 0, {0}, frameIndices)
        ' Clamp the frame duration to a minimum value of 0.001 seconds
        Me.FrameDuration = Math.Max(0.001F, frameDuration)
    End Sub

    ''' <summary>
    ''' Gets the rectangle for the current frame in the animation.
    ''' </summary>
    ''' <returns>The rectangle defining the current frame's position in the sprite sheet.</returns>
    Public ReadOnly Property CurrentFrame As Rectangle
        Get
            If _frameIndices Is Nothing OrElse _frameIndices.Length = 0 Then
                Return New Rectangle(0, 0, _spriteSheet.FrameWidth, _spriteSheet.FrameHeight)
            End If
            Return _spriteSheet.GetFrameRectangle(_frameIndices(_currentFrameIndex))
        End Get
    End Property

    ''' <summary>
    ''' Updates the animation state based on the specified delta time.
    ''' </summary>
    ''' <remarks>
    ''' The animation is advanced to the next frame when the current frame duration is reached.
    ''' If the animation reaches the end of the sequence, it loops back to the first frame.
    ''' </remarks>
    ''' <param name="deltaTime">The time interval in seconds since the last update.</param>
    Public Sub Update(deltaTime As Single)
        If _frameIndices.Length <= 1 Then Exit Sub

        _frameTimer += deltaTime
        If _frameTimer >= FrameDuration Then
            _frameTimer -= FrameDuration
            _currentFrameIndex = (_currentFrameIndex + 1) Mod _frameIndices.Length
        End If
    End Sub

    ''' <summary>
    ''' Resets the animation to the first frame.
    ''' </summary>
    Public Sub Reset()
        _currentFrameIndex = 0
        _frameTimer = 0
    End Sub

    ''' <summary>
    ''' Gets the sprite sheet used by this animation.
    ''' </summary>
    ''' <returns>The sprite sheet containing the animation frames.</returns>
    Public ReadOnly Property SpriteSheet As SpriteSheet
        Get
            Return _spriteSheet
        End Get
    End Property

    ''' <summary>
    ''' Gets the index of the current frame in the sprite sheet.
    ''' </summary>
    ''' <returns>The zero-based index of the current frame within the sprite sheet.</returns>
    Public ReadOnly Property CurrentFrameIndex As Integer
        Get
            Return _frameIndices(_currentFrameIndex)
        End Get
    End Property
End Class