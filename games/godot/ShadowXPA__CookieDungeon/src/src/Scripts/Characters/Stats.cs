using Godot;

namespace CookieDungeon.Scripts.Characters;

[GlobalClass]
public partial class Stats : Resource
{
    [Export]
    public int Level { get; set; } = 1;
    [Export]
    public int Health { get; set; }
    [Export]
    public int MaxHealth { get; set; }
    [Export]
    public int Mana { get; set; }
    [Export]
    public int MaxMana { get; set; }
    [Export]
    public int Attack { get; set; }
    [Export]
    public int Defense { get; set; }
    [Export]
    public float Speed { get; set; }
    [Export]
    public float CriticalRate { get; set; } = .05f;
    [Export]
    public float CriticalDamage { get; set; } = 1.5f;
    public float Acceleration => Speed * 10.0f;
    public float Deceleration => Speed * 15.0f;
    public float Dash => Speed * 5.0f;
    [Export]
    public int Experience { get; set; } = 0;
    public int HealthRate { get; private set; } = 1;
    public int ManaRate { get; private set; } = 5;

    public Stats() { }

    public Stats(Stats other)
    {
        Level = other.Level;
        Health = other.Health;
        MaxHealth = other.MaxHealth;
        Mana = other.Mana;
        MaxMana = other.MaxMana;
        Attack = other.Attack;
        Defense = other.Defense;
        Speed = other.Speed;
        CriticalRate = other.CriticalRate;
        CriticalDamage = other.CriticalDamage;
        Experience = other.Experience;
        HealthRate = other.HealthRate;
        ManaRate = other.ManaRate;
    }

    public void RegenHealth(bool doubleRate = false)
    {
        Health = Mathf.Min(Health + HealthRate * (doubleRate ? 2 : 1), MaxHealth);
    }

    public void RegenMana(bool doubleRate = false)
    {
        Mana = Mathf.Min(Mana + ManaRate * (doubleRate ? 2 : 1), MaxMana);
    }

    public bool AddExperience(int exp)
    {
        var prevLevel = Level;

        Experience += exp;

        while (Experience >= 100)
        {
            Experience -= 100;
            LevelUp();
        }

        return (Level - prevLevel) > 0;
    }

    private void LevelUp()
    {
        Level++;
        MaxHealth += Level * 2;
        Health = MaxHealth;
        MaxMana += Level;
        Mana = MaxMana;
        Attack += Level * 2;
        Defense += Level;
        HealthRate += Level;
        ManaRate += Level;
    }
}
