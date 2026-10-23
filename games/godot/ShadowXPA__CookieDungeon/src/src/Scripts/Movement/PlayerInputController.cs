using Godot;

namespace CookieDungeon.Scripts.Movement;

public class PlayerInputController : IInputController
{
    public static readonly PlayerInputController Instance = new();

    public Vector2 GetDirection()
    {
        return Input.GetVector("move_left", "move_right", "move_up", "move_down");
    }

    public bool IsNormalAttacking()
    {
        return Input.IsActionJustPressed("normal_attack");
    }

    public Vector2 GetTargetPosition(Node2D? origin)
    {
        return origin?.GetGlobalMousePosition() ?? Vector2.Up;
    }

    public bool IsDashing()
    {
        return Input.IsActionJustPressed("dash");
    }
}
