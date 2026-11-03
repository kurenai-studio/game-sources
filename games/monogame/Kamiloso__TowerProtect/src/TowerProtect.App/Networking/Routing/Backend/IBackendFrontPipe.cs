namespace TowerProtect.App.Networking.Routing.Backend;

public interface IBackendFrontPipe
{
    void Send(long client, string message);
    bool TryDequeue(out (long, string) msgPair);
}
