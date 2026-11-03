using TowerProtect.App.Backend;
using TowerProtect.App.Client;
using TowerProtect.App.Networking.Connectors;

namespace TowerProtect.App.Root.App;

internal class LocalAppRoot(
    ILocalConnector localConnector,
    IBackendOrchestrator backendOrchestrator,
    IClientOrchestrator clientOrchestrator) : IAppRoot
{
    public void Start()
    {
        localConnector.Start();
        backendOrchestrator.Start();
        clientOrchestrator.Start();
    }

    public void Update(double deltaTime)
    {
        backendOrchestrator.Update(deltaTime);
        clientOrchestrator.Update(deltaTime);
    }
}
