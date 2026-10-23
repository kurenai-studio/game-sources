using Godot;

namespace CookieDungeon.Scripts.States;

[GlobalClass]
public partial class State : Node
{
    public CharacterBody2D? Subject { get; set; }

    public virtual string? ProcessInput(InputEvent @event) => null;
    public virtual string? ProcessPhysics(double delta) => null;
    public virtual string? ProcessFrame(double delta) => null;
    public virtual void Enter() { }
    public virtual void Exit() { }
    public T? GetSubject<T>() where T : CharacterBody2D => Subject as T;
}
