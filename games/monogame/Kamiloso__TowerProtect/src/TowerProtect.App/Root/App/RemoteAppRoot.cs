using TowerProtect.App.Client;

namespace TowerProtect.App.Root.App;

internal class RemoteAppRoot(
    IClientOrchestrator clientOrchestrator) : IAppRoot
{
    public void Start()
    {
        clientOrchestrator.Start();
    }

    public void Update(double deltaTime)
    {
        clientOrchestrator.Update(deltaTime);
    }
}
