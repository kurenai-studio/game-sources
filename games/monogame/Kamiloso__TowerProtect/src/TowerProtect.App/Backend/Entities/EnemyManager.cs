using AutoInterfaceAttributes;
using TowerProtect.Domain.Backend.Entities.Bags;
using TowerProtect.Domain.Inventions.Interfaces;

namespace TowerProtect.App.Backend.Entities;

partial interface IEnemyManager : IUpdateAware;

[AutoInterface]
internal class EnemyManager(
    IEnemyBag entityBag) : IEnemyManager
{
    // TODO: Do something with this constant
    // private const double SpawnInterval = 5.0;

    // private readonly LoopCycle _spawnCycle = new(SpawnInterval);

    public void Update(double deltaTime)
    {
        entityBag = null!;

        /*_spawnCycle.Invoke(deltaTime, () =>
        {
            Vec2 spawnPosition = new Vec2( // test
                x: Random.Shared.NextDouble(),
                y: Random.Shared.NextDouble()
            ) * 10.0;

            var controller = new EnemyController();
            var entity = new MonsterEntity(Vec2.Zero, controller);

            entityBag.SpawnEntity(entity, out _);
        });*/
    }
}
