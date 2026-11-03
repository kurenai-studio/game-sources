using Godot;
using System.Xml.Linq;
using static Godot.OpenXRInterface;

// Author : Vincent Guerrini / Yoka

namespace Com.Vincent_Guerrini.PlayBoard.GameObject;
	
public partial class Ball : GameObject
{
    public override void _Ready()
	{
        speed = 200;
        AreaEntered += OnCollision;
        base._Ready();
    }

	public override void _Process(double pDelta)
	{
		float lDelta = (float)pDelta;
        Position += new Vector2(Scale.X, Scale.Y) * speed * lDelta;
        CheckRebound();
    }

    protected override void Dispose(bool pDisposing)
    {
        AreaEntered -= OnCollision;
    }

    protected virtual void CheckRebound()
    {
        if (Position.Y - Height / 2 <= 0) Scale *= new Vector2(1, -1);
    }

    private void OnCollision(Area2D pArea)
    {
        Scale *= new Vector2(-1, 1);
    }
}
