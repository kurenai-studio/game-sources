namespace TowerProtect.Domain.Model.Scopes;

public abstract record StartData
{
    public abstract ScopeType Type { get; }
}
