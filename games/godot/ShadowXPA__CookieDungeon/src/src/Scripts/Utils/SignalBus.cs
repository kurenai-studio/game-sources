using CookieDungeon.Scripts.Characters;

namespace CookieDungeon.Scripts.Utils;

public static class SignalBus
{
    public static Action<Stats>? Paused;
    public static void BroadcastPaused(Stats stats) => Paused?.Invoke(stats);
    public static Action? Unpaused;
    public static void BroadcastUnpaused() => Unpaused?.Invoke();
    public static Action? PlayerDied;
    public static void BroadcastPlayerDied() => PlayerDied?.Invoke();
    public static Action<int>? LevelUpdated;
    public static void BroadcastLevelUpdated(int level) => LevelUpdated?.Invoke(level);
    public static Action<int, int>? HealthUpdated;
    public static void BroadcastHealthUpdated(int health, int maxHealth) => HealthUpdated?.Invoke(health, maxHealth);
    public static Action<int, int>? ManaUpdated;
    public static void BroadcastManaUpdated(int mana, int maxMana) => ManaUpdated?.Invoke(mana, maxMana);
    public static Action<float, float>? DashCooldownUpdated;
    public static void BroadcastDashCooldownUpdated(float cooldown, float maxCooldown) => DashCooldownUpdated?.Invoke(cooldown, maxCooldown);
    public static Action<int>? MonsterKilled;
    public static void BroadcastMonsterKilled(int experience) => MonsterKilled?.Invoke(experience);
}
