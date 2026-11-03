namespace TowerProtect.Domain.Model.Scopes;

public record StartLocalData(
    string Username,
    ServerHostData? HostInfo = null) : StartData
{
    public override ScopeType Type => ScopeType.Local;
}

public record ServerHostData(string Password, ushort Port);
