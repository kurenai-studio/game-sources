using System;

namespace TowerProtect.App.Networking.Routing.Backend;

public interface IBackendBackPipe
{
    event Action<long, string>? OnSendEvent;
    void PushMessage(long client, string message);
}
