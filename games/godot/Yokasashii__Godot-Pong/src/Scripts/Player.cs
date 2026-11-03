using Com.Vincent_Guerrini.PlayBoard;
using Godot;

// Author : Vincent Guerrini / Yoka

namespace Com.Vincent_Guerrini.PlayBoard.GameObject;

public partial class Player : GameObject
{
    [Export] public Sprite2D runderer;
    public Key KeyUp = Key.Up;
    public Key KeyDown = Key.Down;


    public override void _Ready()
	{
        speed = 250;

        base._Ready();
    }

    public override void _Process(double pDelta)
    {
        float lDelta = (float)pDelta;

        if (Input.IsKeyPressed(KeyUp) && Position.Y >= Height / 2) Position += Vector2.Up * speed * 2 * lDelta;
        if (Input.IsKeyPressed(KeyDown) && Position.Y <= screenSize.Y - Height / 2) Position += Vector2.Down * speed * 2 * lDelta;
    }
}
