using System;

namespace TowerProtect.App.Networking.Routing.Client;

public interface IClientBackPipe
{
    event Action<string>? OnSendEvent;
    void PushMessage(string message);
    void MarkAsDead();
}
