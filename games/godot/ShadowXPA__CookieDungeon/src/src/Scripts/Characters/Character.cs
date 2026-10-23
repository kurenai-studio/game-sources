using Godot;

namespace CookieDungeon.Scripts.Characters;

public partial class Character : CharacterBody2D
{
    [Export]
    public required Stats Stats { get; set; }
    [Export]
    public Control? Damage { get; private set; }
    [Export]
    public Color CritDamageColor { get; private set; } = new Color(1, 0, 0);
    [Export]
    public Color DamageColor { get; private set; } = new Color(1, 1, 1);

    public virtual void ApplyDamage(int dmg, float critDmg, bool isCrit)
    {
        var finalDmg = Mathf.FloorToInt(Mathf.Max(dmg - Stats.Defense, 1) * (isCrit ? critDmg : 1));
        Stats.Health -= finalDmg;

        if (Damage is not null)
        {
            var label = new Label();
            label.AddThemeFontSizeOverride("font_size", isCrit ? 14 : 12);
            label.AddThemeConstantOverride("outline_size", 5);
            label.Text = $"{finalDmg}";
            label.Modulate = isCrit ? CritDamageColor : DamageColor;
            Damage.AddChild(label);
            label.Position = new Vector2 { X = -label.Size.X / 2, Y = -label.Size.Y / 2 };

            var tween = CreateTween();
            var endPosition = label.Position + Vector2.Up * 25;

            tween.TweenProperty(label, "position", endPosition, 1f).SetTrans(Tween.TransitionType.Circ).SetEase(Tween.EaseType.Out);
            tween.TweenProperty(label, "modulate:a", 0.0f, 1.0f);
            tween.TweenCallback(Callable.From(() =>
                {
                    label.QueueFree();
                    tween.Kill();
                }));

            tween.Play();
        }
    }
}
