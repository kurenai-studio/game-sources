using Godot;

namespace CookieDungeon.Scripts.Objects;

public partial class Sprinkle : Projectile
{
    public override void _Ready()
    {
        base._Ready();
        var red = GD.Randf();
        var green = GD.Randf();
        var blue = GD.Randf();
        Modulate = new Color(red, green, blue);
    }
}
