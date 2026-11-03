Imports Microsoft.Xna.Framework
Imports Microsoft.Xna.Framework.Graphics

''' <summary>
''' Represents a virtual joystick used for player input in the game.
''' Renders two images: one for the base, one for the knob.
''' Supports dead zone for better touch input experience.
''' </summary>
Public NotInheritable Class VirtualJoystick
    ' Required fields
    Private ReadOnly _baseTexture As Texture2D
    Private ReadOnly _knobTexture As Texture2D

    ''' <summary>
    ''' The scale factor for the joystick base (same for all devices).
    ''' </summary>
    Private Const JOYSTICK_BASE_SCALE As Integer = 3

    ''' <summary>
    ''' Dead zone radius as a percentage of max radius (0.0 to 1.0).
    ''' Prevents accidental movement from slight touches.
    ''' </summary>
    Private Const DEAD_ZONE As Single = 0.25F  ' 25% of max radius

    ''' <summary>
    ''' Center of the joystick base.
    ''' </summary>
    Public Property Position As Vector2

    ''' <summary>
    ''' Current value of the joystick (-1 to 1 scale).
    ''' </summary>
    Public Property Value As Vector2

    ''' <summary>
    ''' Whether the joystick is currently being touched/used.
    ''' </summary>
    Public Property IsActive As Boolean = False

    Public Sub New(baseTexture As Texture2D, knobTexture As Texture2D, center As Vector2)
        _baseTexture = baseTexture
        _knobTexture = knobTexture
        Position = center
        Value = Vector2.Zero
    End Sub

    ''' <summary>
    ''' Updates the joystick state based on touch input.
    ''' </summary>
    ''' <param name="touchPoint">Current touch position (if any).</param>
    ''' <param name="maxRadius">Maximum radius of the joystick (for dead zone compensation).</param>
    Public Sub Update(touchPoint As Vector2?, maxRadius As Single)
        If touchPoint.HasValue Then
            Dim delta = touchPoint.Value - Position
            Dim distance = delta.Length()

            ' Apply dead zone: only register input if beyond dead zone threshold
            If distance > maxRadius * DEAD_ZONE Then
                If distance > maxRadius Then
                    delta.Normalize()
                    delta *= maxRadius
                End If
                ' Normalize value with dead zone compensation
                Dim adjustedDistance = distance - maxRadius * DEAD_ZONE
                Dim adjustedMax = maxRadius * (1.0F - DEAD_ZONE)
                Value = delta / distance * (adjustedDistance / adjustedMax)
                IsActive = True
            Else
                Value = Vector2.Zero
                IsActive = False
            End If
        Else
            ' Only reset joystick if it's not currently active via keyboard
            If Not IsActive Then Value = Vector2.Zero
            IsActive = False
        End If
    End Sub

    ''' <summary>
    ''' Draws the virtual joystick on the screen.
    ''' </summary>
    ''' <param name="spriteBatch">Sprite batch to use for drawing.</param>
    ''' <param name="screenScale">Scale factor for the screen (same for all devices).</param>
    Public Sub Draw(spriteBatch As SpriteBatch, screenScale As Single)
        Dim scale = JOYSTICK_BASE_SCALE * screenScale
        Dim scaledWidth = _baseTexture.Width * scale
        Dim scaledHeight = _baseTexture.Height * scale

        Dim baseRect As New Rectangle(
            CInt(Position.X - scaledWidth / 2),
            CInt(Position.Y - scaledHeight / 2),
            CInt(scaledWidth),
            CInt(scaledHeight)
        )
        spriteBatch.Draw(_baseTexture, baseRect, Color.White)

        Dim knobPos = Position + Value * (scaledWidth / 2)
        Dim knobScaledWidth = _knobTexture.Width * scale
        Dim knobScaledHeight = _knobTexture.Height * scale

        Dim knobRect As New Rectangle(
            CInt(knobPos.X - knobScaledWidth / 2),
            CInt(knobPos.Y - knobScaledHeight / 2),
            CInt(knobScaledWidth),
            CInt(knobScaledHeight)
        )
        spriteBatch.Draw(_knobTexture, knobRect, Color.White)
    End Sub
End Class