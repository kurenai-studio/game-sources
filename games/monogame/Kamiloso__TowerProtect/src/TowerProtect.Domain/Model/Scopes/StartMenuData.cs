namespace TowerProtect.Domain.Model.Scopes;

public record StartMenuData : StartData
{
    public override ScopeType Type => ScopeType.Menu;
}
