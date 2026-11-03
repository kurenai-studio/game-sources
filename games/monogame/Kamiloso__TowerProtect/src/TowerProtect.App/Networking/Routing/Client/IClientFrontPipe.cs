namespace TowerProtect.App.Networking.Routing.Client;

public interface IClientFrontPipe
{
    void Send(string message);
    bool TryDequeue(out string message);
    bool IsDead();
}
