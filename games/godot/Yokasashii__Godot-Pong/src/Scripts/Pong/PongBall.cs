using Com.Vincent_Guerrini.PlayBoard.GameObject;
using Godot;

// Author : Vincent Guerrini / Yoka

namespace Com.Vincent_Guerrini.PlayBoard.GameObject.Pong;

public partial class PongBall : Ball
{
    protected override void CheckRebound()
    {
        base.CheckRebound();
        if (Position.Y + Height / 2 >= screenSize.Y) Scale *= new Vector2(1, -1);
    }
}

