using AutoInterfaceAttributes;
using TowerProtect.App.Networking.Routing.Backend;
using TowerProtect.App.Networking.Routing.Client;
using TowerProtect.Domain.Inventions.Interfaces;
using TowerProtect.Domain.Inventions.Networking;

namespace TowerProtect.App.Networking.Connectors;

partial interface ILocalConnector : IStartAware;

[AutoInterface]
internal class LocalConnector(
    IClientBackPipe clientBackPipe,
    IBackendBackPipe backendBackPipe,
    INetInstance netInstance) : ILocalConnector
{
    private readonly long _client = netInstance.Id;

    public void Start()
    {
        clientBackPipe.OnSendEvent += message =>
        {
            backendBackPipe.PushMessage(_client, message);
        };

        backendBackPipe.OnSendEvent += (client, message) =>
        {
            if (client == _client || client == 0) // 0 is broadcast
                clientBackPipe.PushMessage(message);
        };
    }
}
