using Godot;

namespace CookieDungeon.Scripts.Utils;

public static class ResourceManager
{
    public static class Identifier
    {
        public const string PlayerStats = "uid://by6fnmu5cqmc2";
        public const string Egg = "uid://ceunla3edid8o";
        public const string EnemyStats = "uid://dhp6x33dtw3p1";
        public const string EggStats = "uid://dwe74lbrl4e4v";
    }

    public static T Load<T>(string resourceId) where T : Resource => ResourceLoader.Load<T>(resourceId);
}
