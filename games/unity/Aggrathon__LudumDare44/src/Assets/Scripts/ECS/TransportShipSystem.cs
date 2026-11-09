using Unity.Burst;
using Unity.Collections;
using Unity.Entities;
using Unity.Jobs;
using Unity.Mathematics;
using Unity.Transforms;
using static Unity.Mathematics.math;

[UpdateBefore(typeof(NavigatorSystem))]
public class TransportShipSystem : ComponentSystem
{
    GameState state;

    protected override void OnUpdate()
    {
        if(!state) state = UnityEngine.GameObject.FindObjectOfType<GameState>();
        Entities.ForEach((Entity ent, ref Navigator nav, ref TransportShip ship, ref Translation trans) => {
            var pos = EntityManager.GetComponentData<Translation>(ship.target).Value;
            pos.z = trans.Value.z;
            if (distancesq(trans.Value, pos) < ship.minDist * ship.minDist) {
                switch(ship.resource) {
                    case Asteroid.Resource.Water:
                        state.water += ship.inventory;
                        break;
                    case Asteroid.Resource.Iron:
                        state.iron += ship.inventory;
                        break;
                    case Asteroid.Resource.Aluminium:
                        state.aluminium += ship.inventory;
                        break;
                }
                PostUpdateCommands.DestroyEntity(ent);
            } else {
                nav.target = pos;
            }
        });
    }
}