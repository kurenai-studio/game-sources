using CookieDungeon.Scripts.Skills;

namespace CookieDungeon.Scripts.Characters;

public class Skills
{
    public Skill NormalAttack { get; } = new()
    {
        Animation = "attack",
        Cooldown = .1f,
        Cost = 1,
    };

    public Skill? SpecialAttack { get; set; }
    public Skill Dash { get; } = new()
    {
        Animation = "dash",
        Cooldown = 5.0f,
        Cost = 10,
    };
}
