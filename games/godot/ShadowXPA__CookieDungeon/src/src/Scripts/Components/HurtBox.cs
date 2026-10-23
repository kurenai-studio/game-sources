using Godot;

namespace CookieDungeon.Scripts.Components;

public partial class HurtBox : Area2D
{
    [Export]
    public Node2D? Subject { get; private set; }
}
