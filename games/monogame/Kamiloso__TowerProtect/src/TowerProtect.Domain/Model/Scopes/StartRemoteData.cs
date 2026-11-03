namespace TowerProtect.Domain.Model.Scopes;

public record StartRemoteData(
    string Username,
    string Password,
    string Address) : StartData
{
    public override ScopeType Type => ScopeType.Remote;
}
