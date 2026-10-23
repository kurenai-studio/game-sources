using Godot;

namespace CookieDungeon.Scripts.Utils;

public static class NodeExtensions
{
    public static void LookAtPoint(this Node2D node2D, Vector2 point)
    {
        node2D.Rotation = node2D.GlobalPosition.AngleToPoint(point) + Mathf.Pi / 2f;
    }

    public static void ResetAndPlay(this AnimationPlayer animationPlayer, string animation)
    {
        animationPlayer.Play("RESET");
        animationPlayer.Advance(0);
        animationPlayer.Play(animation);
    }
}
