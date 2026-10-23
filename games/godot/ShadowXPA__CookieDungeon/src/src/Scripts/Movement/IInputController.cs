using Godot;

namespace CookieDungeon.Scripts.Movement;

public interface IInputController
{
    Vector2 GetDirection() => Vector2.Zero;
    bool IsNormalAttacking() => false;
    Vector2 GetTargetPosition(Node2D? origin = null) => Vector2.Zero;
    bool IsDashing() => false;
}
