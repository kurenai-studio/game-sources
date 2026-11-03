using TowerProtect.Domain.Backend.Entities.Abstract;

namespace TowerProtect.Domain.Backend.Entities.Interactions.Output;

internal interface IEntityPanel
{
    void Spawn(Entity entity);
}
