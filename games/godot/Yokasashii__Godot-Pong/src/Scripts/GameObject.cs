using Godot;

// Author : Vincent Guerrini / Yoka

namespace Com.Vincent_Guerrini.PlayBoard.GameObject;
	
public partial class GameObject : Area2D
{
	protected int Height;
    public int speed;
    protected const string Runderer = "Runderer";
    protected Vector2 screenSize;
    public PackedScene scene;


    public override void _Ready()
	{
        screenSize = GetWindow().Size;
    }
}

