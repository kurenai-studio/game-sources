namespace TowerProtect.Domain.Model.Scopes;

public enum ScopeType
{
    Local,
    Remote,
    Menu,
}

public static class ScopeTypeMethods
{
    public static bool IsGameplay(this ScopeType self)
        => self == ScopeType.Local || self == ScopeType.Remote;

    public static bool IsMenu(this ScopeType self)
        => self == ScopeType.Menu;
}
